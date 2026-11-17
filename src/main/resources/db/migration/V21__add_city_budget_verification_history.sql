-- V21: append-only audit trail for city daily-budget verification.
-- Existing city estimates are not promoted by this migration.

CREATE TABLE city_budget_verification_history (
    id BIGSERIAL PRIMARY KEY,
    city_id BIGINT NOT NULL REFERENCES cities(id) ON DELETE RESTRICT,
    verified_daily_budget NUMERIC(12,2) NOT NULL,
    verified_currency VARCHAR(3) NOT NULL,
    source_name VARCHAR(180) NOT NULL,
    source_url VARCHAR(1000) NOT NULL,
    verification_notes VARCHAR(1000) NOT NULL,
    verified_by VARCHAR(180) NOT NULL,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_city_budget_history_amount
        CHECK (verified_daily_budget >= 0),
    CONSTRAINT ck_city_budget_history_currency
        CHECK (verified_currency ~ '^[A-Z]{3}$'),
    CONSTRAINT ck_city_budget_history_source_name
        CHECK (length(btrim(source_name)) > 0),
    CONSTRAINT ck_city_budget_history_source_url
        CHECK (source_url ~* '^https?://[^[:space:]]+$'),
    CONSTRAINT ck_city_budget_history_notes
        CHECK (length(btrim(verification_notes)) > 0),
    CONSTRAINT ck_city_budget_history_verified_by
        CHECK (length(btrim(verified_by)) > 0)
);

CREATE INDEX idx_city_budget_verification_history_city_date
    ON city_budget_verification_history(city_id, verified_at DESC);

CREATE FUNCTION prevent_city_budget_verification_history_mutation() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'City budget verification history is append-only; insert a new event instead';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_city_budget_verification_history_immutable
BEFORE UPDATE OR DELETE ON city_budget_verification_history
FOR EACH ROW EXECUTE FUNCTION prevent_city_budget_verification_history_mutation();

COMMENT ON TABLE city_budget_verification_history IS
    'Historique append-only des vérifications de budgets journaliers des villes. Les valeurs sont conservées en instantané.';
COMMENT ON COLUMN city_budget_verification_history.verified_daily_budget IS
    'Montant journalier exact contrôlé lors de cet événement.';
COMMENT ON COLUMN city_budget_verification_history.verified_currency IS
    'Devise du montant journalier contrôlé lors de cet événement.';
