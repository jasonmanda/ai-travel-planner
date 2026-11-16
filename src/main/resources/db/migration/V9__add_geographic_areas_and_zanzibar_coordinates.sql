-- V9: add broad geographic areas and sourced reference coordinates for Zanzibar.
-- Coordinates are approximate catalogue reference points, not proof of access or visitor conditions.
-- Every enriched row remains UNVERIFIED until independently checked by a trusted local/official source.
--
-- Sources:
-- Stone Town heritage coordinates: Wikidata WikiProject Tanzania/Monuments
-- https://www.wikidata.org/wiki/Wikidata:WikiProject_Tanzania/Monuments
-- Jozani Forest locality (100 m maximum error): AntWeb CEPF-TZ-10
-- https://www.antweb.org/locality.do?code=CEPF-TZ-10
-- Nungwi study-site coordinates: Frontiers in Marine Science (2026)
-- https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2026.1946229/full
-- Forodhani Gardens coordinate reference: Avygeo
-- https://www.avygeo.com/en/activities/78757-forodhani-gardens

ALTER TABLE attractions
    ADD COLUMN IF NOT EXISTS geographic_area VARCHAR(80);

ALTER TABLE activities
    ADD COLUMN IF NOT EXISTS geographic_area VARCHAR(80);

ALTER TABLE itinerary_items
    ADD COLUMN IF NOT EXISTS geographic_area VARCHAR(80);

-- Broad areas are intentionally distinct from exact GPS coordinates.
UPDATE attractions a
SET geographic_area = CASE
    WHEN a.name IN (
        'Forodhani Gardens', 'House of Wonders', 'Old Fort of Zanzibar',
        'Old Dispensary', 'Christ Church Anglican Cathedral', 'Hamamni Persian Baths'
    ) THEN 'STONE_TOWN'
    WHEN a.name = 'Jozani Forest' THEN 'JOZANI'
    WHEN a.name = 'Prison Island (Changuu)' THEN 'CHANGUU'
    WHEN a.name = 'Nungwi Beach' THEN 'NUNGWI'
    WHEN a.name = 'Paje Beach' THEN 'PAJE'
    WHEN a.name = 'Nakupenda Sandbank' THEN 'OFFSHORE_WEST'
    ELSE a.geographic_area
END
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name IN (
      'Forodhani Gardens', 'House of Wonders', 'Old Fort of Zanzibar',
      'Old Dispensary', 'Christ Church Anglican Cathedral', 'Hamamni Persian Baths',
      'Jozani Forest', 'Prison Island (Changuu)', 'Nungwi Beach',
      'Paje Beach', 'Nakupenda Sandbank'
  );

UPDATE activities a
SET geographic_area = CASE
    WHEN a.name IN (
        'Découverte du patrimoine de Stone Town',
        'Visite guidée du patrimoine de Stone Town',
        'Découverte du marché nocturne de Forodhani'
    ) THEN 'STONE_TOWN'
    WHEN a.name = 'Excursion dans la forêt de Jozani' THEN 'JOZANI'
    WHEN a.name = 'Excursion en bateau vers un banc de sable' THEN 'OFFSHORE_WEST'
    ELSE a.geographic_area
END
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ';

-- Stone Town heritage reference points. These remain UNVERIFIED.
UPDATE attractions a
SET latitude = x.latitude,
    longitude = x.longitude,
    source_name = 'Wikidata WikiProject Tanzania/Monuments - coordinate reference',
    source_url = 'https://www.wikidata.org/wiki/Wikidata:WikiProject_Tanzania/Monuments',
    data_status = 'UNVERIFIED',
    last_verified_at = NULL
FROM cities c
JOIN countries co ON co.id = c.country_id
CROSS JOIN (VALUES
    ('Old Dispensary', -6.15839::DOUBLE PRECISION, 39.19262::DOUBLE PRECISION),
    ('Christ Church Anglican Cathedral', -6.16293::DOUBLE PRECISION, 39.19252::DOUBLE PRECISION),
    ('Hamamni Persian Baths', -6.16233::DOUBLE PRECISION, 39.19098::DOUBLE PRECISION)
) AS x(name, latitude, longitude)
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name = x.name;

-- Jozani reference locality; it is not asserted to be the visitor entrance.
UPDATE attractions a
SET latitude = -6.26755,
    longitude = 39.41111,
    source_name = 'AntWeb CEPF-TZ-10 locality reference (maximum error 100 m)',
    source_url = 'https://www.antweb.org/locality.do?code=CEPF-TZ-10',
    data_status = 'UNVERIFIED',
    last_verified_at = NULL
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name = 'Jozani Forest';

-- Nungwi study-site reference point; not a surveyed boundary for the entire beach.
UPDATE attractions a
SET latitude = -5.7259,
    longitude = 39.2986,
    source_name = 'Frontiers in Marine Science (2026) - Nungwi study-site reference',
    source_url = 'https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2026.1946229/full',
    data_status = 'UNVERIFIED',
    last_verified_at = NULL
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name = 'Nungwi Beach';

-- The Jozani activity refers to the same reserve locality, not a separate operator or route.
UPDATE activities a
SET latitude = -6.26755,
    longitude = 39.41111,
    source_name = 'AntWeb CEPF-TZ-10 locality reference (maximum error 100 m)',
    source_url = 'https://www.antweb.org/locality.do?code=CEPF-TZ-10',
    data_status = 'UNVERIFIED',
    last_verified_at = NULL
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name = 'Excursion dans la forêt de Jozani';

-- Forodhani night-market suggestion is associated with the Gardens reference point.
UPDATE activities a
SET latitude = -6.160680,
    longitude = 39.188616,
    source_name = 'Avygeo Forodhani Gardens coordinate reference',
    source_url = 'https://www.avygeo.com/en/activities/78757-forodhani-gardens',
    data_status = 'UNVERIFIED',
    last_verified_at = NULL
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name = 'Découverte du marché nocturne de Forodhani';
