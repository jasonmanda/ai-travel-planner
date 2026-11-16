-- V13: add explicit source classification and traceability to travel catalog items.
-- Existing records remain UNVERIFIED; source metadata must never imply factual verification.

ALTER TABLE attractions
    ADD COLUMN source_type VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',
    ADD COLUMN source_scope VARCHAR(24) NOT NULL DEFAULT 'UNKNOWN',
    ADD COLUMN verification_notes VARCHAR(1200);

ALTER TABLE activities
    ADD COLUMN source_type VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',
    ADD COLUMN source_scope VARCHAR(24) NOT NULL DEFAULT 'UNKNOWN',
    ADD COLUMN verification_notes VARCHAR(1200);

ALTER TABLE attractions
    ADD CONSTRAINT ck_attraction_source_type
        CHECK (source_type IN ('OFFICIAL', 'SCIENTIFIC', 'ENCYCLOPEDIC', 'GENERIC', 'UNKNOWN')),
    ADD CONSTRAINT ck_attraction_source_scope
        CHECK (source_scope IN ('ITEM_SPECIFIC', 'DESTINATION_GENERAL', 'UNKNOWN'));

ALTER TABLE activities
    ADD CONSTRAINT ck_activity_source_type
        CHECK (source_type IN ('OFFICIAL', 'SCIENTIFIC', 'ENCYCLOPEDIC', 'GENERIC', 'UNKNOWN')),
    ADD CONSTRAINT ck_activity_source_scope
        CHECK (source_scope IN ('ITEM_SPECIFIC', 'DESTINATION_GENERAL', 'UNKNOWN'));

COMMENT ON COLUMN attractions.source_type IS
    'Nature de la source documentaire; ne constitue pas une preuve de verification factuelle.';
COMMENT ON COLUMN attractions.source_scope IS
    'Portee de la source: attraction specifique, destination generale ou inconnue.';
COMMENT ON COLUMN attractions.verification_notes IS
    'Notes explicatives sur les informations couvertes et les limites de la source.';

COMMENT ON COLUMN activities.source_type IS
    'Nature de la source documentaire; ne constitue pas une preuve de verification factuelle.';
COMMENT ON COLUMN activities.source_scope IS
    'Portee de la source: activite specifique, destination generale ou inconnue.';
COMMENT ON COLUMN activities.verification_notes IS
    'Notes explicatives sur les informations couvertes et les limites de la source.';
