-- Travel Catalog V2: structured tourism data. All imported/demo content is explicitly unverified.
CREATE TABLE attractions (
    id BIGSERIAL PRIMARY KEY,
    city_id BIGINT NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(60) NOT NULL,
    description VARCHAR(1200),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    estimated_visit_cost NUMERIC(12,2),
    cost_currency VARCHAR(3),
    estimated_duration_minutes INTEGER,
    data_status VARCHAR(30) NOT NULL DEFAULT 'UNVERIFIED',
    source_name VARCHAR(180),
    source_url VARCHAR(1000),
    last_verified_at TIMESTAMPTZ,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_attraction_cost CHECK (estimated_visit_cost IS NULL OR estimated_visit_cost >= 0),
    CONSTRAINT ck_attraction_duration CHECK (estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0),
    CONSTRAINT ck_attraction_lat CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_attraction_lon CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT uk_attraction_city_name UNIQUE(city_id, name)
);
CREATE INDEX idx_attractions_city ON attractions(city_id, active);

CREATE TABLE activities (
    id BIGSERIAL PRIMARY KEY,
    city_id BIGINT NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(60) NOT NULL,
    description VARCHAR(1200),
    estimated_duration_minutes INTEGER,
    estimated_cost NUMERIC(12,2),
    cost_currency VARCHAR(3),
    suitable_for_families BOOLEAN,
    min_age_years INTEGER,
    data_status VARCHAR(30) NOT NULL DEFAULT 'UNVERIFIED',
    source_name VARCHAR(180),
    source_url VARCHAR(1000),
    last_verified_at TIMESTAMPTZ,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_activity_cost CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
    CONSTRAINT ck_activity_duration CHECK (estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0),
    CONSTRAINT ck_activity_min_age CHECK (min_age_years IS NULL OR min_age_years >= 0),
    CONSTRAINT uk_activity_city_name UNIQUE(city_id, name)
);
CREATE INDEX idx_activities_city ON activities(city_id, active);
CREATE INDEX idx_activities_category ON activities(category);

CREATE TABLE city_budget_components (
    id BIGSERIAL PRIMARY KEY,
    city_id BIGINT NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    component_key VARCHAR(40) NOT NULL,
    label VARCHAR(100) NOT NULL,
    estimated_amount NUMERIC(12,2),
    currency_code VARCHAR(3),
    pricing_basis VARCHAR(40) NOT NULL,
    data_status VARCHAR(30) NOT NULL DEFAULT 'NOT_AVAILABLE',
    source_name VARCHAR(180),
    source_url VARCHAR(1000),
    last_verified_at TIMESTAMPTZ,
    CONSTRAINT uk_city_budget_component UNIQUE(city_id, component_key),
    CONSTRAINT ck_budget_component_amount CHECK (estimated_amount IS NULL OR estimated_amount >= 0)
);

CREATE TABLE city_seasons (
    id BIGSERIAL PRIMARY KEY,
    city_id BIGINT NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    month_number SMALLINT NOT NULL CHECK (month_number BETWEEN 1 AND 12),
    season_type VARCHAR(40) NOT NULL,
    summary VARCHAR(1000),
    data_status VARCHAR(30) NOT NULL DEFAULT 'UNVERIFIED',
    source_name VARCHAR(180),
    source_url VARCHAR(1000),
    last_verified_at TIMESTAMPTZ,
    CONSTRAINT uk_city_season_month UNIQUE(city_id, month_number)
);

-- Seed only neutral catalog structure. No fabricated prices, coordinates, opening hours or season claims.
INSERT INTO city_budget_components(city_id, component_key, label, pricing_basis, data_status)
SELECT c.id, x.component_key, x.label, 'PER_PERSON_PER_DAY', 'NOT_AVAILABLE'
FROM cities c
CROSS JOIN (VALUES
    ('accommodation', 'Hébergement'),
    ('meals', 'Repas'),
    ('local_transport', 'Transport local'),
    ('activities', 'Activités'),
    ('miscellaneous', 'Divers')
) AS x(component_key, label)
ON CONFLICT (city_id, component_key) DO NOTHING;

-- Illustrative catalog entries only: names/categories are starter content, not verified travel guidance.
INSERT INTO attractions(city_id, name, category, description, data_status, source_name)
SELECT c.id, x.name, x.category, x.description, 'UNVERIFIED', 'Starter catalog - verification required'
FROM cities c
JOIN countries co ON co.id = c.country_id
JOIN (VALUES
    ('Zanzibar', 'TZ', 'Stone Town', 'HERITAGE', 'Quartier historique de Zanzibar. Informations pratiques et conditions de visite à vérifier.'),
    ('Zanzibar', 'TZ', 'Forodhani Gardens', 'PUBLIC_SPACE', 'Espace public du front de mer à Stone Town. Horaires et conditions d’accès à vérifier.'),
    ('Marrakech', 'MA', 'Jemaa el-Fna', 'CULTURE', 'Place emblématique de Marrakech. Activités, horaires et conditions de visite à vérifier.'),
    ('Marrakech', 'MA', 'Jardin Majorelle', 'GARDEN', 'Jardin botanique et site culturel. Tarifs et modalités de réservation à vérifier.'),
    ('Le Cap', 'ZA', 'Table Mountain', 'NATURE', 'Site naturel majeur du Cap. Accès, météo et tarifs à vérifier.'),
    ('Le Cap', 'ZA', 'V&A Waterfront', 'WATERFRONT', 'Zone portuaire et commerciale du Cap. Horaires et activités à vérifier.')
) AS x(city_name, iso_code, name, category, description) ON c.name = x.city_name AND co.iso_code = x.iso_code
ON CONFLICT (city_id, name) DO NOTHING;

INSERT INTO activities(city_id, name, category, description, data_status, source_name)
SELECT c.id, x.name, x.category, x.description, 'UNVERIFIED', 'Starter catalog - verification required'
FROM cities c
JOIN countries co ON co.id = c.country_id
JOIN (VALUES
    ('Zanzibar', 'TZ', 'Découverte du patrimoine de Stone Town', 'CULTURE', 'Activité suggérée à titre indicatif; opérateur, durée, prix et disponibilité à vérifier.'),
    ('Zanzibar', 'TZ', 'Journée plage et baignade', 'BEACH', 'Activité suggérée à titre indicatif; conditions de mer, sécurité et accès à vérifier.'),
    ('Marrakech', 'MA', 'Découverte des souks et de la médina', 'CULTURE', 'Activité suggérée à titre indicatif; guide, durée, prix et conditions à vérifier.'),
    ('Marrakech', 'MA', 'Visite de jardin', 'NATURE', 'Activité suggérée à titre indicatif; horaires et tarifs à vérifier.'),
    ('Le Cap', 'ZA', 'Découverte du front de mer', 'CITY', 'Activité suggérée à titre indicatif; horaires et coûts à vérifier.'),
    ('Le Cap', 'ZA', 'Randonnée en milieu naturel', 'ADVENTURE', 'Activité suggérée à titre indicatif; météo, sécurité, accès et niveau requis à vérifier.')
) AS x(city_name, iso_code, name, category, description) ON c.name = x.city_name AND co.iso_code = x.iso_code
ON CONFLICT (city_id, name) DO NOTHING;
