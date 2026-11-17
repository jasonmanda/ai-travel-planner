-- V19: enforce price verification snapshot and itinerary metadata integrity.
-- Existing history events and itinerary snapshots are preserved.

-- An attraction price snapshot exists if and only if the event verifies
-- both the price and its currency as VERIFIED.
ALTER TABLE attraction_verification_history
    ADD CONSTRAINT ck_attraction_verified_price_nonnegative
        CHECK (verified_price IS NULL OR verified_price >= 0),
    ADD CONSTRAINT ck_attraction_verified_currency_format
        CHECK (verified_currency IS NULL OR verified_currency ~ '^[A-Z]{3}$'),
    ADD CONSTRAINT ck_attraction_verified_price_consistency
        CHECK (
            (
                verification_status = 'VERIFIED'
                AND verified_fields @> ARRAY[
                    'estimated_visit_cost',
                    'cost_currency'
                ]::text[]
            ) = (
                verified_price IS NOT NULL
                AND verified_currency IS NOT NULL
            )
        );

-- An activity price snapshot follows the same rule.
ALTER TABLE activity_verification_history
    ADD CONSTRAINT ck_activity_verified_price_nonnegative
        CHECK (verified_price IS NULL OR verified_price >= 0),
    ADD CONSTRAINT ck_activity_verified_currency_format
        CHECK (verified_currency IS NULL OR verified_currency ~ '^[A-Z]{3}$'),
    ADD CONSTRAINT ck_activity_verified_price_consistency
        CHECK (
            (
                verification_status = 'VERIFIED'
                AND verified_fields @> ARRAY[
                    'estimated_cost',
                    'cost_currency'
                ]::text[]
            ) = (
                verified_price IS NOT NULL
                AND verified_currency IS NOT NULL
            )
        );

-- A VERIFIED itinerary price requires complete, nonblank source metadata.
-- Keep the existing non-VERIFIED status behavior unchanged.
ALTER TABLE itinerary_items
    DROP CONSTRAINT ck_itinerary_item_price_verification_metadata,
    ADD CONSTRAINT ck_itinerary_item_price_verification_metadata
        CHECK (
            price_verification_status <> 'VERIFIED'
            OR (
                estimated_cost IS NOT NULL
                AND estimated_cost >= 0
                AND currency_code IS NOT NULL
                AND currency_code ~ '^[A-Z]{3}$'
                AND price_verified_at IS NOT NULL
                AND price_verification_source_name IS NOT NULL
                AND BTRIM(price_verification_source_name) <> ''
                AND price_verification_source_url IS NOT NULL
                AND price_verification_source_url ~* '^https?://[^[:space:]]+$'
            )
        );

COMMENT ON CONSTRAINT ck_attraction_verified_price_consistency
    ON attraction_verification_history IS
    'A price snapshot is required exactly when a VERIFIED event verifies both estimated_visit_cost and cost_currency.';
COMMENT ON CONSTRAINT ck_activity_verified_price_consistency
    ON activity_verification_history IS
    'A price snapshot is required exactly when a VERIFIED event verifies both estimated_cost and cost_currency.';
COMMENT ON CONSTRAINT ck_itinerary_item_price_verification_metadata
    ON itinerary_items IS
    'VERIFIED itinerary prices require a nonnegative amount, uppercase three-letter currency syntax, verification date, and nonblank HTTP(S) source metadata.';
