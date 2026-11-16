-- V16: preserve verification audit events when catalog records are removed.
-- The history tables are append-only, so cascading deletes would invoke their
-- immutability triggers and fail with a misleading trigger exception.
-- RESTRICT makes the retention rule explicit: a catalog item with audit history
-- cannot be deleted. Archive/deactivation should be used instead.

ALTER TABLE attraction_verification_history
    DROP CONSTRAINT attraction_verification_history_attraction_id_fkey;

ALTER TABLE attraction_verification_history
    ADD CONSTRAINT fk_attraction_verification_history_attraction
    FOREIGN KEY (attraction_id)
    REFERENCES attractions(id)
    ON DELETE RESTRICT;

ALTER TABLE activity_verification_history
    DROP CONSTRAINT activity_verification_history_activity_id_fkey;

ALTER TABLE activity_verification_history
    ADD CONSTRAINT fk_activity_verification_history_activity
    FOREIGN KEY (activity_id)
    REFERENCES activities(id)
    ON DELETE RESTRICT;

COMMENT ON CONSTRAINT fk_attraction_verification_history_attraction
    ON attraction_verification_history IS
    'Prevents deletion of an attraction while immutable verification audit events exist.';

COMMENT ON CONSTRAINT fk_activity_verification_history_activity
    ON activity_verification_history IS
    'Prevents deletion of an activity while immutable verification audit events exist.';
