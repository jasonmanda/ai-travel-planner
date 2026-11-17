-- Manual PostgreSQL schema update for OPERATOR_PRIMARY.
-- Run manually in pgAdmin. NOT a Flyway migration.
--
-- Keeps the existing allowed source types and adds OPERATOR_PRIMARY.
-- Does not update catalog rows or verification status.

BEGIN;

ALTER TABLE activities
    DROP CONSTRAINT ck_activity_source_type;

ALTER TABLE activities
    ADD CONSTRAINT ck_activity_source_type
    CHECK (
        source_type IS NULL
        OR source_type IN (
            'OFFICIAL',
            'SCIENTIFIC',
            'ENCYCLOPEDIC',
            'GENERIC',
            'UNKNOWN',
            'OPERATOR_PRIMARY'
        )
    );

ALTER TABLE attractions
    DROP CONSTRAINT ck_attraction_source_type;

ALTER TABLE attractions
    ADD CONSTRAINT ck_attraction_source_type
    CHECK (
        source_type IS NULL
        OR source_type IN (
            'OFFICIAL',
            'SCIENTIFIC',
            'ENCYCLOPEDIC',
            'GENERIC',
            'UNKNOWN',
            'OPERATOR_PRIMARY'
        )
    );

COMMIT;

-- Read-only verification.
SELECT
    conrelid::regclass AS table_name,
    conname,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname IN (
    'ck_activity_source_type',
    'ck_attraction_source_type'
)
ORDER BY conname;
