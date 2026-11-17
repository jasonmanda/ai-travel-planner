-- Read-only operational and recommendation-eligibility audit.
-- Run manually in pgAdmin. SELECT statements only; NOT a Flyway migration.
-- Mirrors CatalogRecommendationEligibility: VERIFIED + official item-specific source candidate
-- + valid coordinates + positive duration + non-empty title/category.
-- This audit does not update catalog data, verification history or itinerary records.

WITH catalog_items AS (
    SELECT
        'ATTRACTION'::TEXT AS item_type,
        a.id,
        co.iso_code,
        c.name AS city,
        a.name,
        a.category,
        a.description,
        a.latitude,
        a.longitude,
        a.estimated_duration_minutes AS estimated_duration_minutes,
        a.estimated_visit_cost AS estimated_cost,
        a.cost_currency AS currency,
        NULL::BOOLEAN AS suitable_for_families,
        NULL::INTEGER AS min_age_years,
        a.data_status,
        a.source_name,
        a.source_url,
        a.source_type,
        a.source_scope,
        a.last_verified_at,
        CASE
          WHEN pv.verification_status = 'VERIFIED'
           AND pv.verified_fields @> ARRAY['estimated_visit_cost', 'cost_currency']::TEXT[]
           AND pv.verified_price = a.estimated_visit_cost
           AND pv.verified_currency = a.cost_currency THEN TRUE
          ELSE FALSE
        END AS price_verified
    FROM attractions a
    JOIN cities c ON c.id = a.city_id
    JOIN countries co ON co.id = c.country_id
    LEFT JOIN LATERAL (
        SELECT h.verification_status, h.verified_fields, h.verified_price, h.verified_currency
        FROM attraction_verification_history h
        WHERE h.attraction_id = a.id
          AND h.verified_fields && ARRAY['estimated_visit_cost', 'cost_currency']::TEXT[]
        ORDER BY h.verified_at DESC, h.id DESC
        LIMIT 1
    ) pv ON TRUE
    WHERE a.active = TRUE AND a.data_status <> 'REJECTED'

    UNION ALL

    SELECT
        'ACTIVITY'::TEXT,
        act.id,
        co.iso_code,
        c.name,
        act.name,
        act.category,
        act.description,
        act.latitude,
        act.longitude,
        act.estimated_duration_minutes,
        act.estimated_cost,
        act.cost_currency,
        act.suitable_for_families,
        act.min_age_years,
        act.data_status,
        act.source_name,
        act.source_url,
        act.source_type,
        act.source_scope,
        act.last_verified_at,
        CASE
          WHEN pv.verification_status = 'VERIFIED'
           AND pv.verified_fields @> ARRAY['estimated_cost', 'cost_currency']::TEXT[]
           AND pv.verified_price = act.estimated_cost
           AND pv.verified_currency = act.cost_currency THEN TRUE
          ELSE FALSE
        END AS price_verified
    FROM activities act
    JOIN cities c ON c.id = act.city_id
    JOIN countries co ON co.id = c.country_id
    LEFT JOIN LATERAL (
        SELECT h.verification_status, h.verified_fields, h.verified_price, h.verified_currency
        FROM activity_verification_history h
        WHERE h.activity_id = act.id
          AND h.verified_fields && ARRAY['estimated_cost', 'cost_currency']::TEXT[]
        ORDER BY h.verified_at DESC, h.id DESC
        LIMIT 1
    ) pv ON TRUE
    WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL'
            THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC'
            THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC')
            THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OPERATOR_PRIMARY'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '^https?://[^/]+/[^[:space:]]+          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '^https?://[^/]+/?([?#].*)?$'
           AND source_url !~* '^https?://maliasilismz\\.go\\.tz/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '^https?://[^/]+/?([?#].*)?$'
           AND source_url !~* '^https?://maliasilismz\\.go\\.tz/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (
            latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90
            AND longitude BETWEEN -180 AND 180
        ) AS coordinates_valid,
        (estimated_duration_minutes IS NOT NULL AND estimated_duration_minutes > 0)
            AS duration_valid
    FROM catalog_items
),
assessed AS (
    SELECT *,
        (
            data_status = 'VERIFIED'
            AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            AND coordinates_valid
            AND duration_valid
            AND NULLIF(BTRIM(name), '') IS NOT NULL
            AND NULLIF(BTRIM(category), '') IS NOT NULL
        ) AS recommendation_eligible,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN data_status <> 'VERIFIED' THEN 'CATALOG_ITEM_NOT_VERIFIED' END,
            CASE WHEN source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                 THEN 'OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED' END,
            CASE WHEN NOT coordinates_valid THEN 'VALID_COORDINATES_REQUIRED' END,
            CASE WHEN NOT duration_valid THEN 'VERIFIED_DURATION_REQUIRED' END,
            CASE WHEN NULLIF(BTRIM(name), '') IS NULL
                   OR NULLIF(BTRIM(category), '') IS NULL
                 THEN 'NAME_AND_CATEGORY_REQUIRED' END
        ], NULL) AS exclusion_reasons,
        CASE WHEN estimated_cost IS NULL THEN 'PRICE_NOT_AVAILABLE'
             WHEN price_verified THEN 'PRICE_VERIFIED'
             ELSE 'PRICE_ESTIMATE_ONLY' END AS price_review,
        ARRAY[
            'OPENING_HOURS_NOT_MODELED',
            'ACCESS_CONDITIONS_NOT_MODELED',
            'LIVE_AVAILABILITY_NOT_MODELED'
        ]::TEXT[] AS operational_fields_not_modeled
    FROM classified
)
SELECT
    item_type, iso_code, city, id, name, category,
    data_status, last_verified_at,
    source_name, source_url, source_type, source_scope, source_quality,
    latitude, longitude, coordinates_valid,
    estimated_duration_minutes, duration_valid,
    estimated_cost, currency, price_review,
    suitable_for_families, min_age_years,
    recommendation_eligible, exclusion_reasons,
    operational_fields_not_modeled
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: shows how many active records pass the strict gate.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.name, a.category, a.latitude, a.longitude,
           a.estimated_duration_minutes, a.data_status, a.source_name, a.source_url,
           a.source_type, a.source_scope
      FROM attractions a WHERE a.active = TRUE AND a.data_status <> 'REJECTED'
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.name, act.category, act.latitude, act.longitude,
           act.estimated_duration_minutes, act.data_status, act.source_name, act.source_url,
           act.source_type, act.source_scope
      FROM activities act WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL' THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC' THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC') THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OPERATOR_PRIMARY' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '^https?://[^/]+/[^[:space:]]+          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

           AND source_url !~* '/(index\\.(php|html?)|default\\.(aspx?|html?)|home|tours|excursions|experiences|activities|booking)/?([?#].*)?          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (
            latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90
            AND longitude BETWEEN -180 AND 180
        ) AS coordinates_valid,
        (estimated_duration_minutes IS NOT NULL AND estimated_duration_minutes > 0)
            AS duration_valid
    FROM catalog_items
),
assessed AS (
    SELECT *,
        (
            data_status = 'VERIFIED'
            AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            AND coordinates_valid
            AND duration_valid
            AND NULLIF(BTRIM(name), '') IS NOT NULL
            AND NULLIF(BTRIM(category), '') IS NOT NULL
        ) AS recommendation_eligible,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN data_status <> 'VERIFIED' THEN 'CATALOG_ITEM_NOT_VERIFIED' END,
            CASE WHEN source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                 THEN 'OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED' END,
            CASE WHEN NOT coordinates_valid THEN 'VALID_COORDINATES_REQUIRED' END,
            CASE WHEN NOT duration_valid THEN 'VERIFIED_DURATION_REQUIRED' END,
            CASE WHEN NULLIF(BTRIM(name), '') IS NULL
                   OR NULLIF(BTRIM(category), '') IS NULL
                 THEN 'NAME_AND_CATEGORY_REQUIRED' END
        ], NULL) AS exclusion_reasons,
        CASE WHEN estimated_cost IS NULL THEN 'PRICE_NOT_AVAILABLE'
             WHEN price_verified THEN 'PRICE_VERIFIED'
             ELSE 'PRICE_ESTIMATE_ONLY' END AS price_review,
        ARRAY[
            'OPENING_HOURS_NOT_MODELED',
            'ACCESS_CONDITIONS_NOT_MODELED',
            'LIVE_AVAILABILITY_NOT_MODELED'
        ]::TEXT[] AS operational_fields_not_modeled
    FROM classified
)
SELECT
    item_type, iso_code, city, id, name, category,
    data_status, last_verified_at,
    source_name, source_url, source_type, source_scope, source_quality,
    latitude, longitude, coordinates_valid,
    estimated_duration_minutes, duration_valid,
    estimated_cost, currency, price_review,
    suitable_for_families, min_age_years,
    recommendation_eligible, exclusion_reasons,
    operational_fields_not_modeled
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: shows how many active records pass the strict gate.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.name, a.category, a.latitude, a.longitude,
           a.estimated_duration_minutes, a.data_status, a.source_name, a.source_url,
           a.source_type, a.source_scope
      FROM attractions a WHERE a.active = TRUE AND a.data_status <> 'REJECTED'
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.name, act.category, act.latitude, act.longitude,
           act.estimated_duration_minutes, act.data_status, act.source_name, act.source_url,
           act.source_type, act.source_scope
      FROM activities act WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL' THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC' THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC') THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

            THEN 'OPERATOR_PRIMARY_CANDIDATE'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (
            latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90
            AND longitude BETWEEN -180 AND 180
        ) AS coordinates_valid,
        (estimated_duration_minutes IS NOT NULL AND estimated_duration_minutes > 0)
            AS duration_valid
    FROM catalog_items
),
assessed AS (
    SELECT *,
        (
            data_status = 'VERIFIED'
            AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            AND coordinates_valid
            AND duration_valid
            AND NULLIF(BTRIM(name), '') IS NOT NULL
            AND NULLIF(BTRIM(category), '') IS NOT NULL
        ) AS recommendation_eligible,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN data_status <> 'VERIFIED' THEN 'CATALOG_ITEM_NOT_VERIFIED' END,
            CASE WHEN source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                 THEN 'OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED' END,
            CASE WHEN NOT coordinates_valid THEN 'VALID_COORDINATES_REQUIRED' END,
            CASE WHEN NOT duration_valid THEN 'VERIFIED_DURATION_REQUIRED' END,
            CASE WHEN NULLIF(BTRIM(name), '') IS NULL
                   OR NULLIF(BTRIM(category), '') IS NULL
                 THEN 'NAME_AND_CATEGORY_REQUIRED' END
        ], NULL) AS exclusion_reasons,
        CASE WHEN estimated_cost IS NULL THEN 'PRICE_NOT_AVAILABLE'
             WHEN price_verified THEN 'PRICE_VERIFIED'
             ELSE 'PRICE_ESTIMATE_ONLY' END AS price_review,
        ARRAY[
            'OPENING_HOURS_NOT_MODELED',
            'ACCESS_CONDITIONS_NOT_MODELED',
            'LIVE_AVAILABILITY_NOT_MODELED'
        ]::TEXT[] AS operational_fields_not_modeled
    FROM classified
)
SELECT
    item_type, iso_code, city, id, name, category,
    data_status, last_verified_at,
    source_name, source_url, source_type, source_scope, source_quality,
    latitude, longitude, coordinates_valid,
    estimated_duration_minutes, duration_valid,
    estimated_cost, currency, price_review,
    suitable_for_families, min_age_years,
    recommendation_eligible, exclusion_reasons,
    operational_fields_not_modeled
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: shows how many active records pass the strict gate.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.name, a.category, a.latitude, a.longitude,
           a.estimated_duration_minutes, a.data_status, a.source_name, a.source_url,
           a.source_type, a.source_scope
      FROM attractions a WHERE a.active = TRUE AND a.data_status <> 'REJECTED'
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.name, act.category, act.latitude, act.longitude,
           act.estimated_duration_minutes, act.data_status, act.source_name, act.source_url,
           act.source_type, act.source_scope
      FROM activities act WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL' THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC' THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC') THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

           AND source_url !~* '/(index\\.(php|html?)|default\\.(aspx?|html?)|home|tours|excursions|experiences|activities|booking)/?([?#].*)?          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

           AND source_url !~* '/(index\\.(php|html?)|default\\.(aspx?|html?)|home|tours|excursions|experiences|activities|booking)/?([?#].*)?          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (
            latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90
            AND longitude BETWEEN -180 AND 180
        ) AS coordinates_valid,
        (estimated_duration_minutes IS NOT NULL AND estimated_duration_minutes > 0)
            AS duration_valid
    FROM catalog_items
),
assessed AS (
    SELECT *,
        (
            data_status = 'VERIFIED'
            AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            AND coordinates_valid
            AND duration_valid
            AND NULLIF(BTRIM(name), '') IS NOT NULL
            AND NULLIF(BTRIM(category), '') IS NOT NULL
        ) AS recommendation_eligible,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN data_status <> 'VERIFIED' THEN 'CATALOG_ITEM_NOT_VERIFIED' END,
            CASE WHEN source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                 THEN 'OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED' END,
            CASE WHEN NOT coordinates_valid THEN 'VALID_COORDINATES_REQUIRED' END,
            CASE WHEN NOT duration_valid THEN 'VERIFIED_DURATION_REQUIRED' END,
            CASE WHEN NULLIF(BTRIM(name), '') IS NULL
                   OR NULLIF(BTRIM(category), '') IS NULL
                 THEN 'NAME_AND_CATEGORY_REQUIRED' END
        ], NULL) AS exclusion_reasons,
        CASE WHEN estimated_cost IS NULL THEN 'PRICE_NOT_AVAILABLE'
             WHEN price_verified THEN 'PRICE_VERIFIED'
             ELSE 'PRICE_ESTIMATE_ONLY' END AS price_review,
        ARRAY[
            'OPENING_HOURS_NOT_MODELED',
            'ACCESS_CONDITIONS_NOT_MODELED',
            'LIVE_AVAILABILITY_NOT_MODELED'
        ]::TEXT[] AS operational_fields_not_modeled
    FROM classified
)
SELECT
    item_type, iso_code, city, id, name, category,
    data_status, last_verified_at,
    source_name, source_url, source_type, source_scope, source_quality,
    latitude, longitude, coordinates_valid,
    estimated_duration_minutes, duration_valid,
    estimated_cost, currency, price_review,
    suitable_for_families, min_age_years,
    recommendation_eligible, exclusion_reasons,
    operational_fields_not_modeled
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: shows how many active records pass the strict gate.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.name, a.category, a.latitude, a.longitude,
           a.estimated_duration_minutes, a.data_status, a.source_name, a.source_url,
           a.source_type, a.source_scope
      FROM attractions a WHERE a.active = TRUE AND a.data_status <> 'REJECTED'
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.name, act.category, act.latitude, act.longitude,
           act.estimated_duration_minutes, act.data_status, act.source_name, act.source_url,
           act.source_type, act.source_scope
      FROM activities act WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL' THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC' THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC') THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

            THEN 'OPERATOR_PRIMARY_CANDIDATE'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (
            latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90
            AND longitude BETWEEN -180 AND 180
        ) AS coordinates_valid,
        (estimated_duration_minutes IS NOT NULL AND estimated_duration_minutes > 0)
            AS duration_valid
    FROM catalog_items
),
assessed AS (
    SELECT *,
        (
            data_status = 'VERIFIED'
            AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            AND coordinates_valid
            AND duration_valid
            AND NULLIF(BTRIM(name), '') IS NOT NULL
            AND NULLIF(BTRIM(category), '') IS NOT NULL
        ) AS recommendation_eligible,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN data_status <> 'VERIFIED' THEN 'CATALOG_ITEM_NOT_VERIFIED' END,
            CASE WHEN source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                 THEN 'OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED' END,
            CASE WHEN NOT coordinates_valid THEN 'VALID_COORDINATES_REQUIRED' END,
            CASE WHEN NOT duration_valid THEN 'VERIFIED_DURATION_REQUIRED' END,
            CASE WHEN NULLIF(BTRIM(name), '') IS NULL
                   OR NULLIF(BTRIM(category), '') IS NULL
                 THEN 'NAME_AND_CATEGORY_REQUIRED' END
        ], NULL) AS exclusion_reasons,
        CASE WHEN estimated_cost IS NULL THEN 'PRICE_NOT_AVAILABLE'
             WHEN price_verified THEN 'PRICE_VERIFIED'
             ELSE 'PRICE_ESTIMATE_ONLY' END AS price_review,
        ARRAY[
            'OPENING_HOURS_NOT_MODELED',
            'ACCESS_CONDITIONS_NOT_MODELED',
            'LIVE_AVAILABILITY_NOT_MODELED'
        ]::TEXT[] AS operational_fields_not_modeled
    FROM classified
)
SELECT
    item_type, iso_code, city, id, name, category,
    data_status, last_verified_at,
    source_name, source_url, source_type, source_scope, source_quality,
    latitude, longitude, coordinates_valid,
    estimated_duration_minutes, duration_valid,
    estimated_cost, currency, price_review,
    suitable_for_families, min_age_years,
    recommendation_eligible, exclusion_reasons,
    operational_fields_not_modeled
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: shows how many active records pass the strict gate.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.name, a.category, a.latitude, a.longitude,
           a.estimated_duration_minutes, a.data_status, a.source_name, a.source_url,
           a.source_type, a.source_scope
      FROM attractions a WHERE a.active = TRUE AND a.data_status <> 'REJECTED'
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.name, act.category, act.latitude, act.longitude,
           act.estimated_duration_minutes, act.data_status, act.source_name, act.source_url,
           act.source_type, act.source_scope
      FROM activities act WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL' THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC' THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC') THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

            THEN 'OPERATOR_PRIMARY_CANDIDATE'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

           AND source_url !~* '/(index\\.(php|html?)|default\\.(aspx?|html?)|home|tours|excursions|experiences|activities|booking)/?([?#].*)?          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (
            latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90
            AND longitude BETWEEN -180 AND 180
        ) AS coordinates_valid,
        (estimated_duration_minutes IS NOT NULL AND estimated_duration_minutes > 0)
            AS duration_valid
    FROM catalog_items
),
assessed AS (
    SELECT *,
        (
            data_status = 'VERIFIED'
            AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            AND coordinates_valid
            AND duration_valid
            AND NULLIF(BTRIM(name), '') IS NOT NULL
            AND NULLIF(BTRIM(category), '') IS NOT NULL
        ) AS recommendation_eligible,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN data_status <> 'VERIFIED' THEN 'CATALOG_ITEM_NOT_VERIFIED' END,
            CASE WHEN source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                 THEN 'OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED' END,
            CASE WHEN NOT coordinates_valid THEN 'VALID_COORDINATES_REQUIRED' END,
            CASE WHEN NOT duration_valid THEN 'VERIFIED_DURATION_REQUIRED' END,
            CASE WHEN NULLIF(BTRIM(name), '') IS NULL
                   OR NULLIF(BTRIM(category), '') IS NULL
                 THEN 'NAME_AND_CATEGORY_REQUIRED' END
        ], NULL) AS exclusion_reasons,
        CASE WHEN estimated_cost IS NULL THEN 'PRICE_NOT_AVAILABLE'
             WHEN price_verified THEN 'PRICE_VERIFIED'
             ELSE 'PRICE_ESTIMATE_ONLY' END AS price_review,
        ARRAY[
            'OPENING_HOURS_NOT_MODELED',
            'ACCESS_CONDITIONS_NOT_MODELED',
            'LIVE_AVAILABILITY_NOT_MODELED'
        ]::TEXT[] AS operational_fields_not_modeled
    FROM classified
)
SELECT
    item_type, iso_code, city, id, name, category,
    data_status, last_verified_at,
    source_name, source_url, source_type, source_scope, source_quality,
    latitude, longitude, coordinates_valid,
    estimated_duration_minutes, duration_valid,
    estimated_cost, currency, price_review,
    suitable_for_families, min_age_years,
    recommendation_eligible, exclusion_reasons,
    operational_fields_not_modeled
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: shows how many active records pass the strict gate.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.name, a.category, a.latitude, a.longitude,
           a.estimated_duration_minutes, a.data_status, a.source_name, a.source_url,
           a.source_type, a.source_scope
      FROM attractions a WHERE a.active = TRUE AND a.data_status <> 'REJECTED'
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.name, act.category, act.latitude, act.longitude,
           act.estimated_duration_minutes, act.data_status, act.source_name, act.source_url,
           act.source_type, act.source_scope
      FROM activities act WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL' THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC' THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC') THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;

            THEN 'OPERATOR_PRIMARY_CANDIDATE'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL'
           AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (
            latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90
            AND longitude BETWEEN -180 AND 180
        ) AS coordinates_valid,
        (estimated_duration_minutes IS NOT NULL AND estimated_duration_minutes > 0)
            AS duration_valid
    FROM catalog_items
),
assessed AS (
    SELECT *,
        (
            data_status = 'VERIFIED'
            AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            AND coordinates_valid
            AND duration_valid
            AND NULLIF(BTRIM(name), '') IS NOT NULL
            AND NULLIF(BTRIM(category), '') IS NOT NULL
        ) AS recommendation_eligible,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN data_status <> 'VERIFIED' THEN 'CATALOG_ITEM_NOT_VERIFIED' END,
            CASE WHEN source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                 THEN 'OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED' END,
            CASE WHEN NOT coordinates_valid THEN 'VALID_COORDINATES_REQUIRED' END,
            CASE WHEN NOT duration_valid THEN 'VERIFIED_DURATION_REQUIRED' END,
            CASE WHEN NULLIF(BTRIM(name), '') IS NULL
                   OR NULLIF(BTRIM(category), '') IS NULL
                 THEN 'NAME_AND_CATEGORY_REQUIRED' END
        ], NULL) AS exclusion_reasons,
        CASE WHEN estimated_cost IS NULL THEN 'PRICE_NOT_AVAILABLE'
             WHEN price_verified THEN 'PRICE_VERIFIED'
             ELSE 'PRICE_ESTIMATE_ONLY' END AS price_review,
        ARRAY[
            'OPENING_HOURS_NOT_MODELED',
            'ACCESS_CONDITIONS_NOT_MODELED',
            'LIVE_AVAILABILITY_NOT_MODELED'
        ]::TEXT[] AS operational_fields_not_modeled
    FROM classified
)
SELECT
    item_type, iso_code, city, id, name, category,
    data_status, last_verified_at,
    source_name, source_url, source_type, source_scope, source_quality,
    latitude, longitude, coordinates_valid,
    estimated_duration_minutes, duration_valid,
    estimated_cost, currency, price_review,
    suitable_for_families, min_age_years,
    recommendation_eligible, exclusion_reasons,
    operational_fields_not_modeled
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: shows how many active records pass the strict gate.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.name, a.category, a.latitude, a.longitude,
           a.estimated_duration_minutes, a.data_status, a.source_name, a.source_url,
           a.source_type, a.source_scope
      FROM attractions a WHERE a.active = TRUE AND a.data_status <> 'REJECTED'
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.name, act.category, act.latitude, act.longitude,
           act.estimated_duration_minutes, act.data_status, act.source_name, act.source_url,
           act.source_type, act.source_scope
      FROM activities act WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
classified AS (
    SELECT *,
        CASE
          WHEN NULLIF(BTRIM(source_name), '') IS NULL
            OR NULLIF(BTRIM(source_url), '') IS NULL
            OR source_url !~* '^https?://[^[:space:]]+$'
            THEN 'NO_USABLE_SOURCE'
          WHEN source_scope = 'DESTINATION_GENERAL' THEN 'DESTINATION_CONTEXT_ONLY'
          WHEN source_type = 'SCIENTIFIC' THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
          WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC') THEN 'SECONDARY_REFERENCE_ONLY'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(index\.(php|html?)|default\.(aspx?|html?)|home)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?$'
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
           AND (
                lower(source_url) LIKE '%whc.unesco.org/en/list/173%'
             OR lower(source_url) LIKE '%whc.unesco.org/document/218167%'
             OR lower(source_url) LIKE '%bot.go.tz/%tanzania%tourism%sector%survey%'
             OR lower(source_url) LIKE '%sanparks.org/parks/table-mountain'
             OR lower(source_url) LIKE '%tanzaniatourism.go.tz/%chan-2024-participant-guidebook%'
             OR lower(source_url) LIKE '%nishati.go.tz/%eapce25%'
           )
            THEN 'SOURCE_REQUIRES_REVIEW'
          WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
            THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        (latitude IS NOT NULL AND longitude IS NOT NULL
         AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) AS coordinates_valid
    FROM catalog_items
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED'
          AND source_quality = 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
          AND coordinates_valid
          AND estimated_duration_minutes > 0
          AND NULLIF(BTRIM(name), '') IS NOT NULL
          AND NULLIF(BTRIM(category), '') IS NOT NULL
    ) AS recommendation_eligible_count,
    COUNT(*) FILTER (WHERE data_status <> 'VERIFIED') AS not_fully_verified_count,
    COUNT(*) FILTER (WHERE source_quality <> 'ITEM_SPECIFIC_PRIMARY_CANDIDATE') AS source_gate_failed_count,
    COUNT(*) FILTER (WHERE NOT coordinates_valid) AS invalid_or_missing_coordinates_count,
    COUNT(*) FILTER (WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0)
        AS missing_or_invalid_duration_count
FROM classified;
