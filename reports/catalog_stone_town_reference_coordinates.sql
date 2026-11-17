-- Guarded, manual correction of the Stone Town reference-point coordinates.
-- Source: UNESCO World Heritage Centre, Stone Town of Zanzibar map:
-- https://whc.unesco.org/en/list/173/maps/
-- UNESCO coordinates: S6 9 47.016, E39 11 21.012
-- Rounded to 3 decimals for the catalog's geographic reference point:
-- latitude -6.163, longitude 39.189.
--
-- Run manually in pgAdmin. This is NOT a Flyway migration.
-- Only fills NULL coordinate pairs for the exact Stone Town records.
-- Does not modify data_status, last_verified_at, durations, or verification history.
-- If either target no longer matches exactly, the block raises an error and rolls back.

BEGIN;

DO $$
DECLARE
    activity_rows INTEGER;
    attraction_rows INTEGER;
BEGIN
    UPDATE activities act
       SET latitude = -6.163,
           longitude = 39.189
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND act.id = 2
       AND act.name = 'Découverte du patrimoine de Stone Town'
       AND act.latitude IS NULL
       AND act.longitude IS NULL;

    GET DIAGNOSTICS activity_rows = ROW_COUNT;

    IF activity_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected exactly 1 Stone Town activity row with NULL coordinates; updated %',
            activity_rows;
    END IF;

    UPDATE attractions a
       SET latitude = -6.163,
           longitude = 39.189
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 2
       AND a.name = 'Stone Town'
       AND a.latitude IS NULL
       AND a.longitude IS NULL;

    GET DIAGNOSTICS attraction_rows = ROW_COUNT;

    IF attraction_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected exactly 1 Stone Town attraction row with NULL coordinates; updated %',
            attraction_rows;
    END IF;
END $$;

COMMIT;
