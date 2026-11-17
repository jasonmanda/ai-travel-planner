-- Guarded manual source metadata review for the eight remaining Zanzibar source failures.
-- Run manually in pgAdmin. NOT a Flyway migration.
--
-- Five records receive a more item-specific institutional reference:
--   ACTIVITY TZ/Zanzibar 1 (Paje beach day)
--   ACTIVITY TZ/Zanzibar 2 and 7 (Stone Town heritage discovery / walking)
--   ATTRACTION TZ/Zanzibar 14 (Nungwi Beach)
--   ATTRACTION TZ/Zanzibar 15 (Paje Beach)
--
-- ATTRACTION TZ/Zanzibar 16 (Nakupenda) is correctly reclassified as
-- OPERATOR_PRIMARY: the cited page is the provider's own excursion description,
-- not an institutional/geographic confirmation of an official place name.
--
-- Safari Blue (ACTIVITY 10) and Spice Tour (ACTIVITY 8) remain OPERATOR_PRIMARY.
-- No coordinates are invented for Spice Tour. All records remain UNVERIFIED.
-- This script changes source metadata and explanatory notes only.

BEGIN;

DO $$
DECLARE
    n INTEGER;
BEGIN
    -- Paje activity: the Tanzanian High Commission page explicitly names Paje
    -- among Zanzibar's best-known beaches. It does not establish live conditions.
    UPDATE activities a
       SET source_name = 'Tanzania High Commission in the United Kingdom - Zanzibar Tropical Paradise in Africa',
           source_url = 'https://www.uk.tzembassy.go.tz/news/view/zanzibar-tropical-paradise-in-africa',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'La page officielle de la High Commission de Tanzanie cite explicitement Paje parmi les plages connues du sud-est de Zanzibar. Elle appuie l’identification de Paje comme lieu de plage, mais ne confirme ni les conditions actuelles d’accès, ni la sécurité, ni les services, ni les horaires, ni les coûts, ni la durée de cette activité. La fiche reste UNVERIFIED.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 1
       AND a.name = 'Journée plage à Paje'
       AND a.data_status = 'UNVERIFIED'
       AND a.last_verified_at IS NULL
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'DESTINATION_GENERAL'
       AND a.source_url = 'https://www.bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025021916491906.pdf';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one guarded Paje activity source update, got %. Transaction rolled back.', n;
    END IF;

    -- Stone Town heritage discovery: the UNESCO Urban Heritage Atlas is
    -- specifically about Stone Town and documents its historic urban fabric.
    UPDATE activities a
       SET source_name = 'UNESCO World Heritage Centre - Urban Heritage Atlas: Stone Town of Zanzibar',
           source_url = 'https://whc.unesco.org/en/urban-heritage-atlas/stone-town',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'L’Atlas du patrimoine urbain de l’UNESCO porte spécifiquement sur Stone Town et décrit son tissu urbain historique, ses rues étroites et ses bâtiments patrimoniaux. Il étaye le contexte patrimonial de la découverte, mais ne prouve pas qu’une visite organisée est actuellement proposée ni les conditions de guidage, d’accès, les horaires, les coûts ou la durée. La fiche reste UNVERIFIED.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 2
       AND a.name = 'Découverte du patrimoine de Stone Town'
       AND a.data_status = 'UNVERIFIED'
       AND a.last_verified_at IS NULL
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'DESTINATION_GENERAL'
       AND a.source_url = 'https://whc.unesco.org/document/218167';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one guarded Stone Town discovery source update, got %. Transaction rolled back.', n;
    END IF;

    -- Stone Town walking activity: same item-specific heritage atlas, with
    -- no claim that it validates a current guided-tour product.
    UPDATE activities a
       SET source_name = 'UNESCO World Heritage Centre - Urban Heritage Atlas: Stone Town of Zanzibar',
           source_url = 'https://whc.unesco.org/en/urban-heritage-atlas/stone-town',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'L’Atlas du patrimoine urbain de l’UNESCO porte spécifiquement sur Stone Town et décrit notamment son réseau de rues étroites, son paysage urbain et ses bâtiments historiques. Il constitue un contexte patrimonial pertinent pour une découverte à pied, mais ne prouve pas qu’une visite guidée est actuellement proposée ni ses conditions pratiques. La fiche reste UNVERIFIED.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 7
       AND a.name = 'Visite à pied du patrimoine de Stone Town'
       AND a.data_status = 'UNVERIFIED'
       AND a.last_verified_at IS NULL
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'DESTINATION_GENERAL'
       AND a.source_url = 'https://www.tanzaniatourism.go.tz/data/2025/08/CHAN-2024-Participant-Guidebook-1.pdf';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one guarded Stone Town walking source update, got %. Transaction rolled back.', n;
    END IF;

    -- Nungwi Beach: the same official High Commission page names Nungwi.
    UPDATE attractions a
       SET source_name = 'Tanzania High Commission in the United Kingdom - Zanzibar Tropical Paradise in Africa',
           source_url = 'https://www.uk.tzembassy.go.tz/news/view/zanzibar-tropical-paradise-in-africa',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'La page officielle de la High Commission de Tanzanie cite explicitement Nungwi parmi les plages connues de Zanzibar. Elle appuie l’identification de la plage, mais ne confirme ni les conditions actuelles d’accès, ni la sécurité, ni les services, ni les horaires, ni les coûts, ni la durée de visite. La fiche reste UNVERIFIED.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 14
       AND a.name = 'Nungwi Beach'
       AND a.data_status = 'UNVERIFIED'
       AND a.last_verified_at IS NULL
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'DESTINATION_GENERAL'
       AND a.source_url = 'https://www.bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025021916491906.pdf';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one guarded Nungwi Beach source update, got %. Transaction rolled back.', n;
    END IF;

    -- Paje Beach: the same official High Commission page names Paje.
    UPDATE attractions a
       SET source_name = 'Tanzania High Commission in the United Kingdom - Zanzibar Tropical Paradise in Africa',
           source_url = 'https://www.uk.tzembassy.go.tz/news/view/zanzibar-tropical-paradise-in-africa',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'La page officielle de la High Commission de Tanzanie cite explicitement Paje parmi les plages connues du sud-est de Zanzibar. Elle appuie l’identification de la plage, mais ne confirme ni les conditions actuelles d’accès, ni la sécurité, ni les services, ni les horaires, ni les coûts, ni la durée de visite. La fiche reste UNVERIFIED.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 15
       AND a.name = 'Paje Beach'
       AND a.data_status = 'UNVERIFIED'
       AND a.last_verified_at IS NULL
       AND a.source_type = 'OFFICIAL'
       AND a.source_scope = 'DESTINATION_GENERAL'
       AND a.source_url = 'https://www.bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025021916491906.pdf';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one guarded Paje Beach source update, got %. Transaction rolled back.', n;
    END IF;

    -- Nakupenda: reclassify the provider's own page as operator-primary,
    -- not generic/independent institutional evidence.
    UPDATE attractions a
       SET source_name = 'Sea Star Fish Zanzibar - Nakupenda Trip (operator description)',
           source_url = 'https://seastarfish.co.tz/nakupenda',
           source_type = 'OPERATOR_PRIMARY',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'Page publiée par le prestataire Sea Star Fish décrivant son excursion commercialisée vers un banc de sable appelé Nakupenda. Cette source primaire documente l’offre du prestataire uniquement; elle ne confirme pas indépendamment le toponyme officiel, la délimitation géographique, les coordonnées, l’autorisation du prestataire, l’accès, la disponibilité, les tarifs ou la durée réelle. La fiche reste UNVERIFIED.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 16
       AND a.name = 'Banc de sable au large de Stone Town (excursion dite Nakupenda)'
       AND a.data_status = 'UNVERIFIED'
       AND a.last_verified_at IS NULL
       AND a.source_type = 'GENERIC'
       AND a.source_scope = 'ITEM_SPECIFIC'
       AND a.source_url = 'https://seastarfish.co.tz/nakupenda';
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one guarded Nakupenda source reclassification, got %. Transaction rolled back.', n;
    END IF;
END $$;

COMMIT;

-- Post-run verification of the six updated records.
SELECT
    item_type,
    iso_code,
    city,
    id,
    name,
    source_name,
    source_url,
    source_type,
    source_scope,
    data_status,
    last_verified_at,
    latitude,
    longitude,
    estimated_duration_minutes
FROM (
    SELECT
        'ACTIVITY'::TEXT AS item_type,
        co.iso_code,
        c.name AS city,
        a.id,
        a.name,
        a.source_name,
        a.source_url,
        a.source_type,
        a.source_scope,
        a.data_status,
        a.last_verified_at,
        a.latitude,
        a.longitude,
        a.estimated_duration_minutes
    FROM activities a
    JOIN cities c ON c.id = a.city_id
    JOIN countries co ON co.id = c.country_id
    WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND a.id IN (1, 2, 7)

    UNION ALL

    SELECT
        'ATTRACTION'::TEXT,
        co.iso_code,
        c.name,
        a.id,
        a.name,
        a.source_name,
        a.source_url,
        a.source_type,
        a.source_scope,
        a.data_status,
        a.last_verified_at,
        a.latitude,
        a.longitude,
        a.estimated_duration_minutes
    FROM attractions a
    JOIN cities c ON c.id = a.city_id
    JOIN countries co ON co.id = c.country_id
    WHERE co.iso_code = 'TZ' AND c.name = 'Zanzibar' AND a.id IN (14, 15, 16)
) updated
ORDER BY item_type, id;

-- The spice-tour coordinate is intentionally not updated.
SELECT
    co.iso_code,
    c.name AS city,
    a.id,
    a.name,
    a.source_type,
    a.source_scope,
    a.data_status,
    a.latitude,
    a.longitude,
    a.estimated_duration_minutes
FROM activities a
JOIN cities c ON c.id = a.city_id
JOIN countries co ON co.id = c.country_id
WHERE co.iso_code = 'TZ'
  AND c.name = 'Zanzibar'
  AND a.id IN (8, 10)
ORDER BY a.id;
