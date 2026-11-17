-- Manual source-specificity improvements for catalog entries with a defensible,
-- item-focused institutional tourism page.
-- Execute manually in pgAdmin. This is NOT a Flyway migration.
--
-- Safety guarantees:
--   * Updates are guarded by country, city, exact item name AND previous source URL.
--   * Only source metadata and explanatory notes are changed.
--   * data_status, last_verified_at and verification history are never changed.
--   * A page about a place/activity is not proof of current opening, access,
--     price, availability, operator, safety or visit conditions.
--   * Broad suggestions (e.g. "Visite de jardin", "Randonnée en milieu naturel")
--     are intentionally not converted to a named attraction's evidence.
--
-- Research basis:
--   Cape Town Tourism has dedicated pages for the V&A Waterfront:
--   https://www.capetown.travel/neighbourhood/the-va-waterfront/
--   https://www.capetown.travel/top-attractions/va-waterfront/
--   Visit Marrakech has a dedicated page for a walking tour of souks/fondouks:
--   https://visitmarrakech.com/en/listing/visite-a-pied-des-souks-et-des-fondouks/

BEGIN;

-- 1) The V&A Waterfront attraction: replace generic visitor-information endpoint
--    with a dedicated Cape Town Tourism neighbourhood page.
UPDATE attractions a
   SET source_name = 'Cape Town Tourism - The V&A Waterfront',
       source_url = 'https://www.capetown.travel/neighbourhood/the-va-waterfront/',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page dédiée de Cape Town Tourism décrivant le quartier du V&A Waterfront et ses principales attractions. Elle documente le lieu, mais ne confirme pas les horaires, l’ouverture de chaque établissement, les tarifs, les disponibilités ni les conditions du jour.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND c.name = 'Le Cap'
   AND co.iso_code = 'ZA'
   AND a.name = 'V&A Waterfront'
   AND a.source_url = 'https://www.waterfront.co.za/visitor-information';

-- 2) The waterfront discovery activity: use the same dedicated destination page.
--    The note deliberately does not imply that a specific tour/operator is included.
UPDATE activities act
   SET source_name = 'Cape Town Tourism - The V&A Waterfront',
       source_url = 'https://www.capetown.travel/neighbourhood/the-va-waterfront/',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page dédiée de Cape Town Tourism décrivant le secteur du V&A Waterfront et les expériences présentes dans le quartier. Elle étaye le contexte de découverte du front de mer, mais ne confirme aucun prestataire, itinéraire organisé, tarif, créneau ou disponibilité.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id
   AND c.name = 'Le Cap'
   AND co.iso_code = 'ZA'
   AND act.name = 'Découverte du front de mer'
   AND act.source_url = 'https://www.waterfront.co.za/attractions';

-- 3) Souks and medina discovery: use the official Marrakech tourism page dedicated
--    to a walking tour of souks and fondouks.
UPDATE activities act
   SET source_name = 'Visit Marrakech - Walking tour of souks and fondouks',
       source_url = 'https://visitmarrakech.com/en/listing/visite-a-pied-des-souks-et-des-fondouks/',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page dédiée du site officiel du tourisme de Marrakech décrivant une visite à pied des souks et fondouks de la médina. Elle étaye la pertinence de cette expérience, mais ne confirme pas qu’un opérateur précis est réservé, ni le prix, la durée, les horaires ou la disponibilité à la date du voyage.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id
   AND c.name = 'Marrakech'
   AND co.iso_code = 'MA'
   AND act.name = 'Découverte des souks et de la médina'
   AND act.source_url = 'https://www.visitmorocco.com/fr/voyage/marrakech/shopping';

COMMIT;

-- Read-only post-run check. Expected: up to 3 rows, depending on whether each
-- guarded UPDATE matched the current database values. All must remain UNVERIFIED
-- unless a separate, documented field-level verification is performed.
SELECT 'ATTRACTION' AS item_type, co.iso_code, c.name AS city, a.name,
       a.source_name, a.source_url, a.source_type, a.source_scope,
       a.data_status, a.last_verified_at, a.verification_notes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'ZA' AND c.name = 'Le Cap' AND a.name = 'V&A Waterfront')
UNION ALL
SELECT 'ACTIVITY', co.iso_code, c.name, act.name,
       act.source_name, act.source_url, act.source_type, act.source_scope,
       act.data_status, act.last_verified_at, act.verification_notes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE (co.iso_code = 'ZA' AND c.name = 'Le Cap' AND act.name = 'Découverte du front de mer')
    OR (co.iso_code = 'MA' AND c.name = 'Marrakech' AND act.name = 'Découverte des souks et de la médina')
 ORDER BY 2, 3, 1, 4;
