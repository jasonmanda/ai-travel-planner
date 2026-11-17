-- Batch reduction of generic catalog sources where an official source
-- explicitly names the attraction or describes the relevant park activity.
-- MANUAL execution in pgAdmin only. This file is NOT a Flyway migration.
--
-- Safety:
--   * Exact country, city, item name and previous URL guards.
--   * Only source metadata and verification_notes are updated.
--   * data_status, last_verified_at and verification-history tables are untouched.
--   * ITEM_SPECIFIC means the page explicitly identifies/describes the named
--     place or park experience; it does NOT mean current visit conditions verified.
--   * Broad activity ideas remain generic where no matching official evidence exists.
--
-- Sources consulted:
-- UNESCO Stone Town page explicitly names Christ Church, Hamamni baths,
-- House of Wonders, Old Dispensary and Old Fort:
-- https://whc.unesco.org/en/list/173
-- UNESCO intangible heritage page dedicated to Jemaa el-Fna:
-- https://ich.unesco.org/fr/RL/l-espace-culturel-de-la-place-jemaa-el-fna-00014
-- Official Jozani Chwaka Bay National Park site (guided tours / visitor information):
-- https://maliasilismz.go.tz/index.php

BEGIN;

-- 1) Jemaa el-Fna: official UNESCO page dedicated to the cultural space.
UPDATE attractions a
   SET source_name = 'UNESCO - Espace culturel de la place Jemaa el-Fna',
       source_url = 'https://ich.unesco.org/fr/RL/l-espace-culturel-de-la-place-jemaa-el-fna-00014',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page UNESCO consacrée à l’espace culturel de la place Jemaa el-Fna. Elle étaye la reconnaissance et les pratiques culturelles associées au lieu, mais ne confirme pas les horaires actuels, les vendeurs présents, les prix, la sécurité ni les conditions de visite à une date donnée.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND c.name = 'Marrakech'
   AND co.iso_code = 'MA'
   AND a.name = 'Jemaa el-Fna'
   AND a.source_url = 'https://mjcc.gov.ma/fr/departements/culture/patrimoine-materiel-national/';

-- 2) Stone Town monuments explicitly named by UNESCO.
-- The page is dedicated to the World Heritage property and names each monument;
-- it does not establish current opening, interior access or visitor services.
UPDATE attractions a
   SET source_name = 'UNESCO World Heritage Centre - Stone Town of Zanzibar',
       source_url = 'https://whc.unesco.org/en/list/173',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = CASE a.name
         WHEN 'Christ Church Anglican Cathedral' THEN 'La page UNESCO consacrée à Stone Town nomme explicitement Christ Church Anglican Cathedral et décrit son importance dans le patrimoine du site. Elle ne confirme pas l’ouverture actuelle, l’accès intérieur, les horaires, les tarifs ni les services visiteurs.'
         WHEN 'Hamamni Persian Baths' THEN 'La page UNESCO consacrée à Stone Town nomme explicitement les bains Hamamni parmi les monuments historiques. Elle documente leur importance patrimoniale, mais ne confirme pas leur ouverture actuelle, l’accès intérieur, les horaires, les tarifs ni les conditions de visite.'
         WHEN 'House of Wonders' THEN 'La page UNESCO consacrée à Stone Town nomme explicitement la House of Wonders parmi les monuments du bien inscrit. Elle documente son importance patrimoniale, mais ne confirme pas son état actuel, son ouverture, l’accès intérieur ni les conditions de visite.'
         WHEN 'Old Dispensary' THEN 'La page UNESCO consacrée à Stone Town nomme explicitement l’Old Dispensary parmi les monuments historiques. Elle documente son importance patrimoniale, mais ne confirme pas son ouverture actuelle, l’accès intérieur, les horaires ni les services visiteurs.'
         WHEN 'Old Fort of Zanzibar' THEN 'La page UNESCO consacrée à Stone Town nomme explicitement l’Old Fort parmi les monuments historiques. Elle documente son importance patrimoniale, mais ne confirme pas l’ouverture actuelle, les horaires, les tarifs ni les conditions de visite.'
         ELSE a.verification_notes
       END
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND c.name = 'Zanzibar'
   AND co.iso_code = 'TZ'
   AND a.name IN (
       'Christ Church Anglican Cathedral',
       'Hamamni Persian Baths',
       'House of Wonders',
       'Old Dispensary',
       'Old Fort of Zanzibar'
   )
   AND a.source_url IN (
       'https://whc.unesco.org/en/urban-heritage-atlas/stone-town',
       'https://whc.unesco.org/en/list/173'
   );

-- 3) Jozani Forest attraction: use the official park site, not the generic
-- tourism destination homepage.
UPDATE attractions a
   SET source_name = 'Jozani Chwaka Bay National Park - official park website',
       source_url = 'https://maliasilismz.go.tz/index.php',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Site officiel du parc national de Jozani Chwaka Bay, consacré au parc et à ses attractions naturelles, dont le Zanzibar Red Colobus. Il présente des informations visiteurs et des visites guidées, mais ne confirme pas pour cette fiche les tarifs, horaires applicables le jour du voyage, disponibilité, accès ou conditions opérationnelles.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND c.name = 'Zanzibar'
   AND co.iso_code = 'TZ'
   AND a.name = 'Jozani Forest'
   AND a.source_url = 'https://maliasilismz.go.tz/';

-- 4) Jozani excursion: the official park page explicitly mentions guided tours.
-- This does not verify a particular operator, booking, price or departure time.
UPDATE activities act
   SET source_name = 'Jozani Chwaka Bay National Park - official park website',
       source_url = 'https://maliasilismz.go.tz/index.php',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Site officiel du parc national de Jozani Chwaka Bay indiquant que des visites guidées sont proposées. Cette source soutient la pertinence d’une découverte guidée du parc, mais ne confirme pas un opérateur précis, une réservation, la durée, le prix, les horaires ou la disponibilité à la date du voyage.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id
   AND c.name = 'Zanzibar'
   AND co.iso_code = 'TZ'
   AND act.name = 'Excursion dans la forêt de Jozani'
   AND act.source_url = 'https://maliasilismz.go.tz/';

COMMIT;

-- Read-only post-run check: the expected set is up to 8 rows.
-- Every row must still be UNVERIFIED and last_verified_at must remain unchanged.
SELECT 'ATTRACTION' AS item_type, co.iso_code, c.name AS city, a.name,
       a.source_name, a.source_url, a.source_type, a.source_scope,
       a.data_status, a.last_verified_at, a.verification_notes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'MA' AND c.name = 'Marrakech' AND a.name = 'Jemaa el-Fna')
    OR (co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND a.name IN (
       'Christ Church Anglican Cathedral', 'Hamamni Persian Baths',
       'House of Wonders', 'Old Dispensary', 'Old Fort of Zanzibar',
       'Jozani Forest'
    ))
UNION ALL
SELECT 'ACTIVITY', co.iso_code, c.name, act.name,
       act.source_name, act.source_url, act.source_type, act.source_scope,
       act.data_status, act.last_verified_at, act.verification_notes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code = 'TZ'
   AND c.name = 'Zanzibar'
   AND act.name = 'Excursion dans la forêt de Jozani'
 ORDER BY 2, 3, 1, 4;
