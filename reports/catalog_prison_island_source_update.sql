-- Manual, guarded source correction for Prison Island (Changuu).
-- Run manually in pgAdmin. NOT a Flyway migration.
--
-- The Zanzibar Ministry of Finance BIG-Z ESMF, Annex E, identifies
-- Changuu Island and describes its historical use and current tourism-centre
-- operation. It is a stronger institutional, item-specific reference than
-- the previous EAPCE25 event circular.
--
-- This update changes source metadata only. It does NOT verify current visitor
-- access, opening hours, prices, boat schedules, availability, coordinates,
-- duration, or safety conditions. The record remains UNVERIFIED.

BEGIN;

DO $$
DECLARE
    n INTEGER;
BEGIN
    UPDATE attractions a
       SET source_name = 'Zanzibar Ministry of Finance - BIG-Z ESMF, Annex E: Historical Sites (Changuu Island)',
           source_url = 'https://mofzanzibar.go.tz/wp-content/uploads/2025/12/UPDATED-ESMF-BIG-Z-AFTER-RESTRUCTURING_FINAL-CLEARED-VERSION-BY-THE-WB_DISCLOSED-CLEAN-VERSION-26.11.2025.pdf',
           source_type = 'OFFICIAL',
           source_scope = 'ITEM_SPECIFIC',
           verification_notes = 'Document officiel du Ministry of Finance Zanzibar, annexe E sur les sites historiques: identifie Changuu Island et décrit son histoire ainsi que son exploitation comme centre touristique. Cette référence ne confirme pas les conditions actuelles de visite, horaires, tarifs, départs de bateaux, disponibilité, sécurité, coordonnées ni durée réelle. La fiche reste UNVERIFIED.'
      FROM cities c
      JOIN countries co ON co.id = c.country_id
     WHERE a.city_id = c.id
       AND co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND a.id = 13
       AND a.name = 'Prison Island (Changuu)'
       AND a.data_status = 'UNVERIFIED'
       AND a.last_verified_at IS NULL
       AND a.source_name = 'Zanzibar Petroleum Regulatory Authority - EAPCE25 First Circular (Prison Island)'
       AND a.source_url ILIKE '%nishati.go.tz%EAPCE25%FIRST%CIRCULAR%';
    GET DIAGNOSTICS n = ROW_COUNT;

    IF n <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one guarded Prison Island source update, got %. Transaction rolled back.', n;
    END IF;
END $$;

COMMIT;

-- Post-run verification. The row must remain UNVERIFIED and unverified.
SELECT
    co.iso_code,
    c.name AS city,
    a.id,
    a.name,
    a.source_name,
    a.source_url,
    a.source_type,
    a.source_scope,
    a.data_status,
    a.last_verified_at,
    a.verification_notes
FROM attractions a
JOIN cities c ON c.id = a.city_id
JOIN countries co ON co.id = c.country_id
WHERE co.iso_code = 'TZ'
  AND c.name = 'Zanzibar'
  AND a.id = 13;
