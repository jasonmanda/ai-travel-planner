-- V20: make city daily-budget estimates explicitly traceable.
-- Existing demo values are retained and classified as INDICATIVE; no historical
-- estimate is promoted to VERIFIED by this migration.

ALTER TABLE cities
    ADD COLUMN estimated_daily_budget_status VARCHAR(20) NOT NULL DEFAULT 'INDICATIVE',
    ADD COLUMN estimated_daily_budget_source_name VARCHAR(180),
    ADD COLUMN estimated_daily_budget_source_url VARCHAR(1000),
    ADD COLUMN estimated_daily_budget_verified_at TIMESTAMPTZ,
    ADD COLUMN estimated_daily_budget_notes VARCHAR(1000);

-- Recommendations may legitimately have no numeric estimate when a city budget is UNKNOWN.
ALTER TABLE trip_recommendations
    ALTER COLUMN estimated_trip_budget DROP NOT NULL;

-- UNKNOWN means that no numeric estimate/currency is available.
ALTER TABLE cities
    ALTER COLUMN estimated_daily_budget DROP NOT NULL,
    ALTER COLUMN estimated_daily_budget_currency DROP NOT NULL;

ALTER TABLE cities
    ADD CONSTRAINT ck_city_daily_budget_status
        CHECK (estimated_daily_budget_status IN ('VERIFIED', 'INDICATIVE', 'UNKNOWN')),
    ADD CONSTRAINT ck_city_daily_budget_amount
        CHECK (estimated_daily_budget IS NULL OR estimated_daily_budget >= 0),
    ADD CONSTRAINT ck_city_daily_budget_currency_format
        CHECK (
            estimated_daily_budget_currency IS NULL
            OR estimated_daily_budget_currency ~ '^[A-Z]{3}$'
        ),
    ADD CONSTRAINT ck_city_daily_budget_status_metadata
        CHECK (
            (
                estimated_daily_budget_status = 'UNKNOWN'
                AND estimated_daily_budget IS NULL
                AND estimated_daily_budget_currency IS NULL
            )
            OR (
                estimated_daily_budget_status = 'INDICATIVE'
                AND estimated_daily_budget IS NOT NULL
                AND estimated_daily_budget_currency IS NOT NULL
                AND estimated_daily_budget_verified_at IS NULL
            )
            OR (
                estimated_daily_budget_status = 'VERIFIED'
                AND estimated_daily_budget IS NOT NULL
                AND estimated_daily_budget_currency IS NOT NULL
                AND estimated_daily_budget_verified_at IS NOT NULL
                AND estimated_daily_budget_source_name IS NOT NULL
                AND BTRIM(estimated_daily_budget_source_name) <> ''
                AND estimated_daily_budget_source_url IS NOT NULL
                AND estimated_daily_budget_source_url ~* '^https?://[^[:space:]]+$'
            )
        );

COMMENT ON COLUMN cities.estimated_daily_budget_status IS
    'Trust status of the daily budget: VERIFIED, INDICATIVE, or UNKNOWN.';
COMMENT ON COLUMN cities.estimated_daily_budget_source_name IS
    'Human-readable source used to verify or contextualize the daily budget.';
COMMENT ON COLUMN cities.estimated_daily_budget_source_url IS
    'HTTP(S) URL supporting the daily budget source.';
COMMENT ON COLUMN cities.estimated_daily_budget_verified_at IS
    'Timestamp when the daily budget amount and currency were verified.';
COMMENT ON COLUMN cities.estimated_daily_budget_notes IS
    'Scope, assumptions, inclusions, exclusions, and limitations of the daily-budget estimate.';
