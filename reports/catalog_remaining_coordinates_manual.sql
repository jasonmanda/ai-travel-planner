-- Guarded, manual coordinate corrections for the catalog follow-up batch.
-- Run manually in pgAdmin. This is NOT a Flyway migration.
--
-- Coordinate references:
-- Jardin Majorelle (OSM way 41922120; representative point):
-- https://www.openstreetmap.org/way/41922120
-- Prison Island / Changuu (Zanzibar House of Representatives budget document):
-- https://www.zanzibarassembly.go.tz/public/storage/documents/Budgets/all/1735288194.pdf
-- Lion's Head (South African History Online place record):
-- https://sahistory.org.za/place/lions-head-mt
--
-- This script only fills coordinate pairs that are both NULL, for exact
-- country/city/id/name matches. It does not modify sources, durations,
-- data_status, last_verified_at, or verification history.
-- Any unexpected row count aborts the transaction.

BEGIN;

DO $$
DECLARE
    rows_updated INTEGER;
BEGIN
    -- Marrakech: Jardin Majorelle activity.
    UPDATE activities act
       SET latitude = 31.64137,
           longitude = -8.00292
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND co.iso_code = 'MA'
       AND c.name = 'Marrakech'
       AND act.id = 3
       AND act.latitude IS NULL
       AND act.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN
        RAISE EXCEPTION 'Expected 1 Jardin Majorelle activity row; updated %', rows_updated;
    END IF;

    -- Marrakech: Jardin Majorelle attraction.
    UPDATE attractions a
       SET latitude = 31.64137,
           longitude = -8.00292
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'MA'
       AND c.name = 'Marrakech'
       AND a.id = 3
       AND a.name = 'Jardin Majorelle'
       AND a.latitude IS NULL
       AND a.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN
        RAISE EXCEPTION 'Expected 1 Jardin Majorelle attraction row; updated %', rows_updated;
    END IF;

    -- Zanzibar: Prison Island / Changuu.
    UPDATE attractions a
       SET latitude = -6.120402,
           longitude = 39.168599
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 13
       AND a.name = 'Prison Island (Changuu)'
       AND a.latitude IS NULL
       AND a.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN
        RAISE EXCEPTION 'Expected 1 Prison Island attraction row; updated %', rows_updated;
    END IF;

    -- Cape Town: Lion's Head activity (mountain reference point, not trailhead).
    UPDATE activities act
       SET latitude = -33.9696,
           longitude = 18.3969
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND co.iso_code = 'ZA'
       AND c.name = 'Le Cap'
       AND act.id = 5
       AND act.latitude IS NULL
       AND act.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN
        RAISE EXCEPTION 'Expected 1 Lion''s Head activity row; updated %', rows_updated;
    END IF;
END $$;

COMMIT;

-- Post-run verification (read-only).
SELECT 'ACTIVITY' AS item_type, act.id, act.name, c.name AS city,
       co.iso_code, act.latitude, act.longitude, act.data_status,
       act.estimated_duration_minutes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'MA' AND act.id = 3)
    OR (co.iso_code = 'ZA' AND act.id = 5)
UNION ALL
SELECT 'ATTRACTION', a.id, a.name, c.name, co.iso_code,
       a.latitude, a.longitude, a.data_status, a.estimated_duration_minutes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'MA' AND a.id = 3)
    OR (co.iso_code = 'TZ' AND a.id = 13)
ORDER BY iso_code, item_type, id;
