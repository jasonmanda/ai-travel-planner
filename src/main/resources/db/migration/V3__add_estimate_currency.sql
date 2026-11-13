-- Explicitly records the currency used by each destination's daily-budget estimate.
-- Existing demo estimates are expressed in XOF; update this value when importing verified local-currency data.
ALTER TABLE cities
    ADD COLUMN estimated_daily_budget_currency VARCHAR(3) NOT NULL DEFAULT 'XOF';
