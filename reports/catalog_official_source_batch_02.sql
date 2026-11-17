-- Targeted official-source replacement for Prison Island (Changuu), Zanzibar.
-- MANUAL execution in pgAdmin only. This is NOT a Flyway migration.
--
-- Evidence:
-- Zanzibar Petroleum Regulatory Authority (ZPRA), EAPCE25 First Circular.
-- The document has a dedicated "PRISON ISLAND" section, identifies Changuu Island,
-- describes the boat journey from Stone Town and the giant Aldabra tortoises:
-- https://www.nishati.go.tz/uploads/documents/en-1717415585-EAPCE25%20FIRST%20CIRCULAR.pdf
--
-- Limits:
-- This is an official government-hosted event document, not a live visitor service.
-- It does not establish current opening/access, operator, schedule, price, safety,
-- conservation rules or availability on a travel date.
-- No other remaining generic entry is changed in this batch because the research
-- did not identify a sufficiently precise official item-level source.
--
-- Safety:
-- Exact country, city, item name and previous URL guards.
-- Only source metadata and verification_notes are updated.
-- data_status, last_verified_at and verification history remain untouched.

BEGIN;

UPDATE attractions a
   SET source_name = 'Zanzibar Petroleum Regulatory Authority - EAPCE25 First Circular (Prison Island)',
       source_url = 'https://www.nishati.go.tz/uploads/documents/en-1717415585-EAPCE25%20FIRST%20CIRCULAR.pdf',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Document institutionnel hébergé par le ministère tanzanien de l’Énergie, avec une section dédiée à Prison Island (Changuu Island), décrivant l’île, son accès historique en bateau depuis Stone Town et la présence de tortues géantes Aldabra. Cette source confirme l’identification patrimoniale et touristique du lieu, mais ne confirme pas les conditions actuelles d’accès, horaires, tarifs, opérateurs, règles de conservation ni disponibilité à la date du voyage.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE a.city_id = c.id
   AND c.name = 'Zanzibar'
   AND co.iso_code = 'TZ'
   AND a.name = 'Prison Island (Changuu)'
   AND a.source_url = 'https://visitzanzibar.go.tz/';

COMMIT;

-- Read-only post-run check. Expected: one row, still UNVERIFIED.
SELECT co.iso_code, c.name AS city, a.name,
       a.source_name, a.source_url, a.source_type, a.source_scope,
       a.data_status, a.last_verified_at, a.verification_notes
  FROM attractions a
  JOIN cities c ON c.id = a.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code = 'TZ'
   AND c.name = 'Zanzibar'
   AND a.name = 'Prison Island (Changuu)';
