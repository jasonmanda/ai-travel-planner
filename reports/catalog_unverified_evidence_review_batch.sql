-- Evidence review batch for the remaining active UNVERIFIED catalog records.
-- MANUAL execution in pgAdmin only. This is NOT a Flyway migration.
--
-- Scope: six guarded corrections based on the 27-row review:
--   * use the V&A Waterfront's dedicated "Plan Your Day" page;
--   * correct Lion's Head ascent duration from 90 to 75 minutes
--     (midpoint of SANParks' 1–1.5 hour one-way ascent range);
--   * replace the inaccessible/outdated Bank of Tanzania PDF URL for Nungwi/Paje
--     with the accessible 2023 International Visitors' Exit Survey PDF.
--
-- Safety:
--   * Every UPDATE is guarded by country, city, item ID/name and previous value.
--   * data_status, last_verified_at and verification-history tables are untouched.
--   * No prices, opening hours, bathing safety, operator licences or availability
--     are inferred from these sources.
--   * If a guard no longer matches, the UPDATE affects zero rows; investigate rather
--     than weakening the guard.

BEGIN;

-- Fail before changing anything if the reviewed snapshot no longer matches.
-- This keeps the six corrections all-or-nothing.
DO $
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM activities act
      JOIN cities c ON c.id = act.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE co.iso_code = 'ZA' AND c.name = 'Le Cap'
       AND act.id = 6 AND act.name = 'Découverte du front de mer'
       AND act.source_url = 'https://www.waterfront.co.za/attractions';
    IF v_count <> 1 THEN RAISE EXCEPTION 'Precondition failed: V&A Waterfront activity 6'; END IF;

    SELECT COUNT(*) INTO v_count
      FROM attractions a
      JOIN cities c ON c.id = a.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE co.iso_code = 'ZA' AND c.name = 'Le Cap'
       AND a.id = 5 AND a.name = 'V&A Waterfront'
       AND a.source_url = 'https://www.waterfront.co.za/visitor-information';
    IF v_count <> 1 THEN RAISE EXCEPTION 'Precondition failed: V&A Waterfront attraction 5'; END IF;

    SELECT COUNT(*) INTO v_count
      FROM activities act
      JOIN cities c ON c.id = act.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE co.iso_code = 'ZA' AND c.name = 'Le Cap'
       AND act.id = 5 AND act.name = 'Randonnée sur Lion''s Head'
       AND act.source_url = 'https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails'
       AND act.estimated_duration_minutes = 90;
    IF v_count <> 1 THEN RAISE EXCEPTION 'Precondition failed: Lion''s Head activity 5'; END IF;

    SELECT COUNT(*) INTO v_count
      FROM attractions a
      JOIN cities c ON c.id = a.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND a.id = 14 AND a.name = 'Nungwi Beach'
       AND a.source_url = 'https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2026.1946229/full';
    IF v_count <> 1 THEN RAISE EXCEPTION 'Precondition failed: Nungwi Beach attraction 14'; END IF;

    SELECT COUNT(*) INTO v_count
      FROM activities act
      JOIN cities c ON c.id = act.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND act.id = 1 AND act.name = 'Journée plage à Paje'
       AND act.source_url = 'https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf';
    IF v_count <> 1 THEN RAISE EXCEPTION 'Precondition failed: Paje activity 1'; END IF;

    SELECT COUNT(*) INTO v_count
      FROM attractions a
      JOIN cities c ON c.id = a.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar'
       AND a.id = 15 AND a.name = 'Paje Beach'
       AND a.source_url = 'https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf';
    IF v_count <> 1 THEN RAISE EXCEPTION 'Precondition failed: Paje Beach attraction 15'; END IF;
END $;

-- 1. V&A Waterfront activity: use the official curated itinerary/attractions page.
UPDATE activities act
   SET source_name = 'V&A Waterfront - Plan Your Day (official attractions and itineraries)',
       source_url = 'https://www.waterfront.co.za/attractions/plan-your-day',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page officielle du V&A Waterfront présentant des itinéraires de découverte et des attractions précises du precinct (aquarium, Cape Wheel, parcours patrimonial, etc.). Elle étaye l’existence d’expériences de découverte sur le site, mais ne confirme pas un prestataire, un tarif, un créneau ou une disponibilité propres à une activité réservée.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id
   AND co.iso_code = 'ZA' AND c.name = 'Le Cap'
   AND act.id = 6 AND act.name = 'Découverte du front de mer'
   AND act.source_url = 'https://www.waterfront.co.za/attractions';

-- 2. V&A Waterfront attraction: use the same dedicated page for the precinct's
--    named attractions and curated visitor itineraries.
UPDATE attractions a
   SET source_name = 'V&A Waterfront - Plan Your Day (official attractions and itineraries)',
       source_url = 'https://www.waterfront.co.za/attractions/plan-your-day',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page officielle du gestionnaire du V&A Waterfront présentant les attractions, districts et itinéraires de visite du precinct. Elle confirme le contexte de visite du lieu, mais ne garantit pas les horaires, tarifs, accès ou disponibilités des attractions individuelles à la date du voyage.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND co.iso_code = 'ZA' AND c.name = 'Le Cap'
   AND a.id = 5 AND a.name = 'V&A Waterfront'
   AND a.source_url = 'https://www.waterfront.co.za/visitor-information';

-- 3. Lion's Head: 1–1.5 hours up has a midpoint of 75 minutes, not 90.
--    This is the one-way ascent only, not a round trip.
UPDATE activities act
   SET estimated_duration_minutes = 75,
       description = 'Randonnée sur le parcours de Lion’s Head dans le Table Mountain National Park. SANParks indique environ 2 km dans un sens, 1 à 1,5 heure de montée et une difficulté facile avec quelques passages rocheux. La durée indicative de 75 minutes correspond au milieu de la fourchette de montée et ne comprend pas le retour. Aucun point d’eau n’est disponible sur le parcours; vérifier météo, accès et consignes de sécurité avant le départ.',
       verification_notes = 'Page officielle SANParks décrivant explicitement Lion’s Head, la distance approximative, le temps de montée et le niveau de difficulté. La durée enregistrée de 75 minutes est le milieu arithmétique de la fourchette publiée (1 à 1,5 heure) et concerne uniquement la montée, pas un aller-retour garanti. Vérifier météo, accès et avis de sécurité le jour de la randonnée.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id
   AND co.iso_code = 'ZA' AND c.name = 'Le Cap'
   AND act.id = 5 AND act.name = 'Randonnée sur Lion''s Head'
   AND act.source_url = 'https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails'
   AND act.estimated_duration_minutes = 90;

-- 4. Nungwi Beach: replace the scientific study-site reference with a government
--    tourism-sector report that names Nungwi as a Zanzibar beach destination.
UPDATE attractions a
   SET source_name = 'Bank of Tanzania - Tanzania Tourism Sector Survey (2023 International Visitors’ Exit Survey Report)',
       source_url = 'https://www.bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025021916491906.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Le rapport institutionnel Tanzania Tourism Sector Survey (rapport de l’enquête de sortie des visiteurs 2023) cite Nungwi parmi les zones balnéaires touristiques de Zanzibar dans une section de contexte qui reprend une référence au magazine Travelers Worldwide. Il étaye l’identification de Nungwi comme destination balnéaire, mais ne constitue pas une étude opérationnelle de la plage et ne confirme ni accès, baignade, marées, courants, qualité de l’eau, sauveteurs, services ou conditions actuelles.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND a.id = 14 AND a.name = 'Nungwi Beach'
   AND a.source_url = 'https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2026.1946229/full';

-- 5. Paje activity: correct the Bank of Tanzania PDF URL to the accessible official
--    2023 exit-survey document. The cited passage is contextual, not a safety report.
UPDATE activities act
   SET source_name = 'Bank of Tanzania - Tanzania Tourism Sector Survey (2023 International Visitors’ Exit Survey Report)',
       source_url = 'https://www.bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025021916491906.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Le rapport institutionnel Tanzania Tourism Sector Survey (rapport de l’enquête de sortie des visiteurs 2023) cite Paje parmi les destinations balnéaires de Zanzibar dans une section de contexte qui reprend une référence au magazine Travelers Worldwide. Il étaye l’intérêt touristique de Paje, mais ne confirme ni l’aptitude à la baignade, ni les marées, courants, qualité de l’eau, sauveteurs, services ou conditions du jour.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id
   AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND act.id = 1 AND act.name = 'Journée plage à Paje'
   AND act.source_url = 'https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf';

-- 6. Paje attraction: same corrected source URL and explicit evidence limitations.
UPDATE attractions a
   SET source_name = 'Bank of Tanzania - Tanzania Tourism Sector Survey (2023 International Visitors’ Exit Survey Report)',
       source_url = 'https://www.bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025021916491906.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Le rapport institutionnel Tanzania Tourism Sector Survey (rapport de l’enquête de sortie des visiteurs 2023) cite Paje parmi les destinations balnéaires de Zanzibar dans une section de contexte qui reprend une référence au magazine Travelers Worldwide. Il étaye l’identification et l’intérêt touristique de Paje Beach, mais ne confirme ni l’accès actuel, ni la baignade, les marées, courants, qualité de l’eau, sauveteurs, services ou conditions du jour.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND a.id = 15 AND a.name = 'Paje Beach'
   AND a.source_url = 'https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf';

COMMIT;

-- Post-run verification: inspect all six targets. Expected: 6 rows.
-- All remain UNVERIFIED and last_verified_at remains NULL.
SELECT 'ACTIVITY' AS item_type, co.iso_code, c.name AS city, act.id, act.name,
       act.source_name, act.source_url, act.source_type, act.source_scope,
       act.data_status, act.last_verified_at, act.estimated_duration_minutes,
       act.verification_notes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'ZA' AND c.name = 'Le Cap' AND act.id IN (5, 6))
    OR (co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND act.id = 1)
UNION ALL
SELECT 'ATTRACTION', co.iso_code, c.name, a.id, a.name,
       a.source_name, a.source_url, a.source_type, a.source_scope,
       a.data_status, a.last_verified_at, NULL::INTEGER,
       a.verification_notes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'ZA' AND c.name = 'Le Cap' AND a.id = 5)
    OR (co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND a.id IN (14, 15))
 ORDER BY 2, 3, 1, 5;
