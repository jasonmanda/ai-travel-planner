-- Seed a small, explicitly unverified Zanzibar coordinate sample for geographic-planner validation.
-- Coordinates are reference points only; they do not confirm opening hours, access, safety or visitor availability.
-- Sources:
-- Forodhani Gardens: https://www.avygeo.com/en/activities/78757-forodhani-gardens
-- House of Wonders: https://en.wikipedia.org/wiki/House_of_Wonders
-- Old Fort of Zanzibar: https://en.wikipedia.org/wiki/Old_Fort_of_Zanzibar

UPDATE attractions a
SET latitude = -6.160680,
    longitude = 39.188616,
    source_name = 'Avygeo coordinate reference - verification required',
    source_url = 'https://www.avygeo.com/en/activities/78757-forodhani-gardens',
    data_status = 'UNVERIFIED',
    last_verified_at = NULL
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name = 'Forodhani Gardens';

INSERT INTO attractions (
    city_id, name, category, description, latitude, longitude,
    data_status, source_name, source_url, last_verified_at, active
)
SELECT c.id, x.name, 'HERITAGE', x.description, x.latitude, x.longitude,
       'UNVERIFIED', 'Wikipedia coordinate reference - verification required',
       x.source_url, NULL, TRUE
FROM cities c
JOIN countries co ON co.id = c.country_id
CROSS JOIN (VALUES
    (
        'House of Wonders',
        'Repère patrimonial du front de mer de Stone Town. Accès intérieur, travaux et conditions de visite à confirmer auprès des autorités locales.',
        -6.160914::DOUBLE PRECISION,
        39.189591::DOUBLE PRECISION,
        'https://en.wikipedia.org/wiki/House_of_Wonders'
    ),
    (
        'Old Fort of Zanzibar',
        'Fort historique de Stone Town. Horaires, accès et conditions de visite à confirmer auprès des autorités locales.',
        -6.161390::DOUBLE PRECISION,
        39.189170::DOUBLE PRECISION,
        'https://en.wikipedia.org/wiki/Old_Fort_of_Zanzibar'
    )
) AS x(name, description, latitude, longitude, source_url)
WHERE c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
ON CONFLICT (city_id, name) DO UPDATE
SET category = EXCLUDED.category,
    description = EXCLUDED.description,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    data_status = 'UNVERIFIED',
    source_name = EXCLUDED.source_name,
    source_url = EXCLUDED.source_url,
    last_verified_at = NULL,
    active = TRUE;
