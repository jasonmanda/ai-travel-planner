-- V14: classify existing catalog sources conservatively.
-- Source classification describes the source itself, not factual verification of the catalog item.
-- No data_status or last_verified_at values are changed by this migration.

-- UNESCO's Stone Town heritage atlas is an institutional source covering the wider
-- historic urban area. It does not establish current opening hours, access or prices
-- for each individual attraction.
UPDATE attractions
SET source_type = 'OFFICIAL',
    source_scope = 'DESTINATION_GENERAL',
    verification_notes = 'Source institutionnelle UNESCO sur le patrimoine urbain de Stone Town. Elle documente le contexte patrimonial général, mais ne confirme pas à elle seule les horaires, l’accès actuel, les tarifs ni les conditions de visite de ce lieu.'
WHERE source_url = 'https://whc.unesco.org/en/urban-heritage-atlas/stone-town';

UPDATE activities
SET source_type = 'OFFICIAL',
    source_scope = 'DESTINATION_GENERAL',
    verification_notes = 'Source institutionnelle UNESCO sur le patrimoine urbain de Stone Town. Elle apporte un contexte patrimonial général, mais ne confirme pas l’existence d’un prestataire, la disponibilité, la durée, le prix ou les modalités actuelles de cette activité.'
WHERE source_url = 'https://whc.unesco.org/en/urban-heritage-atlas/stone-town';

-- Visit Zanzibar is the official destination tourism portal. Its scope is the
-- destination, not a guarantee about a particular operator or current conditions.
UPDATE attractions
SET source_type = 'OFFICIAL',
    source_scope = 'DESTINATION_GENERAL',
    verification_notes = 'Portail touristique officiel de Zanzibar. Source utile pour le contexte et la promotion de la destination, mais qui ne confirme pas à elle seule l’accès actuel, les horaires, les tarifs, la sécurité ou les services de ce lieu.'
WHERE source_url = 'https://visitzanzibar.go.tz/';

UPDATE activities
SET source_type = 'OFFICIAL',
    source_scope = 'DESTINATION_GENERAL',
    verification_notes = 'Portail touristique officiel de Zanzibar. La source concerne la destination dans son ensemble et ne confirme pas un opérateur précis, la disponibilité, le prix, la durée, la sécurité ou les conditions actuelles de cette activité.'
WHERE source_url = 'https://visitzanzibar.go.tz/';

-- Wikipedia is an encyclopedic secondary source. The linked article concerns
-- the named attraction, but its coordinates and descriptions still need review.
UPDATE attractions
SET source_type = 'ENCYCLOPEDIC',
    source_scope = 'ITEM_SPECIFIC',
    verification_notes = 'Article encyclopédique consacré à ce monument. Référence documentaire secondaire ; les coordonnées, l’état actuel, l’accès et les conditions de visite doivent être confirmés auprès de sources locales ou institutionnelles.'
WHERE source_url IN (
    'https://en.wikipedia.org/wiki/House_of_Wonders',
    'https://en.wikipedia.org/wiki/Old_Fort_of_Zanzibar'
);

-- Scientific research sources provide a study/locality reference, not a visitor
-- entrance, surveyed attraction boundary or current visitor information.
UPDATE attractions
SET source_type = 'SCIENTIFIC',
    source_scope = 'ITEM_SPECIFIC',
    verification_notes = 'Référence issue d’un article scientifique identifiant un site d’étude à Nungwi. Le point géographique ne représente pas nécessairement les limites de toute la plage et ne confirme ni accès, ni services, ni conditions de baignade.'
WHERE source_url = 'https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2026.1946229/full';

UPDATE attractions
SET source_type = 'SCIENTIFIC',
    source_scope = 'ITEM_SPECIFIC',
    verification_notes = 'Référence scientifique de localité AntWeb (erreur maximale annoncée de 100 m). Elle situe une localité associée à la forêt de Jozani, mais ne constitue pas une coordonnée vérifiée de l’entrée visiteurs ni une confirmation des conditions d’accès.'
WHERE source_url = 'https://www.antweb.org/locality.do?code=CEPF-TZ-10';

UPDATE activities
SET source_type = 'SCIENTIFIC',
    source_scope = 'ITEM_SPECIFIC',
    verification_notes = 'Référence scientifique de localité AntWeb (erreur maximale annoncée de 100 m). Elle concerne une localité de la forêt de Jozani, pas un itinéraire touristique, un opérateur ou une entrée visiteurs vérifiés.'
WHERE source_url = 'https://www.antweb.org/locality.do?code=CEPF-TZ-10';

-- Avygeo is a generic secondary travel reference. Here it is used only as a
-- geographic reference for Forodhani Gardens, not as proof of current conditions.
UPDATE attractions
SET source_type = 'GENERIC',
    source_scope = 'ITEM_SPECIFIC',
    verification_notes = 'Référence touristique secondaire utilisée pour un point de repère géographique. Elle ne constitue pas une source officielle et ne confirme pas les horaires, l’accès, les services ou les conditions actuelles du site.'
WHERE source_url = 'https://www.avygeo.com/en/activities/78757-forodhani-gardens';

UPDATE activities
SET source_type = 'GENERIC',
    source_scope = 'ITEM_SPECIFIC',
    verification_notes = 'Référence touristique secondaire associée au point de repère des jardins de Forodhani. Elle ne confirme pas les horaires du marché, les jours d’ouverture, les vendeurs, les prix ou les conditions actuelles.'
WHERE source_url = 'https://www.avygeo.com/en/activities/78757-forodhani-gardens';

-- Wikidata WikiProject pages and starter records without a direct source URL
-- intentionally remain UNKNOWN until their source nature and exact coverage
-- can be established. All records retain their existing UNVERIFIED status.
