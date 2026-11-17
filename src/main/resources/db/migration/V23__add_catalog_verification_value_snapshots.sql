-- V23: preserve the exact catalog field values captured during each verification.
-- Legacy events remain NULL: their historical values cannot be reconstructed safely.
-- New verification events must populate this snapshot from the locked catalog row.

ALTER TABLE attraction_verification_history
    ADD COLUMN verified_values JSONB;

ALTER TABLE activity_verification_history
    ADD COLUMN verified_values JSONB;

ALTER TABLE attraction_verification_history
    ADD CONSTRAINT ck_attraction_verified_values_object
        CHECK (verified_values IS NULL OR (
            jsonb_typeof(verified_values) = 'object'
            AND verified_values <> '{}'::jsonb
        ));

ALTER TABLE activity_verification_history
    ADD CONSTRAINT ck_activity_verified_values_object
        CHECK (verified_values IS NULL OR (
            jsonb_typeof(verified_values) = 'object'
            AND verified_values <> '{}'::jsonb
        ));

COMMENT ON COLUMN attraction_verification_history.verified_values IS
    'Snapshot JSONB des valeurs exactes lues dans attractions au moment du contrôle. NULL uniquement pour les événements historiques antérieurs à V23.';

COMMENT ON COLUMN activity_verification_history.verified_values IS
    'Snapshot JSONB des valeurs exactes lues dans activities au moment du contrôle. NULL uniquement pour les événements historiques antérieurs à V23.';
