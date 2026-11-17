-- Guarded manual corrections for the remaining 27-record catalog review batch.
-- Run manually in pgAdmin. This is NOT a Flyway migration.
--
-- Scope:
--   * 10 coordinate pairs are added as map/reference points.
--   * 4 activity durations are added as itinerary estimates from named local tour providers.
--   * 1 generic Spice Farm activity deliberately receives no coordinates because the
--     catalog item does not identify one specific farm among several farms in Zanzibar.
--   * No data_status, last_verified_at, source fields, or verification-history rows change.
--   * Coordinate and duration provenance is appended to verification_notes.
--   * Every update requires the expected country, city, ID, and NULL target field.
--   * The transaction aborts unless every expected update affects exactly one row.
--
-- Coordinate references:
-- Marrakech Souks (OSM way 1222593640): https://mapcarta.com/W1222593640
-- Jemaa el-Fna (OSM way 1132585098): https://mapcarta.com/27389480
-- Paje Beach (GPS point): https://www.avygeo.com/fr/guide/lieux-interet/78766-plage-de-paje
-- Stone Town UNESCO reference point: https://whc.unesco.org/en/list/173/maps/
-- Safari Blue named map point / Fumba departure area (OSM node 6540223812):
--   https://mapcarta.com/N6540223812
-- Nakupenda Sandbank position: https://beach-matters.com/beaches/nakupenda/
-- V&A Waterfront (OSM way 689159965): https://mapcarta.com/W689159965
-- Table Mountain (geographic feature): https://mapcarta.com/19067054
--
-- Duration references:
-- Marrakech souks/medina guided walk (~3 h):
--   https://www.visit-marrakech-medina.com/en/walking-tours-in-marrakech-explore-the-medina-on-foot
-- Stone Town walking tour (~3 h):
--   https://afrigo.co.tz/tours/stone-town-tour
-- Spice farm tour (~3–4 h; 210 min midpoint estimate):
--   https://afrigo.co.tz/tours/spice-farm-tour
-- Safari Blue (~8–9 h; 510 min midpoint estimate):
--   https://afrigo.co.tz/tours/safari-blue
--
-- These are map anchors and operator-specific duration estimates, not proof of
-- complete catalog verification or universal visit durations. All records remain UNVERIFIED.

BEGIN;

DO $$
DECLARE
    rows_updated INTEGER;
BEGIN
    -- COORDINATES: Marrakech.
    UPDATE activities act
       SET latitude = 31.62890,
           longitude = -7.98806,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point: Marrakech Souks OSM way 1222593640; map anchor, not a complete route. https://mapcarta.com/W1222593640'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'MA' AND c.name = 'Marrakech'
       AND act.id = 4 AND act.latitude IS NULL AND act.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Marrakech souks activity coordinate update; got %', rows_updated; END IF;

    UPDATE attractions a
       SET latitude = 31.62582,
           longitude = -7.98924,
           verification_notes = COALESCE(NULLIF(BTRIM(a.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point: Jemaa el-Fna OSM way 1132585098. https://mapcarta.com/27389480'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id AND co.iso_code = 'MA' AND c.name = 'Marrakech'
       AND a.id = 4 AND a.name = 'Jemaa el-Fna'
       AND a.latitude IS NULL AND a.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Jemaa el-Fna attraction coordinate update; got %', rows_updated; END IF;

    -- COORDINATES: Zanzibar.
    UPDATE activities act
       SET latitude = -6.267261,
           longitude = 39.536082,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point for Paje Beach; GPS reference, not a full beach boundary. https://www.avygeo.com/fr/guide/lieux-interet/78766-plage-de-paje'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND act.id = 1 AND act.latitude IS NULL AND act.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Paje activity coordinate update; got %', rows_updated; END IF;

    UPDATE activities act
       SET latitude = -6.163,
           longitude = 39.189,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point: UNESCO Stone Town property coordinates; city/heritage anchor, not a route start. https://whc.unesco.org/en/list/173/maps/'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND act.id = 7 AND act.latitude IS NULL AND act.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Stone Town walking activity coordinate update; got %', rows_updated; END IF;

    UPDATE activities act
       SET latitude = -6.31772,
           longitude = 39.27737,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point: mapped Safari Blue location in Fumba, used as departure-area anchor; excursion route extends offshore. https://mapcarta.com/N6540223812'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND act.id = 10 AND act.latitude IS NULL AND act.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Safari Blue activity coordinate update; got %', rows_updated; END IF;

    UPDATE attractions a
       SET latitude = -6.267261,
           longitude = 39.536082,
           verification_notes = COALESCE(NULLIF(BTRIM(a.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point for Paje Beach; GPS reference, not a full beach boundary. https://www.avygeo.com/fr/guide/lieux-interet/78766-plage-de-paje'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND a.id = 15 AND a.name = 'Paje Beach'
       AND a.latitude IS NULL AND a.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Paje attraction coordinate update; got %', rows_updated; END IF;

    UPDATE attractions a
       SET latitude = -6.23330,
           longitude = 39.15000,
           verification_notes = COALESCE(NULLIF(BTRIM(a.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point for Nakupenda Sandbank (6°13.998 S, 39°9.000 E); tidal sandbank position, not a permanent land boundary. https://beach-matters.com/beaches/nakupenda/'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND a.id = 16 AND a.latitude IS NULL AND a.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Nakupenda attraction coordinate update; got %', rows_updated; END IF;

    -- COORDINATES: Cape Town.
    UPDATE activities act
       SET latitude = -33.90602,
           longitude = 18.42392,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point: Victoria & Alfred Waterfront OSM way 689159965. https://mapcarta.com/W689159965'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'ZA' AND c.name = 'Le Cap'
       AND act.id = 6 AND act.latitude IS NULL AND act.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 V&A activity coordinate update; got %', rows_updated; END IF;

    UPDATE attractions a
       SET latitude = -33.90602,
           longitude = 18.42392,
           verification_notes = COALESCE(NULLIF(BTRIM(a.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point: Victoria & Alfred Waterfront OSM way 689159965. https://mapcarta.com/W689159965'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id AND co.iso_code = 'ZA' AND c.name = 'Le Cap'
       AND a.id = 5 AND a.latitude IS NULL AND a.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 V&A attraction coordinate update; got %', rows_updated; END IF;

    UPDATE attractions a
       SET latitude = -33.96216,
           longitude = 18.41352,
           verification_notes = COALESCE(NULLIF(BTRIM(a.verification_notes), '') || E'\n', '')
               || 'Coordinate reference point for Table Mountain landform; not the cableway station or a trailhead. https://mapcarta.com/19067054'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id AND co.iso_code = 'ZA' AND c.name = 'Le Cap'
       AND a.id = 6 AND a.latitude IS NULL AND a.longitude IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Table Mountain attraction coordinate update; got %', rows_updated; END IF;

    -- DURATIONS: operator-specific itinerary estimates, not universal visit times.
    UPDATE activities act
       SET estimated_duration_minutes = 180,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Estimated duration 180 min (~3 h) based on a local guided Marrakech medina/souks walk; operator-specific itinerary, not a universal visit duration. https://www.visit-marrakech-medina.com/en/walking-tours-in-marrakech-explore-the-medina-on-foot'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'MA' AND c.name = 'Marrakech'
       AND act.id = 4 AND act.estimated_duration_minutes IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Marrakech activity duration update; got %', rows_updated; END IF;

    UPDATE activities act
       SET estimated_duration_minutes = 180,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Estimated duration 180 min (~3 h) based on AfriGo Stone Town Walking Tour itinerary; operator-specific estimate. https://afrigo.co.tz/tours/stone-town-tour'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND act.id = 7 AND act.estimated_duration_minutes IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Stone Town activity duration update; got %', rows_updated; END IF;

    UPDATE activities act
       SET estimated_duration_minutes = 210,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Estimated duration 210 min (midpoint of operator range 3–4 h) based on AfriGo Spice Farm Tour; operator-specific estimate, transfer and lunch inclusions may vary. https://afrigo.co.tz/tours/spice-farm-tour'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND act.id = 8 AND act.estimated_duration_minutes IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Spice Farm activity duration update; got %', rows_updated; END IF;

    UPDATE activities act
       SET estimated_duration_minutes = 510,
           verification_notes = COALESCE(NULLIF(BTRIM(act.verification_notes), '') || E'\n', '')
               || 'Estimated duration 510 min (midpoint of operator range 8–9 h) based on AfriGo Safari Blue itinerary; operator-specific full-day estimate, timing varies with pickup and sea conditions. https://afrigo.co.tz/tours/safari-blue'
      FROM cities c JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND act.id = 10 AND act.estimated_duration_minutes IS NULL;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    IF rows_updated <> 1 THEN RAISE EXCEPTION 'Expected 1 Safari Blue activity duration update; got %', rows_updated; END IF;
END $$;

COMMIT;

-- Post-run verification for every row touched by this batch.
SELECT 'ACTIVITY' AS item_type, act.id, act.name, c.name AS city, co.iso_code,
       act.latitude, act.longitude, act.estimated_duration_minutes,
       act.data_status, act.last_verified_at, act.verification_notes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'MA' AND act.id = 4)
    OR (co.iso_code = 'TZ' AND act.id IN (1, 7, 8, 10))
    OR (co.iso_code = 'ZA' AND act.id = 6)
UNION ALL
SELECT 'ATTRACTION', a.id, a.name, c.name, co.iso_code,
       a.latitude, a.longitude, a.estimated_duration_minutes,
       a.data_status, a.last_verified_at, a.verification_notes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'MA' AND a.id = 4)
    OR (co.iso_code = 'TZ' AND a.id IN (15, 16))
    OR (co.iso_code = 'ZA' AND a.id IN (5, 6))
ORDER BY iso_code, item_type, id;
