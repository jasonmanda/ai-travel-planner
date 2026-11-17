-- Manual, narrowly scoped source correction for Lion's Head.
-- Run in pgAdmin. This is NOT a Flyway migration.
-- The UPDATE is guarded by the expected old URL, item name, city and country.
-- No status, verification timestamp, coordinates, duration or price is changed.

BEGIN;

UPDATE activities act
SET source_name = 'SANParks - Lion''s Head & Signal Hill (official attraction page)',
    source_url = 'https://www.sanparks.org/parks/table-mountain/what-to-do/attractions/lions-head-signal-hill'
WHERE act.id = 5
  AND act.name = 'Randonnée sur Lion''s Head'
  AND act.source_url = 'https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails'
  AND EXISTS (
      SELECT 1
      FROM cities c
      JOIN countries co ON co.id = c.country_id
      WHERE c.id = act.city_id
        AND c.name = 'Le Cap'
        AND co.iso_code = 'ZA'
  );

-- Expected: exactly one updated row. If not, ROLLBACK and inspect the row.
SELECT
    act.id,
    act.name,
    act.source_name,
    act.source_url,
    act.estimated_duration_minutes,
    act.data_status,
    act.last_verified_at
FROM activities act
JOIN cities c ON c.id = act.city_id
JOIN countries co ON co.id = c.country_id
WHERE co.iso_code = 'ZA'
  AND c.name = 'Le Cap'
  AND act.name = 'Randonnée sur Lion''s Head';

-- Review the returned row, then COMMIT if the UPDATE affected exactly one row.
-- Otherwise use ROLLBACK.
-- COMMIT;
-- ROLLBACK;
