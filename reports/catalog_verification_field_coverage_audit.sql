-- Read-only audit of factual verification-history coverage for active catalog records.
-- Run manually in pgAdmin. SELECT statements only; NOT a Flyway migration.
-- Does not update catalog rows, verification history, last_verified_at or recommendation rules.
--
-- This audit mirrors recalculate_activity_catalog_status() and
-- recalculate_attraction_catalog_status():
--   * a field counts only when verified_fields declares it AND verified_values
--     contains the exact current catalog value;
--   * VERIFIED and PARTIALLY_VERIFIED events can contribute field coverage;
--   * only events after the latest REJECTED event can contribute;
--   * the derived status is based on the six core fields.
--
-- Event-declared status and catalog-derived status are reported separately.
-- An event may declare PARTIALLY_VERIFIED while the derived catalog status is
-- UNVERIFIED when its verified_values are missing or do not match.
-- This is an audit lens; it does not mutate data or alter recommendation rules.

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
        a.estimated_duration_minutes,
        a.data_status,
        a.last_verified_at,
        ARRAY[
            'name', 'category', 'description',
            'latitude', 'longitude', 'estimated_duration_minutes'
        ]::TEXT[] AS required_core_fields
    FROM attractions a
    JOIN cities c ON c.id = a.city_id
    JOIN countries co ON co.id = c.country_id
    WHERE a.active = TRUE
      AND a.data_status <> 'REJECTED'

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
        act.data_status,
        act.last_verified_at,
        ARRAY[
            'name', 'category', 'description',
            'latitude', 'longitude', 'estimated_duration_minutes'
        ]::TEXT[]
    FROM activities act
    JOIN cities c ON c.id = act.city_id
    JOIN countries co ON co.id = c.country_id
    WHERE act.active = TRUE
      AND act.data_status <> 'REJECTED'
),
verification_events AS (
    SELECT
        'ATTRACTION'::TEXT AS item_type,
        h.attraction_id AS item_id,
        h.id AS event_id,
        h.verification_status,
        h.verified_fields,
        h.verified_values,
        h.source_name,
        h.source_url,
        h.verified_by,
        h.verified_at
    FROM attraction_verification_history h

    UNION ALL

    SELECT
        'ACTIVITY'::TEXT,
        h.activity_id,
        h.id,
        h.verification_status,
        h.verified_fields,
        h.verified_values,
        h.source_name,
        h.source_url,
        h.verified_by,
        h.verified_at
    FROM activity_verification_history h
),
event_coverage AS (
    SELECT
        e.item_type,
        e.item_id,
        COUNT(*) AS verification_event_count,
        COUNT(*) FILTER (
            WHERE e.verification_status = 'VERIFIED'
        ) AS verified_event_count,
        COUNT(*) FILTER (
            WHERE e.verification_status = 'PARTIALLY_VERIFIED'
        ) AS partially_verified_event_count,
        COUNT(*) FILTER (
            WHERE e.verification_status = 'REJECTED'
        ) AS rejected_event_count,
        COUNT(*) FILTER (
            WHERE cardinality(COALESCE(e.verified_fields, ARRAY[]::TEXT[])) > 0
              AND EXISTS (
                  SELECT 1
                  FROM unnest(COALESCE(e.verified_fields, ARRAY[]::TEXT[])) AS f(field_name)
                  WHERE NOT (
                      COALESCE(e.verified_values, '{}'::JSONB) ? f.field_name
                  )
              )
        ) AS events_with_declared_fields_missing_values,
        SUM((
            SELECT COUNT(*)
            FROM unnest(COALESCE(e.verified_fields, ARRAY[]::TEXT[])) AS f(field_name)
            WHERE NOT (
                COALESCE(e.verified_values, '{}'::JSONB) ? f.field_name
            )
        )) AS declared_field_entries_missing_values
    FROM verification_events e
    GROUP BY e.item_type, e.item_id
),
latest_event AS (
    SELECT *
    FROM (
        SELECT
            e.*,
            ROW_NUMBER() OVER (
                PARTITION BY e.item_type, e.item_id
                ORDER BY e.verified_at DESC, e.event_id DESC
            ) AS row_num
        FROM verification_events e
    ) ranked
    WHERE row_num = 1
),
latest_rejection AS (
    SELECT
        item_type,
        item_id,
        MAX(event_id) AS latest_rejection_id
    FROM verification_events
    WHERE verification_status = 'REJECTED'
    GROUP BY item_type, item_id
),
field_checks AS (
    SELECT
        i.*,
        COALESCE(ec.verification_event_count, 0) AS verification_event_count,
        COALESCE(ec.verified_event_count, 0) AS verified_event_count,
        COALESCE(ec.partially_verified_event_count, 0) AS partially_verified_event_count,
        COALESCE(ec.rejected_event_count, 0) AS rejected_event_count,
        COALESCE(ec.events_with_declared_fields_missing_values, 0)
            AS events_with_declared_fields_missing_values,
        COALESCE(ec.declared_field_entries_missing_values, 0)
            AS declared_field_entries_missing_values,
        le.event_id AS latest_event_id,
        le.verification_status AS latest_event_status,
        le.verified_fields AS latest_event_fields,
        le.verified_values AS latest_event_values,
        le.source_name AS latest_event_source_name,
        le.source_url AS latest_event_source_url,
        le.verified_by AS latest_event_verified_by,
        le.verified_at AS latest_event_at,
        lr.latest_rejection_id,

        (
            length(btrim(i.name)) > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type
                  AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['name']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'name'
                  AND h.verified_values -> 'name' = to_jsonb(i.name)
            )
        ) AS name_verified,
        (
            i.description IS NOT NULL AND length(btrim(i.description)) > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type
                  AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['description']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'description'
                  AND h.verified_values -> 'description' = to_jsonb(i.description)
            )
        ) AS description_verified,
        (
            length(btrim(i.category)) > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type
                  AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['category']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'category'
                  AND h.verified_values -> 'category' = to_jsonb(i.category)
            )
        ) AS category_verified,
        (
            i.latitude IS NOT NULL
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type
                  AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['latitude']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'latitude'
                  AND h.verified_values -> 'latitude' = to_jsonb(i.latitude)
            )
        ) AS latitude_verified,
        (
            i.longitude IS NOT NULL
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type
                  AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['longitude']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'longitude'
                  AND h.verified_values -> 'longitude' = to_jsonb(i.longitude)
            )
        ) AS longitude_verified,
        (
            i.estimated_duration_minutes IS NOT NULL
            AND i.estimated_duration_minutes > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type
                  AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['estimated_duration_minutes']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'estimated_duration_minutes'
                  AND h.verified_values -> 'estimated_duration_minutes'
                      = to_jsonb(i.estimated_duration_minutes)
            )
        ) AS duration_verified,

        ARRAY(
            SELECT f.field_name
            FROM unnest(COALESCE(le.verified_fields, ARRAY[]::TEXT[])) AS f(field_name)
            WHERE NOT (
                COALESCE(le.verified_values, '{}'::JSONB) ? f.field_name
            )
            ORDER BY f.field_name
        ) AS latest_event_fields_missing_values
    FROM catalog_items i
    LEFT JOIN event_coverage ec
      ON ec.item_type = i.item_type
     AND ec.item_id = i.id
    LEFT JOIN latest_event le
      ON le.item_type = i.item_type
     AND le.item_id = i.id
    LEFT JOIN latest_rejection lr
      ON lr.item_type = i.item_type
     AND lr.item_id = i.id
),
derived_status AS (
    SELECT
        f.*,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN name_verified THEN 'name' END,
            CASE WHEN category_verified THEN 'category' END,
            CASE WHEN description_verified THEN 'description' END,
            CASE WHEN latitude_verified THEN 'latitude' END,
            CASE WHEN longitude_verified THEN 'longitude' END,
            CASE WHEN duration_verified THEN 'estimated_duration_minutes' END
        ]::TEXT[], NULL) AS verified_core_fields,
        CASE
            WHEN latest_rejection_id IS NOT NULL
             AND (
                 (name_verified::INTEGER
                  + description_verified::INTEGER
                  + category_verified::INTEGER
                  + latitude_verified::INTEGER
                  + longitude_verified::INTEGER
                  + duration_verified::INTEGER) < 6
             ) THEN 'REJECTED'
            WHEN (
                 name_verified::INTEGER
                 + description_verified::INTEGER
                 + category_verified::INTEGER
                 + latitude_verified::INTEGER
                 + longitude_verified::INTEGER
                 + duration_verified::INTEGER
            ) = 6 THEN 'VERIFIED'
            WHEN (
                 name_verified::INTEGER
                 + description_verified::INTEGER
                 + category_verified::INTEGER
                 + latitude_verified::INTEGER
                 + longitude_verified::INTEGER
                 + duration_verified::INTEGER
            ) > 0 THEN 'PARTIALLY_VERIFIED'
            ELSE 'UNVERIFIED'
        END AS derived_catalog_status
    FROM field_checks f
),
assessed AS (
    SELECT
        d.*,
        ARRAY(
            SELECT required_field
            FROM unnest(d.required_core_fields) AS required_field
            WHERE NOT (required_field = ANY(d.verified_core_fields))
            ORDER BY required_field
        ) AS missing_core_verified_fields,
        (
            d.latest_event_id IS NOT NULL
            AND d.data_status IS DISTINCT FROM d.derived_catalog_status
        ) AS catalog_status_recalculation_mismatch,
        (
            d.latest_event_id IS NOT NULL
            AND d.latest_event_status IS DISTINCT FROM d.derived_catalog_status
        ) AS latest_event_status_differs_from_derived_status
    FROM derived_status d
)
SELECT
    item_type,
    iso_code,
    city,
    id,
    name,
    category,
    data_status AS current_catalog_status,
    derived_catalog_status,
    last_verified_at,
    verification_event_count,
    verified_event_count,
    partially_verified_event_count,
    rejected_event_count,
    latest_event_id,
    latest_event_status,
    latest_event_at,
    latest_event_fields,
    latest_event_fields_missing_values,
    latest_event_values,
    verified_core_fields,
    missing_core_verified_fields,
    cardinality(missing_core_verified_fields) = 0 AS core_fields_have_verified_history,
    events_with_declared_fields_missing_values,
    declared_field_entries_missing_values,
    catalog_status_recalculation_mismatch,
    latest_event_status_differs_from_derived_status,
    latest_event_source_name,
    latest_event_source_url,
    latest_event_verified_by
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: status recalculation mismatches and malformed verification declarations.
-- The derived status follows the same six-field/value rules as the catalog functions.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.id, a.name, a.category,
           a.description, a.latitude, a.longitude, a.estimated_duration_minutes,
           a.data_status,
           ARRAY['name', 'category', 'description', 'latitude', 'longitude',
                 'estimated_duration_minutes']::TEXT[] AS required_core_fields
    FROM attractions a
    WHERE a.active = TRUE AND a.data_status <> 'REJECTED'

    UNION ALL

    SELECT 'ACTIVITY'::TEXT, act.id, act.name, act.category,
           act.description, act.latitude, act.longitude, act.estimated_duration_minutes,
           act.data_status,
           ARRAY['name', 'category', 'description', 'latitude', 'longitude',
                 'estimated_duration_minutes']::TEXT[]
    FROM activities act
    WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
verification_events AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, h.attraction_id AS item_id,
           h.id AS event_id, h.verification_status, h.verified_fields,
           h.verified_values, h.verified_at
    FROM attraction_verification_history h

    UNION ALL

    SELECT 'ACTIVITY'::TEXT, h.activity_id, h.id, h.verification_status,
           h.verified_fields, h.verified_values, h.verified_at
    FROM activity_verification_history h
),
event_summary AS (
    SELECT
        item_type,
        item_id,
        COUNT(*) AS event_count,
        COUNT(*) FILTER (
            WHERE cardinality(COALESCE(verified_fields, ARRAY[]::TEXT[])) > 0
              AND EXISTS (
                  SELECT 1
                  FROM unnest(COALESCE(verified_fields, ARRAY[]::TEXT[])) AS f(field_name)
                  WHERE NOT (
                      COALESCE(verified_values, '{}'::JSONB) ? f.field_name
                  )
              )
        ) AS events_with_declared_fields_missing_values,
        SUM((
            SELECT COUNT(*)
            FROM unnest(COALESCE(verified_fields, ARRAY[]::TEXT[])) AS f(field_name)
            WHERE NOT (
                COALESCE(verified_values, '{}'::JSONB) ? f.field_name
            )
        )) AS declared_field_entries_missing_values
    FROM verification_events
    GROUP BY item_type, item_id
),
latest_rejection AS (
    SELECT item_type, item_id, MAX(event_id) AS latest_rejection_id
    FROM verification_events
    WHERE verification_status = 'REJECTED'
    GROUP BY item_type, item_id
),
field_checks AS (
    SELECT
        i.*,
        COALESCE(es.event_count, 0) AS event_count,
        COALESCE(es.events_with_declared_fields_missing_values, 0)
            AS events_with_declared_fields_missing_values,
        COALESCE(es.declared_field_entries_missing_values, 0)
            AS declared_field_entries_missing_values,
        lr.latest_rejection_id,
        (
            length(btrim(i.name)) > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['name']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'name'
                  AND h.verified_values -> 'name' = to_jsonb(i.name)
            )
        ) AS name_verified,
        (
            i.description IS NOT NULL AND length(btrim(i.description)) > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['description']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'description'
                  AND h.verified_values -> 'description' = to_jsonb(i.description)
            )
        ) AS description_verified,
        (
            length(btrim(i.category)) > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['category']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'category'
                  AND h.verified_values -> 'category' = to_jsonb(i.category)
            )
        ) AS category_verified,
        (
            i.latitude IS NOT NULL
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['latitude']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'latitude'
                  AND h.verified_values -> 'latitude' = to_jsonb(i.latitude)
            )
        ) AS latitude_verified,
        (
            i.longitude IS NOT NULL
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['longitude']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'longitude'
                  AND h.verified_values -> 'longitude' = to_jsonb(i.longitude)
            )
        ) AS longitude_verified,
        (
            i.estimated_duration_minutes IS NOT NULL
            AND i.estimated_duration_minutes > 0
            AND EXISTS (
                SELECT 1 FROM verification_events h
                WHERE h.item_type = i.item_type AND h.item_id = i.id
                  AND h.event_id > COALESCE(lr.latest_rejection_id, 0)
                  AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                  AND COALESCE(h.verified_fields, ARRAY[]::TEXT[]) @> ARRAY['estimated_duration_minutes']::TEXT[]
                  AND COALESCE(h.verified_values, '{}'::JSONB) ? 'estimated_duration_minutes'
                  AND h.verified_values -> 'estimated_duration_minutes'
                      = to_jsonb(i.estimated_duration_minutes)
            )
        ) AS duration_verified
    FROM catalog_items i
    LEFT JOIN event_summary es
      ON es.item_type = i.item_type AND es.item_id = i.id
    LEFT JOIN latest_rejection lr
      ON lr.item_type = i.item_type AND lr.item_id = i.id
),
assessed AS (
    SELECT
        f.*,
        CASE
            WHEN latest_rejection_id IS NOT NULL
             AND (name_verified::INTEGER + description_verified::INTEGER
                  + category_verified::INTEGER + latitude_verified::INTEGER
                  + longitude_verified::INTEGER + duration_verified::INTEGER) < 6
                THEN 'REJECTED'
            WHEN (name_verified::INTEGER + description_verified::INTEGER
                  + category_verified::INTEGER + latitude_verified::INTEGER
                  + longitude_verified::INTEGER + duration_verified::INTEGER) = 6
                THEN 'VERIFIED'
            WHEN (name_verified::INTEGER + description_verified::INTEGER
                  + category_verified::INTEGER + latitude_verified::INTEGER
                  + longitude_verified::INTEGER + duration_verified::INTEGER) > 0
                THEN 'PARTIALLY_VERIFIED'
            ELSE 'UNVERIFIED'
        END AS derived_catalog_status
    FROM field_checks f
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (WHERE event_count = 0) AS records_without_verification_history,
    COUNT(*) FILTER (WHERE event_count > 0) AS records_with_verification_history,
    COUNT(*) FILTER (
        WHERE NOT (
            name_verified AND description_verified AND category_verified
            AND latitude_verified AND longitude_verified AND duration_verified
        )
    ) AS records_missing_core_field_verification,
    COUNT(*) FILTER (WHERE data_status = 'VERIFIED') AS records_currently_marked_verified,
    COUNT(*) FILTER (
        WHERE data_status = 'VERIFIED' AND derived_catalog_status <> 'VERIFIED'
    ) AS verified_status_with_incomplete_core_history,
    COUNT(*) FILTER (
        WHERE event_count > 0 AND data_status IS DISTINCT FROM derived_catalog_status
    ) AS catalog_status_recalculation_mismatch_count,
    COUNT(*) FILTER (
        WHERE event_count > 0 AND derived_catalog_status IS DISTINCT FROM data_status
    ) AS status_mismatch_count,
    COALESCE(SUM(events_with_declared_fields_missing_values), 0)
        AS events_with_declared_fields_missing_values,
    COALESCE(SUM(declared_field_entries_missing_values), 0)
        AS declared_field_entries_missing_values
FROM assessed;
