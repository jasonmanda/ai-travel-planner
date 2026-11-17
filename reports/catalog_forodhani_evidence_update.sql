-- Targeted provenance correction for Forodhani's evening vendor activity.
-- MANUAL execution in pgAdmin only. This is NOT a Flyway migration.
--
-- Evidence:
-- Zanzibar House of Representatives, Budget Committee Report 2022/2023,
-- February 2023, pp. 77-78 (printed report pagination).
-- The section is explicitly titled "Assessment of revenue collection from
-- businesses and services in the Forodhani area for FY 2021/2022".
-- It describes Forodhani Gardens as especially active in the evening, when
-- many vendors gather to provide services to residents and visitors.
--
-- Scope:
--   * One activity only: Zanzibar ACTIVITY id=11.
--   * Source metadata and verification_notes only.
--   * data_status, last_verified_at, coordinates, duration and verification
--     history are not modified.
--   * The report is historical (FY 2021/2022); it does not establish today's
--     opening hours, exact vendor roster, prices, food hygiene or availability.
--   * This update does not promote the item to VERIFIED.

BEGIN;

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM activities act
      JOIN cities c ON c.id = act.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE co.iso_code = 'TZ'
       AND c.name = 'Zanzibar'
       AND act.id = 11
       AND act.name = 'Découverte du marché nocturne de Forodhani'
       AND act.source_url = 'https://zanzibarassembly.go.tz/storage/documents/Committees/all/1677484498.pdf'
       AND act.data_status = 'UNVERIFIED';

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'Expected exactly one unverified Forodhani activity with the reviewed source; found %',
            v_count;
    END IF;
END $$;

UPDATE activities act
   SET source_name = 'Zanzibar House of Representatives - Budget Committee Report 2022/2023 (Forodhani assessment)',
       source_type = 'OFFICIAL',
       source_scope = 'ITEM_SPECIFIC',
       verification_notes = 'Le rapport officiel de la Commission du Budget de la Baraza la Wawakilishi de Zanzibar (février 2023), pages 77–78, comporte une section consacrée aux commerces et services de la zone de Forodhani pendant l’exercice 2021/2022. Il indique que les jardins sont particulièrement animés en soirée, lorsque de nombreux vendeurs s’y rassemblent pour offrir des services aux habitants et aux visiteurs. Cette preuve institutionnelle et spécifique soutient l’existence d’une activité commerciale en soirée à Forodhani, mais elle est historique : elle ne confirme pas les horaires actuels, la présence quotidienne des vendeurs, les produits proposés aujourd’hui, les prix, l’hygiène alimentaire ni les conditions de visite à la date du voyage. La fiche reste UNVERIFIED.'
  FROM cities c
  JOIN countries co ON co.id = c.country_id
 WHERE act.city_id = c.id
   AND co.iso_code = 'TZ'
   AND c.name = 'Zanzibar'
   AND act.id = 11
   AND act.name = 'Découverte du marché nocturne de Forodhani'
   AND act.source_url = 'https://zanzibarassembly.go.tz/storage/documents/Committees/all/1677484498.pdf'
   AND act.data_status = 'UNVERIFIED';

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    GET DIAGNOSTICS v_count = ROW_COUNT;
    -- ROW_COUNT inside this block is local to the block; final state is checked below.
END $$;

COMMIT;

-- Read-only post-run check. Expected: exactly one row, still UNVERIFIED.
SELECT act.id,
       act.name,
       act.source_name,
       act.source_url,
       act.source_type,
       act.source_scope,
       act.data_status,
       act.last_verified_at,
       act.verification_notes
  FROM activities act
  JOIN cities c ON c.id = act.city_id
  JOIN countries co ON co.id = c.country_id
 WHERE co.iso_code = 'TZ'
   AND c.name = 'Zanzibar'
   AND act.id = 11
   AND act.name = 'Découverte du marché nocturne de Forodhani';
