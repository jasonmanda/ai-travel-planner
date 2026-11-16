-- V17: preserve catalog source transparency in itinerary snapshots.
-- These fields describe the source context available when the itinerary is generated.
-- They do not independently prove the factual accuracy of an item.

ALTER TABLE itinerary_items
    ADD COLUMN source_type VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',
    ADD COLUMN source_scope VARCHAR(24) NOT NULL DEFAULT 'UNKNOWN',
    ADD COLUMN verification_notes VARCHAR(1200),
    ADD COLUMN last_verified_at TIMESTAMPTZ;

ALTER TABLE itinerary_items
    ADD CONSTRAINT ck_itinerary_item_source_type
        CHECK (source_type IN (
            'OFFICIAL', 'SCIENTIFIC', 'ENCYCLOPEDIC', 'GENERIC', 'UNKNOWN'
        )),
    ADD CONSTRAINT ck_itinerary_item_source_scope
        CHECK (source_scope IN (
            'ITEM_SPECIFIC', 'DESTINATION_GENERAL', 'UNKNOWN'
        ));

COMMENT ON COLUMN itinerary_items.source_type IS
    'Nature de la source au moment de la génération; ne prouve pas la vérification factuelle.';

COMMENT ON COLUMN itinerary_items.source_scope IS
    'Portée de la source au moment de la génération.';

COMMENT ON COLUMN itinerary_items.verification_notes IS
    'Notes et limites documentaires conservées dans le snapshot.';

COMMENT ON COLUMN itinerary_items.last_verified_at IS
    'Date de dernière vérification complète connue au moment de la génération.';
