-- Evidence-based refresh of the 10 remaining DESTINATION_CONTEXT_ONLY catalog records.
-- MANUAL execution in pgAdmin only. This is NOT a Flyway migration.
--
-- Research policy:
--   * Use direct institutional / operator pages that explicitly support the named item.
--   * Where only an operator documents a commercial excursion (Nakupenda), identify it
--     as a secondary/provider source, not as an official government source.
--   * Do not invent opening hours, prices, coordinates, operators or availability.
--   * Broad experience records are made concrete only where the cited source supports it.
--
-- Evidence sources:
-- SANParks Lion's Head / Table Mountain hiking routes:
-- https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails
-- Jardin Majorelle official garden page:
-- https://www.jardinmajorelle.com/lejardin/
-- Zanzibar Parliamentary Budget Committee report on Forodhani Gardens:
-- https://zanzibarassembly.go.tz/storage/documents/Committees/all/1677484498.pdf
-- Zanzibar Petroleum Regulatory Authority EAPCE25 circular (Spice Farm section):
-- https://www.nishati.go.tz/uploads/documents/en-1717415585-EAPCE25%20FIRST%20CIRCULAR.pdf
-- Tanzania Tourist Board CHAN 2024 participant guidebook (Safari Blue / Stone Town walks):
-- https://www.tanzaniatourism.go.tz/data/2025/08/CHAN-2024-Participant-Guidebook-1.pdf
-- Bank of Tanzania, Tanzania Tourism Sector Survey (Paje listed among visited beaches):
-- https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf
-- Zanzibar Ministry of Finance ESMF, Annex E (Forodhani Garden gazetted historic site):
-- https://mofzanzibar.go.tz/wp-content/uploads/2025/12/UPDATED-ESMF-BIG-Z-AFTER-RESTRUCTURING_FINAL-CLEARED-VERSION-BY-THE-WB_DISCLOSED-CLEAN-VERSION-26.11.2025.pdf
-- Provider page identifying the Nakupenda trip (not a government source):
-- https://seastarfish.co.tz/nakupenda
--
-- Integrity:
--   * Each UPDATE is scoped by country, city, item ID/name and previous source URL.
--   * data_status, last_verified_at and verification-history tables are NOT changed.
--   * An institutional source is not proof of current opening, safety or availability.
--   * The Nakupenda page is a provider description; its licensing must be checked with
--     Zanzibar Commission for Tourism before a traveler books.

BEGIN;

-- 1. Cape Town: replace generic nature-hike placeholder with a documented route.
UPDATE activities act
   SET name = 'Randonnée sur Lion''s Head',
       description = 'Randonnée sur le parcours de Lion''s Head dans le Table Mountain National Park. SANParks indique environ 2 km dans un sens, 1 à 1,5 heure de montée et une difficulté facile avec quelques passages rocheux. Aucun point d’eau n’est disponible sur le parcours; les conditions météo et la sécurité doivent être contrôlées avant le départ.',
       estimated_duration_minutes = 90,
       source_name = 'SANParks - Table Mountain National Park: Hikes, Walks & Trails',
       source_url = 'https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page officielle SANParks décrivant explicitement Lion’s Head, la distance approximative, le temps de montée et le niveau de difficulté. Les 90 minutes correspondent à la valeur médiane indicative de la montée (1 à 1,5 h), pas à un aller-retour garanti. Vérifier météo, accès et avis de sécurité le jour de la randonnée.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND co.iso_code = 'ZA' AND c.name = 'Le Cap'
   AND act.id = 5 AND act.name = 'Randonnée en milieu naturel'
   AND act.source_url = 'https://www.sanparks.org/parks/table-mountain/useful-information/visitor-tips';

-- 2. Marrakech: replace generic garden visit with the named, documented Jardin Majorelle.
UPDATE activities act
   SET name = 'Visite du Jardin Majorelle',
       description = 'Visite du Jardin Majorelle à Marrakech, jardin botanique et paysager d’environ 9 000 m² conçu par Jacques Majorelle à partir de 1922. La billetterie officielle recommande une réservation en ligne. Horaires et tarifs doivent être relus sur la page officielle au moment du voyage.',
       source_name = 'Jardin Majorelle - site officiel',
       source_url = 'https://www.jardinmajorelle.com/lejardin/',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page officielle du Jardin Majorelle décrivant le jardin, son histoire, son adresse et la billetterie. La page affiche des informations horaires pouvant varier selon la section ou la mise à jour; aucune heure ni aucun tarif n’est figé dans cette fiche.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND co.iso_code = 'MA' AND c.name = 'Marrakech'
   AND act.id = 3 AND act.name = 'Visite de jardin'
   AND act.source_url = 'https://www.jardinmajorelle.com/lejardin/';

-- 3. Zanzibar: official parliamentary report documents evening vendor activity at Forodhani.
UPDATE activities act
   SET source_name = 'Zanzibar House of Representatives - Forodhani revenue and services committee report',
       source_url = 'https://zanzibarassembly.go.tz/storage/documents/Committees/all/1677484498.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Rapport d’une commission de l’Assemblée de Zanzibar décrivant Forodhani Gardens, son origine en 1936 et l’activité de commerçants qui s’y rassemblent particulièrement le soir pour servir résidents et visiteurs. Le document ne garantit pas les horaires actuels, les vendeurs présents, les prix ni les conditions sanitaires du jour.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND act.id = 11 AND act.name = 'Découverte du marché nocturne de Forodhani'
   AND act.source_url = 'https://visitzanzibar.go.tz/';

-- 4. Zanzibar: official ZPRA event circular has a dedicated Spice Farm section and
-- explicitly describes a Zanzibar Spice Farm tour. Fee in the event circular is
-- historical/event-specific and is deliberately not copied into estimated_cost.
UPDATE activities act
   SET name = 'Visite guidée d’une plantation d’épices à Zanzibar',
       description = 'Visite guidée d’une plantation d’épices à Zanzibar. Une circulaire institutionnelle de la Zanzibar Petroleum Regulatory Authority décrit les fermes d’épices, les cultures et une visite guidée. Le document est lié à un événement et ne permet pas de confirmer les tarifs ou disponibilités actuels.',
       source_name = 'Zanzibar Petroleum Regulatory Authority - EAPCE25 First Circular (Spice Farm)',
       source_url = 'https://www.nishati.go.tz/uploads/documents/en-1717415585-EAPCE25%20FIRST%20CIRCULAR.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'La circulaire institutionnelle contient une section dédiée « SPICE FARM », décrit une Zanzibar Spice Farm tour et affiche un tarif de visite dans le contexte de l’événement EAPCE25. Ce tarif n’est pas considéré comme un prix courant et n’est pas recopié dans la base. Aucun nom de ferme, horaire ou disponibilité actuelle n’est confirmé.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND act.id = 8 AND act.name = 'Découverte d’une ferme aux épices'
   AND act.source_url = 'https://visitzanzibar.go.tz/';

-- 5. Zanzibar: use the Tanzania Tourist Board's documented Safari Blue dhow excursion
-- with a sandbank stop, rather than claiming an unspecified boat operator.
UPDATE activities act
   SET name = 'Excursion Safari Blue en dhow avec arrêt sur un banc de sable',
       description = 'Excursion maritime Safari Blue présentée par le Tanzania Tourist Board comme une sortie en dhow à la journée comprenant plongée avec masque et tuba et déjeuner sur un banc de sable. L’itinéraire exact, l’opérateur, les marées, le prix et la disponibilité doivent être confirmés avant réservation.',
       source_name = 'Tanzania Tourist Board - CHAN 2024 Participant Guidebook',
       source_url = 'https://www.tanzaniatourism.go.tz/data/2025/08/CHAN-2024-Participant-Guidebook-1.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Guide officiel du Tanzania Tourist Board présentant explicitement Safari Blue comme une excursion d’une journée en dhow avec snorkeling et déjeuner sur un banc de sable. Il ne constitue pas une offre de réservation actuelle et ne garantit ni opérateur, ni prix, ni horaires, ni conditions de mer à la date du voyage.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND act.id = 10 AND act.name = 'Excursion en bateau vers un banc de sable'
   AND act.source_url = 'https://visitzanzibar.go.tz/';

-- 6. Zanzibar: narrow the generic beach-day suggestion to Paje, which is explicitly
-- identified as one of the most visited Zanzibar beaches in the Bank of Tanzania survey.
UPDATE activities act
   SET name = 'Journée plage à Paje',
       description = 'Journée de découverte de Paje Beach, plage de la côte est de Zanzibar citée parmi les plages les plus visitées dans l’enquête touristique de la Bank of Tanzania. Cette référence ne certifie pas que la baignade est sûre à une heure donnée: marées, courants, météo, accès et présence éventuelle de sauveteurs doivent être vérifiés localement.',
       source_name = 'Bank of Tanzania - Tanzania Tourism Sector Survey',
       source_url = 'https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Rapport officiel de la Bank of Tanzania qui cite Paje parmi les plages de Zanzibar les plus visitées. Il étaye l’existence et l’intérêt touristique de la plage, mais ne confirme ni l’aptitude à la baignade, ni les marées, courants, qualité de l’eau, sauveteurs ou conditions du jour.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND act.id = 1 AND act.name = 'Journée plage et baignade'
   AND act.source_url = 'https://zbs.go.tz/wp-content/uploads/2026/03/STANDARDS-CATALOGUE-AS-OF-MARCH-2026.pdf';

-- 7. Zanzibar: official Tanzania Tourist Board guidebook describes historical walking
-- tours and Swahili architecture in Stone Town.
UPDATE activities act
   SET name = 'Visite à pied du patrimoine de Stone Town',
       description = 'Découverte à pied du patrimoine historique et de l’architecture swahilie de Stone Town. Le guide du Tanzania Tourist Board présente les visites historiques à pied comme une expérience de la ville. Aucun guide, prestataire, horaire, prix ou départ précis n’est garanti par cette référence.',
       source_name = 'Tanzania Tourist Board - CHAN 2024 Participant Guidebook',
       source_url = 'https://www.tanzaniatourism.go.tz/data/2025/08/CHAN-2024-Participant-Guidebook-1.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Guide officiel du Tanzania Tourist Board mentionnant explicitement les visites historiques à pied de Stone Town et son architecture swahilie. Il documente le type d’expérience, pas un opérateur ou une excursion réservable à une date donnée.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND act.id = 7 AND act.name = 'Visite guidée du patrimoine de Stone Town'
   AND act.source_url = 'https://whc.unesco.org/en/urban-heritage-atlas/stone-town';

-- 8. Zanzibar: official Ministry of Finance document lists Forodhani Garden as a
-- gazetted historic site and documents its historical identity.
UPDATE attractions a
   SET source_name = 'Zanzibar Ministry of Finance - BIG-Z ESMF, Annex E: Historical Sites',
       source_url = 'https://mofzanzibar.go.tz/wp-content/uploads/2025/12/UPDATED-ESMF-BIG-Z-AFTER-RESTRUCTURING_FINAL-CLEARED-VERSION-BY-THE-WB_DISCLOSED-CLEAN-VERSION-26.11.2025.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Annexe E du cadre environnemental et social publié par le ministère des Finances de Zanzibar: Forodhani Garden figure dans la liste des sites historiques classés et le document décrit sa création en 1936. Cette source confirme l’identité et le contexte historique du jardin, mais pas son état, ses horaires, les services ou les travaux en cours à la date du voyage.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND a.id = 1 AND a.name = 'Forodhani Gardens'
   AND a.source_url = 'https://visitzanzibar.go.tz/';

-- 9. Zanzibar: Nakupenda is treated as an excursion-trade name for a sandbank,
-- not asserted as a gazetted or official geographic place name. The source is a
-- private provider page and is classified as GENERIC, not OFFICIAL.
UPDATE attractions a
   SET name = 'Banc de sable au large de Stone Town (excursion dite Nakupenda)',
       description = 'Banc de sable accessible en bateau depuis Stone Town et commercialisé par certains prestataires sous le nom Nakupenda. Le banc dépend des marées et peut être recouvert à marée haute. Le nom commercial ne doit pas être interprété comme une désignation géographique officielle.',
       source_name = 'Sea Star Fish Zanzibar - Nakupenda Trip (provider description)',
       source_url = 'https://seastarfish.co.tz/nakupenda',
       source_type = 'GENERIC',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page d’un prestataire privé décrivant une excursion commercialisée sous le nom Nakupenda, avec départ en bateau depuis le port de Zanzibar et visite du banc de sable. Cette page ne prouve pas que Nakupenda est un toponyme officiel et ne valide pas la licence du prestataire, les tarifs, les horaires ou la disponibilité. Vérifier le prestataire auprès de la Zanzibar Commission for Tourism avant toute réservation.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND a.id = 16 AND a.name = 'Nakupenda Sandbank'
   AND a.source_url = 'https://visitzanzibar.go.tz/';

-- 10. Zanzibar: Bank of Tanzania survey identifies Paje among the most visited
-- Zanzibar beaches. This is a real institutional source, not a claim about bathing safety.
UPDATE attractions a
   SET source_name = 'Bank of Tanzania - Tanzania Tourism Sector Survey',
       source_url = 'https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Rapport officiel de la Bank of Tanzania citant explicitement Paje parmi les plages de Zanzibar les plus visitées. Il étaye l’existence et la fréquentation touristique de Paje Beach, mais ne confirme pas les conditions actuelles d’accès, la baignade, les marées, les courants, la qualité de l’eau ni les services.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND co.iso_code = 'TZ' AND c.name = 'Zanzibar'
   AND a.id = 15 AND a.name = 'Paje Beach'
   AND a.source_url = 'https://visitzanzibar.go.tz/';

COMMIT;

-- Read-only post-run verification. Expected: 10 rows.
-- All rows must remain UNVERIFIED and last_verified_at must remain NULL.
SELECT 'ACTIVITY' AS item_type, co.iso_code, c.name AS city, act.id,
       act.name, act.source_name, act.source_url, act.source_type,
       act.source_scope, act.data_status, act.last_verified_at,
       act.estimated_duration_minutes, act.description, act.verification_notes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code = 'ZA' AND c.name = 'Le Cap' AND act.id = 5
    OR co.iso_code = 'MA' AND c.name = 'Marrakech' AND act.id = 3
    OR co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND act.id IN (1, 3, 7, 8, 10, 11)
UNION ALL
SELECT 'ATTRACTION', co.iso_code, c.name, a.id,
       a.name, a.source_name, a.source_url, a.source_type,
       a.source_scope, a.data_status, a.last_verified_at,
       NULL::INTEGER, a.description, a.verification_notes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND a.id IN (1, 15, 16)
 ORDER BY 2, 3, 1, 5;

-- Summary: remaining broad-source records are intentionally retained as such.
WITH catalog_items AS (
    SELECT source_scope, data_status FROM attractions WHERE active = TRUE
    UNION ALL
    SELECT source_scope, data_status FROM activities WHERE active = TRUE
)
SELECT source_scope, data_status, COUNT(*) AS item_count
  FROM catalog_items
 GROUP BY source_scope, data_status
 ORDER BY source_scope, data_status;
