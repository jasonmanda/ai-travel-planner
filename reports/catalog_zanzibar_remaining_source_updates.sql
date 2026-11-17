-- Manual, guarded source-quality corrections for the remaining Zanzibar records.
-- Run manually in pgAdmin. NOT a Flyway migration.
--
-- This script:
--   * separates operator-owned tour pages from institutional sources;
--   * corrects the dedicated Jozani park authority URL;
--   * downgrades broad destination/event references to DESTINATION_GENERAL;
--   * leaves Prison Island and Nakupenda unchanged where evidence is insufficient.
--
-- It never changes data_status, last_verified_at, verification history,
-- coordinates, durations, costs or itinerary records.

BEGIN;

DO $$
DECLARE
    n INTEGER;
BEGIN
    -- 1) Spice-farm visit: first-party offer from a Zanzibar tour operator.
    UPDATE activities act
       SET source_name = 'Sea Star Fish Zanzibar - Spice Tour',
           source_url = 'https://seastarfish.co.tz/spice-tour',
           source_type = 'OPERATOR_PRIMARY',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'Page publiée par Sea Star Fish décrivant sa propre excursion Spice Tour dans des plantations près de Stone Town. Source primaire sur cette offre commerciale uniquement; elle ne prouve pas que toutes les fermes proposent cette visite, ni les coordonnées, la durée réelle, le prix applicable ou la disponibilité à une date donnée.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND act.id = 8
       AND act.data_status = 'UNVERIFIED'
       AND act.source_type = 'OFFICIAL'
       AND act.source_scope = 'ITEM_SPECIFIC'
       AND act.source_url ILIKE '%nishati.go.tz%EAPCE25%';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded spice-farm activity update, got %; transaction rolled back.', n;
    END IF;

    -- 2) Safari Blue: use the named excursion's own operator page.
    UPDATE activities act
       SET source_name = 'Safari Blue - Original Experience (operator)',
           source_url = 'https://safariblue.net/tours/original-experience/',
           source_type = 'OPERATOR_PRIMARY',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'Page officielle de l’opérateur Safari Blue décrivant son Original Experience dans la zone de conservation de Menai. Source primaire sur cette excursion propre à l’opérateur; elle ne constitue pas une validation institutionnelle indépendante et ne garantit pas la disponibilité, les conditions maritimes, le prix ou les transferts à la date du voyage.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND act.id = 10
       AND act.data_status = 'UNVERIFIED'
       AND act.source_type = 'OFFICIAL'
       AND act.source_scope = 'ITEM_SPECIFIC'
       AND act.source_url ILIKE '%tanzaniatourism.go.tz%CHAN-2024%Participant-Guidebook%';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Safari Blue activity update, got %; transaction rolled back.', n;
    END IF;

    -- 3) Jozani: the root site is dedicated to the Jozani Chwaka Bay National Park
    -- authority itself; unlike a generic destination portal, it contains park,
    -- visitor, guided-tour and attraction information.
    UPDATE activities act
       SET source_name = 'Jozani Chwaka Bay National Park - official park authority',
           source_url = 'https://maliasilismz.go.tz/',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'Site officiel de l’administration du parc national Jozani Chwaka Bay, consacré à ce parc; il décrit les visites guidées, les promenades dans la nature et les attractions du parc. Les horaires, tarifs, accès du jour, durée et disponibilité doivent être vérifiés séparément.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND act.id = 9
       AND act.name = 'Excursion dans la forêt de Jozani'
       AND act.data_status = 'UNVERIFIED'
       AND act.source_type = 'OFFICIAL'
       AND act.source_scope = 'ITEM_SPECIFIC'
       AND act.source_url = 'https://maliasilismz.go.tz/index.php';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Jozani activity update, got %; transaction rolled back.', n;
    END IF;

    UPDATE attractions a
       SET source_name = 'Jozani Chwaka Bay National Park - official park authority',
           source_url = 'https://maliasilismz.go.tz/',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'Site officiel de l’administration du parc national Jozani Chwaka Bay, consacré au parc et à ses attractions naturelles, notamment le Zanzibar Red Colobus. Les horaires, tarifs, accès du jour et conditions de visite doivent être vérifiés séparément.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND a.id = 12
       AND a.name = 'Jozani Forest'
       AND a.data_status = 'UNVERIFIED'
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'ITEM_SPECIFIC'
       AND a.source_url = 'https://maliasilismz.go.tz/index.php';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Jozani attraction update, got %; transaction rolled back.', n;
    END IF;

    -- 4) These sources describe the destination/site or an event document,
    -- not the specific activity. Preserve the references but correct their scope.
    UPDATE activities act
       SET source_scope = 'DESTINATION_GENERAL',
           verification_notes = 'La source institutionnelle décrit un contexte touristique ou patrimonial plus large, pas cette activité précise ni un opérateur actuel. Elle est conservée comme contexte uniquement; durée, accès, prix et disponibilité restent à vérifier.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND act.id = 1
       AND act.data_status = 'UNVERIFIED'
       AND act.source_type = 'OFFICIAL'
       AND act.source_scope = 'ITEM_SPECIFIC'
       AND act.source_url ILIKE '%bot.go.tz%Tanzania%Tourism%Sector%Survey%';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Paje activity scope correction, got %; transaction rolled back.', n;
    END IF;

    UPDATE activities act
       SET source_scope = 'DESTINATION_GENERAL',
           verification_notes = 'Les consignes officielles concernent le site patrimonial de Stone Town et les visiteurs en général; elles ne prouvent pas à elles seules l’existence, la durée ou les modalités d’une activité organisée de découverte du patrimoine.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND act.id = 2
       AND act.name = 'Découverte du patrimoine de Stone Town'
       AND act.data_status = 'UNVERIFIED'
       AND act.source_type = 'OFFICIAL'
       AND act.source_scope = 'ITEM_SPECIFIC'
       AND act.source_url ILIKE '%whc.unesco.org%218167%';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Stone Town heritage activity scope correction, got %; transaction rolled back.', n;
    END IF;

    UPDATE activities act
       SET source_scope = 'DESTINATION_GENERAL',
           verification_notes = 'Le guide CHAN est un document institutionnel lié à un événement et ne constitue pas une preuve directe d’une visite à pied actuellement proposée à Stone Town. Il est conservé comme contexte touristique général uniquement.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE act.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND act.id = 7
       AND act.data_status = 'UNVERIFIED'
       AND act.source_type = 'OFFICIAL'
       AND act.source_scope = 'ITEM_SPECIFIC'
       AND act.source_url ILIKE '%tanzaniatourism.go.tz%CHAN-2024%Participant-Guidebook%';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Stone Town walking activity scope correction, got %; transaction rolled back.', n;
    END IF;

    UPDATE attractions a
       SET source_scope = 'DESTINATION_GENERAL',
           verification_notes = 'L’enquête touristique nationale cite Nungwi parmi les plages fréquentées de Zanzibar, mais ne vérifie pas les limites exactes du site, l’accès, les services, la sécurité ou les conditions de baignade actuelles.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND a.id = 14 AND a.name = 'Nungwi Beach'
       AND a.data_status = 'UNVERIFIED'
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'ITEM_SPECIFIC'
       AND a.source_url ILIKE '%bot.go.tz%Tanzania%Tourism%Sector%Survey%';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Nungwi source-scope correction, got %; transaction rolled back.', n;
    END IF;

    UPDATE attractions a
       SET source_scope = 'DESTINATION_GENERAL',
           verification_notes = 'L’enquête touristique nationale cite Paje parmi les plages fréquentées de Zanzibar, mais ne vérifie pas les limites exactes du site, l’accès, les services, la sécurité ou les conditions de baignade actuelles.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
       AND a.id = 15 AND a.name = 'Paje Beach'
       AND a.data_status = 'UNVERIFIED'
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'ITEM_SPECIFIC'
       AND a.source_url ILIKE '%bot.go.tz%Tanzania%Tourism%Sector%Survey%';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected one guarded Paje attraction scope correction, got %; transaction rolled back.', n;
    END IF;
END $$;

COMMIT;

-- Read-only post-run check. Every updated row must remain UNVERIFIED and
-- last_verified_at must remain NULL. Prison Island and Nakupenda are deliberately
-- not updated by this script.
SELECT 'ACTIVITY' AS item_type, co.iso_code, c.name AS city, act.id, act.name,
       act.source_name, act.source_url, act.source_type, act.source_scope,
       act.data_status, act.last_verified_at, act.verification_notes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND act.id IN (1, 2, 7, 8, 9, 10)
UNION ALL
SELECT 'ATTRACTION', co.iso_code, c.name, a.id, a.name,
       a.source_name, a.source_url, a.source_type, a.source_scope,
       a.data_status, a.last_verified_at, a.verification_notes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND a.id IN (12, 13, 14, 15, 16)
 ORDER BY 2, 3, 1, 4;
