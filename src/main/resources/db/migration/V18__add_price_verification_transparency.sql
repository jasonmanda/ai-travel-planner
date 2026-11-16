-- V18: preserve the exact price and currency checked during catalog verification.
-- Historical events are not retroactively considered price verifications.

ALTER TABLE attraction_verification_history
    ADD COLUMN verified_price NUMERIC(12,2),
    ADD COLUMN verified_currency VARCHAR(3);

ALTER TABLE activity_verification_history
    ADD COLUMN verified_price NUMERIC(12,2),
    ADD COLUMN verified_currency VARCHAR(3);

ALTER TABLE attraction_verification_history
    ADD CONSTRAINT ck_attraction_verified_price_snapshot
    CHECK (
        (verified_price IS NULL AND verified_currency IS NULL)
        OR
        (verified_price IS NOT NULL AND verified_currency IS NOT NULL)
    );

ALTER TABLE activity_verification_history
    ADD CONSTRAINT ck_activity_verified_price_snapshot
    CHECK (
        (verified_price IS NULL AND verified_currency IS NULL)
        OR
        (verified_price IS NOT NULL AND verified_currency IS NOT NULL)
    );

-- Preserve price transparency in itinerary snapshots.
ALTER TABLE itinerary_items
    ADD COLUMN price_verification_status VARCHAR(20) NOT NULL DEFAULT 'NOT_AVAILABLE',
    ADD COLUMN price_verified_at TIMESTAMPTZ,
    ADD COLUMN price_verification_source_name VARCHAR(180),
    ADD COLUMN price_verification_source_url VARCHAR(1000);

-- Existing itinerary prices have no reliable price-verification snapshot.
UPDATE itinerary_items
SET price_verification_status = CASE
    WHEN estimated_cost IS NULL THEN 'NOT_AVAILABLE'
    ELSE 'ESTIMATED'
END;

ALTER TABLE itinerary_items
    ADD CONSTRAINT ck_itinerary_item_price_verification_status
    CHECK (price_verification_status IN (
        'VERIFIED', 'ESTIMATED', 'NOT_AVAILABLE'
    ));

ALTER TABLE itinerary_items
    ADD CONSTRAINT ck_itinerary_item_price_verification_metadata
    CHECK (
        price_verification_status <> 'VERIFIED'
        OR (
            estimated_cost IS NOT NULL
            AND currency_code IS NOT NULL
            AND price_verified_at IS NOT NULL
            AND price_verification_source_name IS NOT NULL
            AND price_verification_source_url IS NOT NULL
        )
    );

COMMENT ON COLUMN attraction_verification_history.verified_price IS
    'Exact attraction price checked during this verification event.';
COMMENT ON COLUMN attraction_verification_history.verified_currency IS
    'Currency checked alongside the attraction price.';
COMMENT ON COLUMN activity_verification_history.verified_price IS
    'Exact activity price checked during this verification event.';
COMMENT ON COLUMN activity_verification_history.verified_currency IS
    'Currency checked alongside the activity price.';
COMMENT ON COLUMN itinerary_items.price_verification_status IS
    'Price-specific status, independent from the catalog item verification status.';
