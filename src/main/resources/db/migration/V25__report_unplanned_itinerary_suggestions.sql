-- V25: retain a durable count of catalog suggestions omitted by itinerary capacity/geographic constraints.
ALTER TABLE itineraries
    ADD COLUMN unplanned_item_count INTEGER NOT NULL DEFAULT 0
        CHECK (unplanned_item_count >= 0);

COMMENT ON COLUMN itineraries.unplanned_item_count IS
    'Number of active non-rejected catalog suggestions not placed in the generated itinerary; does not delete catalog entries.';
