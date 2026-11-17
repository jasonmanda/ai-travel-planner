-- Read-only audit of factual verification-history coverage for active catalog records.
-- Run manually in pgAdmin. SELECT statements only; NOT a Flyway migration.
-- Does not update catalog rows, verification history, last_verified_at or recommendation rules.
--
-- A source classification is not a verification event.
-- Only fields explicitly present in a VERIFIED history event count as verified below.
-- The required core field list is an audit lens, not a new application eligibility rule.

WITH catalog_items AS (
    SELECT
        'ATTRACTION'::TEXT AS item_type,
        a.id,
        co.iso_code,
        c.name AS city,
        a.name,
        a.category,
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
        ARRAY(
            SELECT DISTINCT field_name
            FROM verification_events e2
            CROSS JOIN LATERAL unnest(e2.verified_fields) AS field_name
            WHERE e2.item_type = e.item_type
              AND e2.item_id = e.item_id
              AND e2.verification_status = 'VERIFIED'
            ORDER BY field_name
        ) AS cumulatively_verified_fields
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
assessed AS (
    SELECT
        i.*,
        COALESCE(ec.verification_event_count, 0) AS verification_event_count,
        COALESCE(ec.verified_event_count, 0) AS verified_event_count,
        COALESCE(ec.partially_verified_event_count, 0) AS partially_verified_event_count,
        COALESCE(ec.rejected_event_count, 0) AS rejected_event_count,
        COALESCE(ec.cumulatively_verified_fields, ARRAY[]::TEXT[]) AS cumulatively_verified_fields,
        le.event_id AS latest_event_id,
        le.verification_status AS latest_event_status,
        le.verified_fields AS latest_event_fields,
        le.source_name AS latest_event_source_name,
        le.source_url AS latest_event_source_url,
        le.verified_by AS latest_event_verified_by,
        le.verified_at AS latest_event_at,
        ARRAY(
            SELECT required_field
            FROM unnest(i.required_core_fields) AS required_field
            WHERE NOT (
                required_field = ANY(
                    COALESCE(ec.cumulatively_verified_fields, ARRAY[]::TEXT[])
                )
            )
            ORDER BY required_field
        ) AS missing_core_verified_fields,
        (
            le.event_id IS NOT NULL
            AND i.data_status IS DISTINCT FROM le.verification_status
        ) AS history_status_mismatch
    FROM catalog_items i
    LEFT JOIN event_coverage ec
      ON ec.item_type = i.item_type
     AND ec.item_id = i.id
    LEFT JOIN latest_event le
      ON le.item_type = i.item_type
     AND le.item_id = i.id
)
SELECT
    item_type,
    iso_code,
    city,
    id,
    name,
    category,
    data_status,
    last_verified_at,
    verification_event_count,
    verified_event_count,
    partially_verified_event_count,
    rejected_event_count,
    latest_event_id,
    latest_event_status,
    latest_event_at,
    latest_event_fields,
    cumulatively_verified_fields,
    missing_core_verified_fields,
    cardinality(missing_core_verified_fields) = 0 AS core_fields_have_verified_history,
    history_status_mismatch,
    latest_event_source_name,
    latest_event_source_url,
    latest_event_verified_by
FROM assessed
ORDER BY iso_code, city, item_type, name;

-- Summary: count records with no history, incomplete core-field coverage,
-- and status/history inconsistencies. This is not the recommendation-eligibility audit.
WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.id, a.data_status,
           ARRAY['name', 'category', 'description', 'latitude', 'longitude',
                 'estimated_duration_minutes']::TEXT[] AS required_core_fields
    FROM attractions a
    WHERE a.active = TRUE AND a.data_status <> 'REJECTED'

    UNION ALL

    SELECT 'ACTIVITY'::TEXT, act.id, act.data_status,
           ARRAY['name', 'category', 'description', 'latitude', 'longitude',
                 'estimated_duration_minutes']::TEXT[]
    FROM activities act
    WHERE act.active = TRUE AND act.data_status <> 'REJECTED'
),
verification_events AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, h.attraction_id AS item_id,
           h.verification_status, h.verified_fields, h.verified_at, h.id AS event_id
    FROM attraction_verification_history h

    UNION ALL

    SELECT 'ACTIVITY'::TEXT, h.activity_id,
           h.verification_status, h.verified_fields, h.verified_at, h.id
    FROM activity_verification_history h
),
coverage AS (
    SELECT
        i.item_type,
        i.id,
        i.data_status,
        i.required_core_fields,
        COUNT(e.event_id) AS event_count,
        ARRAY(
            SELECT DISTINCT field_name
            FROM verification_events e2
            CROSS JOIN LATERAL unnest(e2.verified_fields) AS field_name
            WHERE e2.item_type = i.item_type
              AND e2.item_id = i.id
              AND e2.verification_status = 'VERIFIED'
            ORDER BY field_name
        ) AS verified_fields,
        (
            SELECT e3.verification_status
            FROM verification_events e3
            WHERE e3.item_type = i.item_type
              AND e3.item_id = i.id
            ORDER BY e3.verified_at DESC, e3.event_id DESC
            LIMIT 1
        ) AS latest_event_status
    FROM catalog_items i
    LEFT JOIN verification_events e
      ON e.item_type = i.item_type
     AND e.item_id = i.id
    GROUP BY i.item_type, i.id, i.data_status, i.required_core_fields
),
assessed AS (
    SELECT *,
        NOT (verified_fields @> required_core_fields) AS core_coverage_incomplete,
        (latest_event_status IS NOT NULL
         AND data_status IS DISTINCT FROM latest_event_status) AS history_status_mismatch
    FROM coverage
)
SELECT
    COUNT(*) AS active_candidate_count,
    COUNT(*) FILTER (WHERE event_count = 0) AS records_without_verification_history,
    COUNT(*) FILTER (WHERE event_count > 0) AS records_with_verification_history,
    COUNT(*) FILTER (WHERE core_coverage_incomplete) AS records_missing_core_field_verification,
    COUNT(*) FILTER (WHERE data_status = 'VERIFIED') AS records_currently_marked_verified,
    COUNT(*) FILTER (WHERE data_status = 'VERIFIED' AND core_coverage_incomplete)
        AS verified_status_with_incomplete_core_history,
    COUNT(*) FILTER (WHERE history_status_mismatch) AS history_status_mismatch_count
FROM assessed;
