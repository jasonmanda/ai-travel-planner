CREATE TABLE itineraries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trip_requests(id) ON DELETE CASCADE,
    city_id BIGINT NOT NULL REFERENCES cities(id),
    title VARCHAR(200) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'GENERATED',
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_itinerary_trip_city UNIQUE (trip_id, city_id)
);

CREATE INDEX idx_itineraries_trip ON itineraries(trip_id);

CREATE TABLE itinerary_days (
    id BIGSERIAL PRIMARY KEY,
    itinerary_id UUID NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL CHECK (day_number BETWEEN 1 AND 90),
    title VARCHAR(160) NOT NULL,
    summary VARCHAR(1000),
    CONSTRAINT uk_itinerary_day UNIQUE (itinerary_id, day_number)
);

CREATE TABLE itinerary_items (
    id BIGSERIAL PRIMARY KEY,
    day_id BIGINT NOT NULL REFERENCES itinerary_days(id) ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL CHECK (sequence_number > 0),
    item_type VARCHAR(30) NOT NULL,
    catalog_item_id BIGINT,
    title VARCHAR(180) NOT NULL,
    description VARCHAR(1200),
    estimated_duration_minutes INTEGER,
    estimated_cost NUMERIC(12,2),
    currency_code VARCHAR(3),
    data_status VARCHAR(30) NOT NULL DEFAULT 'UNVERIFIED',
    source_name VARCHAR(180),
    source_url VARCHAR(1000),
    CONSTRAINT ck_itinerary_item_duration CHECK (estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0),
    CONSTRAINT ck_itinerary_item_cost CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
    CONSTRAINT uk_itinerary_item_sequence UNIQUE (day_id, sequence_number)
);

CREATE INDEX idx_itinerary_days_itinerary ON itinerary_days(itinerary_id, day_number);
CREATE INDEX idx_itinerary_items_day ON itinerary_items(day_id, sequence_number);
