-- Read-only follow-up audit for the 21 records not included in the six-row
-- correction batch from PR #45.
-- MANUAL execution in pgAdmin. SELECT statements only: no UPDATE/INSERT/DELETE.
-- These records remain UNVERIFIED. This query does not prove current access,
-- prices, opening hours, operator licensing, safety or availability.

WITH target_items AS (
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
      AND (
          (co.iso_code = 'ZA' AND c.name = 'Le Cap' AND a.id IN (6))
          OR (co.iso_code = 'MA' AND c.name = 'Marrakech' AND a.id IN (3, 4))
          OR (co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND a.id IN (1, 2, 7, 8, 9, 10, 11, 12, 13, 16))
      )

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
      AND (
          (co.iso_code = 'MA' AND c.name = 'Marrakech' AND act.id IN (3, 4))
          OR (co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND act.id IN (2, 7, 8, 9, 10, 11))
      )
)
SELECT
    item_type,
    iso_code,
    country,
    city,
    id,
    name,
    source_name,
    source_url,
    source_type,
    source_scope,
    data_status,
    last_verified_at,
    verification_notes
FROM target_items
ORDER BY country, city, item_type, id;

-- Expected population: 21 rows (1 Cape Town attraction, 4 Marrakech records,
-- 16 Zanzibar records). The detail result above is the authoritative list.
-- If fewer rows are returned, inspect the current catalog rather than weakening
-- the city/ID filters.
