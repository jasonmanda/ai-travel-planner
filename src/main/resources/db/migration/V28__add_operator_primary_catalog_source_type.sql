-- V28: distinguish first-party tour-operator evidence from institutional sources.
-- Operator pages can document an operator's own offer, but are not independent
-- institutional evidence and do not satisfy the strict recommendation gate.
ALTER TABLE attractions
    DROP CONSTRAINT ck_attraction_source_type,
    ADD CONSTRAINT ck_attraction_source_type
        CHECK (source_type IN ('OFFICIAL', 'OPERATOR_PRIMARY', 'SCIENTIFIC', 'ENCYCLOPEDIC', 'GENERIC', 'UNKNOWN'));

ALTER TABLE activities
    DROP CONSTRAINT ck_activity_source_type,
    ADD CONSTRAINT ck_activity_source_type
        CHECK (source_type IN ('OFFICIAL', 'OPERATOR_PRIMARY', 'SCIENTIFIC', 'ENCYCLOPEDIC', 'GENERIC', 'UNKNOWN'));

COMMENT ON COLUMN attractions.source_type IS
    'Nature de la source documentaire (institutionnelle, opérateur primaire, scientifique ou secondaire); ne constitue pas une preuve de vérification factuelle.';
COMMENT ON COLUMN activities.source_type IS
    'Nature de la source documentaire (institutionnelle, opérateur primaire, scientifique ou secondaire); ne constitue pas une preuve de vérification factuelle.';
