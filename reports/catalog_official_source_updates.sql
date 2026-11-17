-- Manual catalog source refresh for Cape Town, Marrakech and Zanzibar.
-- Execute manually in pgAdmin (this is NOT an automatically executed Flyway migration).
-- Every UPDATE is scoped by country, city and exact item name.
-- This script changes source metadata and explanatory notes only:
--   * data_status is deliberately NOT changed;
--   * last_verified_at is deliberately NOT changed;
--   * no verification-history row is inserted;
--   * official documentation is not equivalent to factual verification.
--
-- Some activities are broad suggestions rather than named attractions. Where the
-- official source is only contextual, source_scope remains DESTINATION_GENERAL.
-- Those records must not be treated as item-specific evidence.

BEGIN;

-- 1) Attractions that previously had no usable source (5 records).
UPDATE attractions a
   SET source_name = 'South African National Parks (SANParks) - Table Mountain National Park',
       source_url = 'https://www.sanparks.org/parks/table-mountain',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page institutionnelle du parc national de Table Mountain. Elle documente le parc et son cadre de visite, mais les accès précis, conditions météo, sentiers ouverts et consignes du jour doivent être contrôlés avant le départ.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND c.name = 'Le Cap' AND co.iso_code = 'ZA'
   AND a.name = 'Table Mountain';

UPDATE attractions a
   SET source_name = 'V&A Waterfront - Visitor information',
       source_url = 'https://www.waterfront.co.za/visitor-information',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page officielle du gestionnaire du V&A Waterfront avec informations visiteurs, accès, transports et services. Les horaires et disponibilités des attractions individuelles doivent être vérifiés sur leurs pages propres.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND c.name = 'Le Cap' AND co.iso_code = 'ZA'
   AND a.name = 'V&A Waterfront';

UPDATE attractions a
   SET source_name = 'Jardin Majorelle - site officiel',
       source_url = 'https://www.jardinmajorelle.com/lejardin/',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page officielle du Jardin Majorelle décrivant le jardin et ses informations pratiques. Les horaires et tarifs peuvent évoluer et doivent être reconsultés à la date du voyage.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND c.name = 'Marrakech' AND co.iso_code = 'MA'
   AND a.name = 'Jardin Majorelle';

UPDATE attractions a
   SET source_name = 'Ministère de la Jeunesse, de la Culture et de la Communication - Patrimoine matériel national',
       source_url = 'https://mjcc.gov.ma/fr/departements/culture/patrimoine-materiel-national/',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Inventaire institutionnel marocain mentionnant la place Jamaa El Fna et son classement patrimonial. Il étaye son identification patrimoniale, pas les événements, horaires, vendeurs ou conditions actuelles.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND c.name = 'Marrakech' AND co.iso_code = 'MA'
   AND a.name = 'Jemaa el-Fna';

UPDATE attractions a
   SET source_name = 'UNESCO World Heritage Centre - Stone Town of Zanzibar',
       source_url = 'https://whc.unesco.org/en/list/173',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Fiche officielle UNESCO du bien patrimonial Stone Town. Elle documente l’ensemble historique et ses monuments, mais ne confirme pas les horaires, l’ouverture intérieure, l’accès ni l’état actuel de chaque bâtiment.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
   AND a.name = 'Stone Town';

-- 2) Activities that previously had no usable source (6 records).
UPDATE activities act
   SET source_name = 'V&A Waterfront - Things to do and visitor experiences',
       source_url = 'https://www.waterfront.co.za/attractions',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Répertoire officiel des attractions et expériences du V&A Waterfront. Il étaye l’existence du precinct et de ses offres publiées, mais chaque prestataire, tarif, créneau et disponibilité doit être vérifié séparément.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND c.name = 'Le Cap' AND co.iso_code = 'ZA'
   AND act.name = 'Découverte du front de mer';

UPDATE activities act
   SET source_name = 'SANParks - Table Mountain National Park visitor tips',
       source_url = 'https://www.sanparks.org/parks/table-mountain/useful-information/visitor-tips',
       source_type = 'OFFICIAL',
       source_scope = 'DESTINATION_GENERAL',
       verification_notes = 'Consignes officielles de randonnée et de sécurité dans le parc national de Table Mountain. La fiche d’activité reste générique et ne désigne pas un sentier précis; météo, accès et fermeture de sentiers doivent être contrôlés.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND c.name = 'Le Cap' AND co.iso_code = 'ZA'
   AND act.name = 'Randonnée en milieu naturel';

UPDATE activities act
   SET source_name = 'Visit Morocco - Shopping and souks in Marrakech',
       source_url = 'https://www.visitmorocco.com/fr/voyage/marrakech/shopping',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page de l’office national marocain du tourisme décrivant les souks de Marrakech. Elle documente le contexte de découverte, sans confirmer un guide, un itinéraire, les horaires de chaque échoppe ni les prix.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND c.name = 'Marrakech' AND co.iso_code = 'MA'
   AND act.name = 'Découverte des souks et de la médina';

UPDATE activities act
   SET source_name = 'Jardin Majorelle - site officiel',
       source_url = 'https://www.jardinmajorelle.com/lejardin/',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Page officielle du Jardin Majorelle. Cette référence correspond à ce jardin précis; elle ne permet pas de généraliser ses horaires ou tarifs à tous les jardins de Marrakech.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND c.name = 'Marrakech' AND co.iso_code = 'MA'
   AND act.name = 'Visite de jardin';

UPDATE activities act
   SET source_name = 'Ministry of Tourism and Heritage Zanzibar - Stone Town visitor guidelines (UNESCO document)',
       source_url = 'https://whc.unesco.org/document/218167',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Consignes officielles destinées aux visiteurs du site patrimonial de Stone Town, publiées par le Ministry of Tourism and Heritage Zanzibar. Le document recommande les guides enregistrés, mais ne désigne aucun prestataire, tarif ou durée.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
   AND act.name = 'Découverte du patrimoine de Stone Town';

UPDATE activities act
   SET source_name = 'Zanzibar Bureau of Standards - Standards Catalogue (beach safety standard)',
       source_url = 'https://zbs.go.tz/wp-content/uploads/2026/03/STANDARDS-CATALOGUE-AS-OF-MARCH-2026.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'DESTINATION_GENERAL',
       verification_notes = 'Catalogue officiel des normes de Zanzibar mentionnant une norme de sécurité des services de plage. La fiche ne désigne aucune plage précise et ne garantit pas les conditions locales de baignade, courants, marées ou présence de sauveteurs.'
  FROM cities c JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id AND c.name = 'Zanzibar' AND co.iso_code = 'TZ'
   AND act.name = 'Journée plage et baignade';

-- 3) Replace selected generic/secondary sources with official references.
-- The source scope remains broad wherever the official page covers the wider site
-- rather than the individual activity or monument.

UPDATE attractions
   SET source_name = 'UNESCO World Heritage Centre - Stone Town of Zanzibar',
       source_url = 'https://whc.unesco.org/en/list/173',
       source_type = 'OFFICIAL',
       source_scope = 'DESTINATION_GENERAL',
       verification_notes = 'Référence officielle sur l’ensemble patrimonial de Stone Town. Elle donne le contexte et cite les monuments, mais ne confirme pas les modalités actuelles de visite de ce bâtiment.'
 WHERE source_url IN (
       'https://en.wikipedia.org/wiki/House_of_Wonders',
       'https://en.wikipedia.org/wiki/Old_Fort_of_Zanzibar'
 );

UPDATE attractions
   SET source_name = 'UNESCO Urban Heritage Atlas - Stone Town of Zanzibar',
       source_url = 'https://whc.unesco.org/en/urban-heritage-atlas/stone-town',
       source_type = 'OFFICIAL',
       source_scope = 'DESTINATION_GENERAL',
       verification_notes = 'Atlas institutionnel du tissu urbain historique de Stone Town; il mentionne plusieurs bâtiments patrimoniaux, mais ne confirme pas leur ouverture, accès intérieur ou état actuel.'
 WHERE source_url LIKE '%wikidata.org/wiki/Wikidata:WikiProject_Tanzania/Monuments%';

UPDATE attractions
   SET source_name = 'Jozani Chwaka Bay National Park - site officiel du gouvernement de Zanzibar',
       source_url = 'https://maliasilismz.go.tz/contact.php',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Site officiel du parc national de Jozani Chwaka Bay, avec informations sur le parc, ses habitats et les expériences visiteurs. Les horaires, tarifs et conditions d’accès doivent être vérifiés directement auprès du parc.'
 WHERE source_url = 'https://www.antweb.org/locality.do?code=CEPF-TZ-10';

UPDATE activities
   SET source_name = 'Jozani Chwaka Bay National Park - site officiel du gouvernement de Zanzibar',
       source_url = 'https://maliasilismz.go.tz/contact.php',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Site officiel du parc national de Jozani Chwaka Bay. Il documente le site et les activités de découverte, sans confirmer un itinéraire précis, une durée ou un tarif pour cette fiche.'
 WHERE source_url = 'https://www.antweb.org/locality.do?code=CEPF-TZ-10';

UPDATE attractions
   SET source_name = 'Visit Zanzibar - official tourism portal',
       source_url = 'https://visitzanzibar.go.tz/',
       source_type = 'OFFICIAL',
       source_scope = 'DESTINATION_GENERAL',
       verification_notes = 'Le portail officiel de Zanzibar présente le Forodhani Night Market comme expérience touristique. La page d’accueil ne confirme pas les horaires, jours, vendeurs ou conditions propres aux jardins; cette référence reste contextuelle.'
 WHERE source_url = 'https://www.avygeo.com/en/activities/78757-forodhani-gardens';

UPDATE activities
   SET source_name = 'Visit Zanzibar - official tourism portal',
       source_url = 'https://visitzanzibar.go.tz/',
       source_type = 'OFFICIAL',
       source_scope = 'DESTINATION_GENERAL',
       verification_notes = 'Le portail touristique officiel présente notamment le Forodhani Night Market. L’URL enregistrée pointe vers la page d’accueil; elle ne constitue donc pas une page dédiée permettant de confirmer les jours, horaires, vendeurs ou prix.'
 WHERE source_url = 'https://www.avygeo.com/en/activities/78757-forodhani-gardens';

COMMIT;

-- Post-run check: all 11 formerly undocumented starter entries should now have
-- source metadata, but remain UNVERIFIED. Any missing row indicates a name/city
-- mismatch and must be investigated rather than force-updated.
SELECT 'ATTRACTION' AS item_type, c.name AS city, a.name, a.source_name, a.source_url,
       a.source_type, a.source_scope, a.data_status
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code IN ('ZA', 'MA', 'TZ')
   AND a.name IN ('Table Mountain', 'V&A Waterfront', 'Jardin Majorelle', 'Jemaa el-Fna', 'Stone Town')
UNION ALL
SELECT 'ACTIVITY', c.name, act.name, act.source_name, act.source_url,
       act.source_type, act.source_scope, act.data_status
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code IN ('ZA', 'MA', 'TZ')
   AND act.name IN (
       'Découverte du front de mer',
       'Randonnée en milieu naturel',
       'Découverte des souks et de la médina',
       'Visite de jardin',
       'Découverte du patrimoine de Stone Town',
       'Journée plage et baignade'
   )
 ORDER BY 2, 1, 3;
