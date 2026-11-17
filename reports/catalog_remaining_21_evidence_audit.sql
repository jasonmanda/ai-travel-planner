-- Read-only evidence audit for the 21 remaining UNVERIFIED records.
-- MANUAL execution in pgAdmin. NOT a Flyway migration.
-- This script performs SELECT statements only. It does not update catalog data,
-- data_status, last_verified_at, or verification-history records.

WITH targets(item_type, iso_code, city_name, item_id, item_name) AS (
    VALUES
      ('ATTRACTION', 'ZA', 'Le Cap', 6, 'Table Mountain'),
      ('ACTIVITY', 'MA', 'Marrakech', 3, 'Visite du Jardin Majorelle'),
      ('ACTIVITY', 'MA', 'Marrakech', 4, 'Découverte des souks et de la médina'),
      ('ATTRACTION', 'MA', 'Marrakech', 3, 'Jardin Majorelle'),
      ('ATTRACTION', 'MA', 'Marrakech', 4, 'Jemaa el-Fna'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 2, 'Découverte du patrimoine de Stone Town'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 7, 'Visite à pied du patrimoine de Stone Town'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 8, 'Visite guidée d’une plantation d’épices à Zanzibar'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 9, 'Excursion dans la forêt de Jozani'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 10, 'Excursion Safari Blue en dhow avec arrêt sur un banc de sable'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 11, 'Découverte du marché nocturne de Forodhani'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 1, 'Forodhani Gardens'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 2, 'Stone Town'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 7, 'House of Wonders'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 8, 'Old Fort of Zanzibar'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 9, 'Old Dispensary'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 10, 'Christ Church Anglican Cathedral'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 11, 'Hamamni Persian Baths'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 12, 'Jozani Forest'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 13, 'Prison Island (Changuu)'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 16, 'Banc de sable au large de Stone Town (excursion dite Nakupenda)')
),
catalog_items AS (
    SELECT
        'ATTRACTION'::TEXT AS item_type, a.id, co.iso_code, c.name AS city,
        a.name, a.source_name, a.source_url, a.source_type, a.source_scope,
        a.data_status, a.last_verified_at, a.verification_notes
    FROM attractions a
    JOIN cities c ON c.id = a.city_id
    JOIN countries co ON co.id = c.country_id
    UNION ALL
    SELECT
        'ACTIVITY'::TEXT, act.id, co.iso_code, c.name,
        act.name, act.source_name, act.source_url, act.source_type, act.source_scope,
        act.data_status, act.last_verified_at, act.verification_notes
    FROM activities act
    JOIN cities c ON c.id = act.city_id
    JOIN countries co ON co.id = c.country_id
),
matched AS (
    SELECT t.item_type, t.iso_code, t.city_name, t.item_id, t.item_name,
           ci.source_name, ci.source_url, ci.source_type, ci.source_scope,
           ci.data_status, ci.last_verified_at, ci.verification_notes
    FROM targets t
    LEFT JOIN catalog_items ci
      ON ci.item_type = t.item_type
     AND ci.iso_code = t.iso_code
     AND ci.city = t.city_name
     AND ci.id = t.item_id
     AND ci.name = t.item_name
)
SELECT
    item_type, iso_code, city_name AS city, item_id AS id, item_name AS name,
    source_name, source_url, source_type, source_scope,
    data_status, last_verified_at, verification_notes,
    CASE
      WHEN source_name IS NULL OR source_url IS NULL THEN 'MISSING_OR_MISMATCHED_TARGET'
      WHEN data_status <> 'UNVERIFIED' THEN 'STATUS_CHANGED_SINCE_REVIEW'
      WHEN last_verified_at IS NOT NULL THEN 'HAS_VERIFICATION_TIMESTAMP'
      ELSE 'REVIEWED_UNVERIFIED'
    END AS audit_result
FROM matched
ORDER BY iso_code, city_name, item_type, item_id;

-- Expected: 21 rows, all matching the requested names and IDs.
-- This summary exposes any missing/mismatched target or unexpected status.
WITH targets(item_type, iso_code, city_name, item_id, item_name) AS (
    VALUES
      ('ATTRACTION', 'ZA', 'Le Cap', 6, 'Table Mountain'),
      ('ACTIVITY', 'MA', 'Marrakech', 3, 'Visite du Jardin Majorelle'),
      ('ACTIVITY', 'MA', 'Marrakech', 4, 'Découverte des souks et de la médina'),
      ('ATTRACTION', 'MA', 'Marrakech', 3, 'Jardin Majorelle'),
      ('ATTRACTION', 'MA', 'Marrakech', 4, 'Jemaa el-Fna'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 2, 'Découverte du patrimoine de Stone Town'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 7, 'Visite à pied du patrimoine de Stone Town'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 8, 'Visite guidée d’une plantation d’épices à Zanzibar'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 9, 'Excursion dans la forêt de Jozani'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 10, 'Excursion Safari Blue en dhow avec arrêt sur un banc de sable'),
      ('ACTIVITY', 'TZ', 'Zanzibar', 11, 'Découverte du marché nocturne de Forodhani'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 1, 'Forodhani Gardens'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 2, 'Stone Town'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 7, 'House of Wonders'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 8, 'Old Fort of Zanzibar'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 9, 'Old Dispensary'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 10, 'Christ Church Anglican Cathedral'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 11, 'Hamamni Persian Baths'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 12, 'Jozani Forest'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 13, 'Prison Island (Changuu)'),
      ('ATTRACTION', 'TZ', 'Zanzibar', 16, 'Banc de sable au large de Stone Town (excursion dite Nakupenda)')
),
catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.id, co.iso_code, c.name AS city,
           a.name, a.data_status, a.last_verified_at
    FROM attractions a JOIN cities c ON c.id = a.city_id
    JOIN countries co ON co.id = c.country_id
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.id, co.iso_code, c.name,
           act.name, act.data_status, act.last_verified_at
    FROM activities act JOIN cities c ON c.id = act.city_id
    JOIN countries co ON co.id = c.country_id
)
SELECT
    COUNT(*) AS expected_target_count,
    COUNT(ci.id) AS matched_target_count,
    COUNT(*) FILTER (WHERE ci.data_status = 'UNVERIFIED') AS unverified_count,
    COUNT(*) FILTER (WHERE ci.last_verified_at IS NULL) AS without_verification_timestamp
FROM targets t
LEFT JOIN catalog_items ci
  ON ci.item_type = t.item_type
 AND ci.iso_code = t.iso_code
 AND ci.city = t.city_name
 AND ci.id = t.item_id
 AND ci.name = t.item_name;

-- Expected summary: 21 / 21 / 21 / 21 if the reviewed snapshot is unchanged.
