-- Read-only follow-up audit for active UNVERIFIED attractions and activities.
-- MANUAL execution in pgAdmin. This script does not update catalog rows,
-- data_status, last_verified_at, or verification-history records.
--
-- Purpose:
--   1. List every active UNVERIFIED attraction/activity with its source evidence.
--   2. Reuse the exact source_quality rules from CatalogSourceTransparency and
--      reports/catalog_source_quality_audit.sql.
--   3. Suggest a human follow-up action without automatically validating anything.
--
-- Important:
--   ITEM_SPECIFIC_PRIMARY_CANDIDATE means only that the source appears structurally
--   official and item-specific. It is NOT a VERIFIED status and does not prove
--   current opening, access, prices, safety, schedules or availability.

WITH catalog_items AS (
    SELECT
        'ATTRACTION'::TEXT AS item_type,
        a.id,
        co.iso_code,
        co.name AS country,
        c.name AS city,
        a.name,
        a.source_name,
        a.source_url,
        a.source_type,
        a.source_scope,
        a.data_status,
        a.last_verified_at,
        a.verification_notes
    FROM attractions a
    JOIN cities c ON c.id = a.city_id
    JOIN countries co ON co.id = c.country_id
    WHERE a.active = TRUE
      AND a.data_status = 'UNVERIFIED'

    UNION ALL

    SELECT
        'ACTIVITY'::TEXT,
        act.id,
        co.iso_code,
        co.name,
        c.name,
        act.name,
        act.source_name,
        act.source_url,
        act.source_type,
        act.source_scope,
        act.data_status,
        act.last_verified_at,
        act.verification_notes
    FROM activities act
    JOIN cities c ON c.id = act.city_id
    JOIN countries co ON co.id = c.country_id
    WHERE act.active = TRUE
      AND act.data_status = 'UNVERIFIED'
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
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
             AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?
                THEN 'SOURCE_REQUIRES_REVIEW'
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
                THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality
    FROM catalog_items
),
actionable AS (
    SELECT *,
        CASE source_quality
            WHEN 'NO_USABLE_SOURCE'
                THEN 'Find a reachable source that identifies this exact item.'
            WHEN 'DESTINATION_CONTEXT_ONLY'
                THEN 'Replace destination-level reference with item-specific evidence.'
            WHEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
                THEN 'Keep as geographic context; add an official visitor or operator source.'
            WHEN 'SECONDARY_REFERENCE_ONLY'
                THEN 'Seek an official source; retain provider evidence only with explicit limits.'
            WHEN 'SOURCE_REQUIRES_REVIEW'
                THEN 'Inspect the exact page and replace generic or structurally broad URLs.'
            WHEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                THEN 'Human-check every claim and current visit conditions before recording verification.'
            ELSE 'Human review required.'
        END AS recommended_next_action
    FROM classified
)
SELECT
    item_type,
    iso_code,
    country,
    city,
    id,
    name,
    source_quality,
    source_name,
    source_url,
    source_type,
    source_scope,
    data_status,
    last_verified_at,
    verification_notes,
    recommended_next_action
FROM actionable
ORDER BY
    CASE source_quality
        WHEN 'NO_USABLE_SOURCE' THEN 1
        WHEN 'DESTINATION_CONTEXT_ONLY' THEN 2
        WHEN 'SOURCE_REQUIRES_REVIEW' THEN 3
        WHEN 'SECONDARY_REFERENCE_ONLY' THEN 4
        WHEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE' THEN 5
        WHEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE' THEN 6
        ELSE 7
    END,
    country,
    city,
    item_type,
    name;

-- Summary of the same active UNVERIFIED population.
WITH catalog_items AS (
    SELECT source_name, source_url, source_type, source_scope, data_status
    FROM attractions
    WHERE active = TRUE AND data_status = 'UNVERIFIED'
    UNION ALL
    SELECT source_name, source_url, source_type, source_scope, data_status
    FROM activities
    WHERE active = TRUE AND data_status = 'UNVERIFIED'
),
classified AS (
    SELECT
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
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
             AND source_url ~* '(^|/)(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)(/|[?#]|$)'
                THEN 'SOURCE_REQUIRES_REVIEW'
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
                THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        source_type,
        source_scope
    FROM catalog_items
)
SELECT
    source_quality,
    source_type,
    source_scope,
    COUNT(*) AS item_count
FROM classified
GROUP BY source_quality, source_type, source_scope
ORDER BY source_quality, source_type, source_scope;

                THEN 'SOURCE_REQUIRES_REVIEW'
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
                THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality
    FROM catalog_items
),
actionable AS (
    SELECT *,
        CASE source_quality
            WHEN 'NO_USABLE_SOURCE'
                THEN 'Find a reachable source that identifies this exact item.'
            WHEN 'DESTINATION_CONTEXT_ONLY'
                THEN 'Replace destination-level reference with item-specific evidence.'
            WHEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
                THEN 'Keep as geographic context; add an official visitor or operator source.'
            WHEN 'SECONDARY_REFERENCE_ONLY'
                THEN 'Seek an official source; retain provider evidence only with explicit limits.'
            WHEN 'SOURCE_REQUIRES_REVIEW'
                THEN 'Inspect the exact page and replace generic or structurally broad URLs.'
            WHEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
                THEN 'Human-check every claim and current visit conditions before recording verification.'
            ELSE 'Human review required.'
        END AS recommended_next_action
    FROM classified
)
SELECT
    item_type,
    iso_code,
    country,
    city,
    id,
    name,
    source_quality,
    source_name,
    source_url,
    source_type,
    source_scope,
    data_status,
    last_verified_at,
    verification_notes,
    recommended_next_action
FROM actionable
ORDER BY
    CASE source_quality
        WHEN 'NO_USABLE_SOURCE' THEN 1
        WHEN 'DESTINATION_CONTEXT_ONLY' THEN 2
        WHEN 'SOURCE_REQUIRES_REVIEW' THEN 3
        WHEN 'SECONDARY_REFERENCE_ONLY' THEN 4
        WHEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE' THEN 5
        WHEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE' THEN 6
        ELSE 7
    END,
    country,
    city,
    item_type,
    name;

-- Summary of the same active UNVERIFIED population.
WITH catalog_items AS (
    SELECT source_name, source_url, source_type, source_scope, data_status
    FROM attractions
    WHERE active = TRUE AND data_status = 'UNVERIFIED'
    UNION ALL
    SELECT source_name, source_url, source_type, source_scope, data_status
    FROM activities
    WHERE active = TRUE AND data_status = 'UNVERIFIED'
),
classified AS (
    SELECT
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
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
             AND source_url ~* '/(attractions|visitor-information|useful-information|visitor-tips|patrimoine-materiel-national|standards-catalogue)/?([?#].*)?
                THEN 'SOURCE_REQUIRES_REVIEW'
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
                THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        source_type,
        source_scope
    FROM catalog_items
)
SELECT
    source_quality,
    source_type,
    source_scope,
    COUNT(*) AS item_count
FROM classified
GROUP BY source_quality, source_type, source_scope
ORDER BY source_quality, source_type, source_scope;

                THEN 'SOURCE_REQUIRES_REVIEW'
            WHEN source_type = 'OFFICIAL'
             AND source_scope = 'ITEM_SPECIFIC'
                THEN 'ITEM_SPECIFIC_PRIMARY_CANDIDATE'
            ELSE 'SOURCE_REQUIRES_REVIEW'
        END AS source_quality,
        source_type,
        source_scope
    FROM catalog_items
)
SELECT
    source_quality,
    source_type,
    source_scope,
    COUNT(*) AS item_count
FROM classified
GROUP BY source_quality, source_type, source_scope
ORDER BY source_quality, source_type, source_scope;
