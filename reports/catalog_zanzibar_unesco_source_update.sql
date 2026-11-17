-- Manual, guarded source-metadata correction for six Zanzibar heritage attractions.
-- Run manually in pgAdmin. This is NOT a Flyway migration.
-- Replaces the broad UNESCO World Heritage List page with the UNESCO Urban Heritage Atlas,
-- which contains named sections for Stone Town and the listed individual monuments.
-- No data_status, verification history, coordinates, duration, cost, or itinerary data changes.
-- All six records remain UNVERIFIED after this update.

DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE attractions a
       SET source_name = 'UNESCO World Heritage Centre - Urban Heritage Atlas: Stone Town of Zanzibar',
           source_url = 'https://whc.unesco.org/en/urban-heritage-atlas/stone-town'
      FROM (
          VALUES
              (2, 'Stone Town'),
              (7, 'House of Wonders'),
              (8, 'Old Fort of Zanzibar'),
              (9, 'Old Dispensary'),
              (10, 'Christ Church Anglican Cathedral'),
              (11, 'Hamamni Persian Baths')
      ) AS target(id, expected_name)
     WHERE a.id = target.id
       AND a.name = target.expected_name
       AND a.data_status = 'UNVERIFIED'
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'ITEM_SPECIFIC'
       AND a.source_url = 'https://whc.unesco.org/en/list/173'
       AND EXISTS (
           SELECT 1
             FROM cities c
             JOIN countries co ON co.id = c.country_id
            WHERE c.id = a.city_id
              AND c.name = 'Zanzibar'
              AND co.iso_code = 'TZ'
       );

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count <> 6 THEN
        RAISE EXCEPTION
            'Expected to update exactly 6 guarded Zanzibar attractions, but updated %; transaction rolled back.',
            updated_count;
    END IF;
END $$;

-- Read-only confirmation: all six records must still be UNVERIFIED.
SELECT
    a.id,
    a.name,
    a.data_status,
    a.source_name,
    a.source_url,
    a.source_type,
    a.source_scope,
    a.last_verified_at
FROM attractions a
JOIN cities c ON c.id = a.city_id
JOIN countries co ON co.id = c.country_id
WHERE co.iso_code = 'TZ'
  AND c.name = 'Zanzibar'
  AND a.id IN (2, 7, 8, 9, 10, 11)
ORDER BY a.id;
