-- Add optional coordinates to activities and persist coordinates on generated itinerary items.
-- Coordinates remain nullable: the planner never invents missing locations.
ALTER TABLE activities
    ADD COLUMN latitude DOUBLE PRECISION,
    ADD COLUMN longitude DOUBLE PRECISION;

ALTER TABLE activities
    ADD CONSTRAINT ck_activity_lat CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    ADD CONSTRAINT ck_activity_lon CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180);

ALTER TABLE itinerary_items
    ADD COLUMN latitude DOUBLE PRECISION,
    ADD COLUMN longitude DOUBLE PRECISION;

ALTER TABLE itinerary_items
    ADD CONSTRAINT ck_itinerary_item_lat CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    ADD CONSTRAINT ck_itinerary_item_lon CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180);
