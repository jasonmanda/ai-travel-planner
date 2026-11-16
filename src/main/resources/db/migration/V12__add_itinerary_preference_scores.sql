ALTER TABLE itinerary_items
    ADD COLUMN preference_score SMALLINT NOT NULL DEFAULT 70,
    ADD COLUMN preference_reason VARCHAR(500) NOT NULL
        DEFAULT 'Aucune préférence renseignée : classement neutre.';

ALTER TABLE itinerary_items
    ADD CONSTRAINT ck_itinerary_item_preference_score
        CHECK (preference_score BETWEEN 0 AND 100);
