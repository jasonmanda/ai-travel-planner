-- V15: auditable factual verification history for attractions and activities.
-- A source classification (V13/V14) is documentary metadata and never creates a verification event.
-- This migration does not promote any existing catalog item to VERIFIED.

CREATE TABLE attraction_verification_history (
    id BIGSERIAL PRIMARY KEY,
    attraction_id BIGINT NOT NULL REFERENCES attractions(id) ON DELETE CASCADE,
    verification_status VARCHAR(24) NOT NULL,
    verified_fields TEXT[] NOT NULL,
    source_name VARCHAR(180) NOT NULL,
    source_url VARCHAR(1000) NOT NULL,
    verification_notes VARCHAR(1200) NOT NULL,
    verified_by VARCHAR(180) NOT NULL,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_attraction_verification_status
        CHECK (verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED', 'REJECTED')),
    CONSTRAINT ck_attraction_verified_fields
        CHECK (
            cardinality(verified_fields) > 0
            AND verified_fields <@ ARRAY[
                'name', 'category', 'description', 'latitude', 'longitude',
                'estimated_visit_cost', 'cost_currency', 'estimated_duration_minutes'
            ]::TEXT[]
        ),
    CONSTRAINT ck_attraction_verification_source_url
        CHECK (source_url ~* '^https?://[^[:space:]]+$'),
    CONSTRAINT ck_attraction_verification_source_name
        CHECK (length(btrim(source_name)) > 0),
    CONSTRAINT ck_attraction_verification_notes
        CHECK (length(btrim(verification_notes)) > 0),
    CONSTRAINT ck_attraction_verified_by
        CHECK (length(btrim(verified_by)) > 0)
);

CREATE TABLE activity_verification_history (
    id BIGSERIAL PRIMARY KEY,
    activity_id BIGINT NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    verification_status VARCHAR(24) NOT NULL,
    verified_fields TEXT[] NOT NULL,
    source_name VARCHAR(180) NOT NULL,
    source_url VARCHAR(1000) NOT NULL,
    verification_notes VARCHAR(1200) NOT NULL,
    verified_by VARCHAR(180) NOT NULL,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_activity_verification_status
        CHECK (verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED', 'REJECTED')),
    CONSTRAINT ck_activity_verified_fields
        CHECK (
            cardinality(verified_fields) > 0
            AND verified_fields <@ ARRAY[
                'name', 'category', 'description', 'latitude', 'longitude',
                'estimated_cost', 'cost_currency', 'estimated_duration_minutes',
                'suitable_for_families', 'min_age_years'
            ]::TEXT[]
        ),
    CONSTRAINT ck_activity_verification_source_url
        CHECK (source_url ~* '^https?://[^[:space:]]+$'),
    CONSTRAINT ck_activity_verification_source_name
        CHECK (length(btrim(source_name)) > 0),
    CONSTRAINT ck_activity_verification_notes
        CHECK (length(btrim(verification_notes)) > 0),
    CONSTRAINT ck_activity_verified_by
        CHECK (length(btrim(verified_by)) > 0)
);

CREATE INDEX idx_attraction_verification_history_item_date
    ON attraction_verification_history(attraction_id, verified_at DESC);

CREATE INDEX idx_activity_verification_history_item_date
    ON activity_verification_history(activity_id, verified_at DESC);

COMMENT ON TABLE attraction_verification_history IS
    'Historique append-only des contrôles factuels des attractions. Une classification de source ne crée jamais de validation.';
COMMENT ON TABLE activity_verification_history IS
    'Historique append-only des contrôles factuels des activités. Une classification de source ne crée jamais de validation.';
COMMENT ON COLUMN attraction_verification_history.verified_fields IS
    'Liste explicite des champs effectivement contrôlés lors de cette vérification.';
COMMENT ON COLUMN activity_verification_history.verified_fields IS
    'Liste explicite des champs effectivement contrôlés lors de cette vérification.';
