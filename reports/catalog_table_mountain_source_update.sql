-- Manual, guarded source-reference correction for Table Mountain attraction.
-- Run manually in pgAdmin. This is NOT a Flyway migration.
-- Updates source metadata only; it does not verify the attraction or change
-- coordinates, duration, prices, verification history, or data_status.

BEGIN;

DO $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE attractions
       SET source_name = 'SANParks - Table Mountain attraction page',
           source_url = 'https://www.sanparks.org/parks/table-mountain/what-to-do/attractions/table-mountain'
     WHERE id = 6
       AND name = 'Table Mountain'
       AND source_url IN (
           'https://www.sanparks.org/parks/table-mountain',
           'https://www.sanparks.org/parks/table-mountain/'
       )
       AND source_type = 'OFFICIAL'
       AND source_scope = 'ITEM_SPECIFIC'
       AND data_status = 'UNVERIFIED';

    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    IF affected_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected to update exactly one unverified Table Mountain attraction (id=6); updated % row(s). No change should be committed.',
            affected_rows;
    END IF;
END $$;

-- Postcondition: the dedicated SANParks item page is recorded and the item
-- remains UNVERIFIED. Review this row before committing.
SELECT
    id,
    name,
    source_name,
    source_url,
    source_type,
    source_scope,
    data_status,
    last_verified_at
FROM attractions
WHERE id = 6
  AND name = 'Table Mountain';

COMMIT;
