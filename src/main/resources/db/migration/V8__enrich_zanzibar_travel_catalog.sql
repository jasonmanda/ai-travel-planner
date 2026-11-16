-- V5 catalog enrichment: additional Zanzibar attractions and activities.
-- All entries are discovery suggestions only. No coordinates, prices, durations or opening hours
-- are asserted without a dedicated verified source. Existing catalog rows are never overwritten.
--
-- Sources:
-- UNESCO Stone Town Urban Heritage Atlas:
-- https://whc.unesco.org/en/urban-heritage-atlas/stone-town
-- Official Zanzibar tourism portal:
-- https://visitzanzibar.go.tz/

INSERT INTO attractions (
    city_id, name, category, description, latitude, longitude,
    data_status, source_name, source_url, last_verified_at, active
)
SELECT c.id, x.name, x.category, x.description, NULL, NULL,
       'UNVERIFIED', x.source_name, x.source_url, NULL, TRUE
FROM cities c
JOIN countries co ON co.id = c.country_id
CROSS JOIN (VALUES
    (
        'Old Dispensary',
        'HERITAGE',
        'Bâtiment historique de Stone Town mentionné dans l’inventaire patrimonial de l’UNESCO. Conditions de visite à confirmer.',
        'UNESCO Urban Heritage Atlas',
        'https://whc.unesco.org/en/urban-heritage-atlas/stone-town'
    ),
    (
        'Christ Church Anglican Cathedral',
        'HERITAGE',
        'Cathédrale anglicane située sur le site de l’ancien marché aux esclaves. Horaires et modalités de visite à confirmer.',
        'UNESCO Urban Heritage Atlas',
        'https://whc.unesco.org/en/urban-heritage-atlas/stone-town'
    ),
    (
        'Hamamni Persian Baths',
        'HERITAGE',
        'Bains persans historiques de Stone Town. Accès actuel et conditions de visite à confirmer.',
        'UNESCO Urban Heritage Atlas',
        'https://whc.unesco.org/en/urban-heritage-atlas/stone-town'
    ),
    (
        'Palace Museum (Beit al-Sahel)',
        'MUSEUM',
        'Ancien palais historique de Stone Town. Statut du musée, horaires et accès à vérifier avant toute visite.',
        'UNESCO Urban Heritage Atlas',
        'https://whc.unesco.org/en/urban-heritage-atlas/stone-town'
    ),
    (
        'Jozani Forest',
        'NATURE',
        'Forêt naturelle de Zanzibar présentée parmi les expériences touristiques de l’archipel. Accès, règles de visite et tarifs à vérifier.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    ),
    (
        'Prison Island (Changuu)',
        'ISLAND',
        'Excursion insulaire proposée dans l’offre touristique de Zanzibar. Transport maritime, droits d’accès et conditions à vérifier.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    ),
    (
        'Nungwi Beach',
        'BEACH',
        'Plage du nord de Zanzibar. Conditions de baignade, marées, accès et services locaux à vérifier.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    ),
    (
        'Paje Beach',
        'BEACH',
        'Plage de la côte est de Zanzibar. Conditions de baignade, marées, accès et activités nautiques à vérifier.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    ),
    (
        'Nakupenda Sandbank',
        'NATURAL_SITE',
        'Banc de sable marin proposé parmi les excursions de Zanzibar. Présence et accessibilité dépendantes des marées et de la météo.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    )
) AS x(name, category, description, source_name, source_url)
WHERE c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
ON CONFLICT (city_id, name) DO NOTHING;

INSERT INTO activities (
    city_id, name, category, description, estimated_duration_minutes,
    estimated_cost, cost_currency, suitable_for_families, min_age_years,
    data_status, source_name, source_url, last_verified_at, active
)
SELECT c.id, x.name, x.category, x.description, NULL, NULL, NULL,
       NULL, NULL, 'UNVERIFIED', x.source_name, x.source_url, NULL, TRUE
FROM cities c
JOIN countries co ON co.id = c.country_id
CROSS JOIN (VALUES
    (
        'Visite guidée du patrimoine de Stone Town',
        'CULTURE',
        'Idée de visite culturelle à organiser avec un guide local. Prestataire, durée, prix et disponibilité à confirmer.',
        'UNESCO Urban Heritage Atlas',
        'https://whc.unesco.org/en/urban-heritage-atlas/stone-town'
    ),
    (
        'Découverte d’une ferme aux épices',
        'CULTURE',
        'Expérience autour des épices proposée dans l’offre touristique de Zanzibar. Ferme, transport, durée et prix à confirmer.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    ),
    (
        'Excursion dans la forêt de Jozani',
        'NATURE',
        'Suggestion de découverte de la forêt de Jozani. Accès, accompagnement, durée et frais éventuels à confirmer.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    ),
    (
        'Excursion en bateau vers un banc de sable',
        'BOAT_TRIP',
        'Suggestion d’excursion maritime. Opérateur, itinéraire, durée, prix, marées et conditions de sécurité à vérifier.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    ),
    (
        'Découverte du marché nocturne de Forodhani',
        'FOOD',
        'Suggestion de découverte de la cuisine de rue locale. Jours, horaires, vendeurs et prix à vérifier sur place.',
        'Visit Zanzibar - official tourism portal',
        'https://visitzanzibar.go.tz/'
    )
) AS x(name, category, description, source_name, source_url)
WHERE c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
ON CONFLICT (city_id, name) DO NOTHING;
