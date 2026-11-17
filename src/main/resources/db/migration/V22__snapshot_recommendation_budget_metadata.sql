-- V22: preserve the exact city budget metadata used when each recommendation is generated.
-- Existing recommendations keep NULL snapshot metadata because their historical source state
-- cannot be reconstructed reliably from the current city catalog.

ALTER TABLE trip_recommendations
    ADD COLUMN budget_estimate_status VARCHAR(20),
    ADD COLUMN budget_currency VARCHAR(3),
    ADD COLUMN budget_source_name VARCHAR(180),
    ADD COLUMN budget_source_url VARCHAR(1000),
    ADD COLUMN budget_verified_at TIMESTAMPTZ,
    ADD COLUMN budget_estimate_notes VARCHAR(1000);

ALTER TABLE trip_recommendations
    ADD CONSTRAINT ck_recommendation_budget_estimate_status
        CHECK (
            budget_estimate_status IS NULL
            OR budget_estimate_status IN ('VERIFIED', 'INDICATIVE', 'UNKNOWN')
        ),
    ADD CONSTRAINT ck_recommendation_budget_currency
        CHECK (
            budget_currency IS NULL
            OR budget_currency ~ '^[A-Z]{3}$'
        ),
    ADD CONSTRAINT ck_recommendation_budget_snapshot
        CHECK (
            budget_estimate_status IS NULL
            OR (
                budget_estimate_status = 'UNKNOWN'
                AND estimated_trip_budget IS NULL
                AND budget_currency IS NULL
            )
            OR (
                budget_estimate_status = 'INDICATIVE'
                AND estimated_trip_budget IS NOT NULL
                AND budget_currency IS NOT NULL
                AND budget_verified_at IS NULL
            )
            OR (
                budget_estimate_status = 'VERIFIED'
                AND estimated_trip_budget IS NOT NULL
                AND budget_currency IS NOT NULL
                AND budget_verified_at IS NOT NULL
                AND budget_source_name IS NOT NULL
                AND BTRIM(budget_source_name) <> ''
                AND budget_source_url IS NOT NULL
                AND budget_source_url ~* '^https?://[^[:space:]]+$'
            )
        );

COMMENT ON COLUMN trip_recommendations.budget_estimate_status IS
    'Budget trust status captured at recommendation generation time; NULL denotes a legacy row without a reliable snapshot.';
COMMENT ON COLUMN trip_recommendations.budget_currency IS
    'Currency captured with the recommendation budget estimate, independent of later city catalog changes.';
COMMENT ON COLUMN trip_recommendations.budget_source_name IS
    'Source name captured when the recommendation was generated.';
COMMENT ON COLUMN trip_recommendations.budget_source_url IS
    'Source URL captured when the recommendation was generated.';
COMMENT ON COLUMN trip_recommendations.budget_verified_at IS
    'Verification timestamp captured when the recommendation was generated.';
COMMENT ON COLUMN trip_recommendations.budget_estimate_notes IS
    'Budget scope and limitations captured when the recommendation was generated.';
