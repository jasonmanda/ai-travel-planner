-- V11: suppress the generic Stone Town heritage activity when the Stone Town attraction is present.
-- The guided heritage tour remains a distinct, potentially complementary experience.
INSERT INTO catalog_item_relations (
    city_id, canonical_item_type, canonical_item_id,
    duplicate_item_type, duplicate_item_id, relation_type,
    reason, confidence, source_name, source_url
)
SELECT c.id, 'ATTRACTION', a.id, 'ACTIVITY', act.id, 'SAME_EXPERIENCE',
       'L’activité générique de découverte du patrimoine décrit la visite de Stone Town déjà représentée par l’attraction. La visite guidée reste distincte et est conservée.',
       0.98, 'Curated Voyagea catalogue relationship',
       'https://whc.unesco.org/en/urban-heritage-atlas/stone-town'
FROM cities c
JOIN countries co ON co.id = c.country_id
JOIN attractions a ON a.city_id = c.id AND a.name = 'Stone Town'
JOIN activities act ON act.city_id = c.id
                   AND act.name = 'Découverte du patrimoine de Stone Town'
WHERE c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
ON CONFLICT (
    city_id, canonical_item_type, canonical_item_id,
    duplicate_item_type, duplicate_item_id, relation_type
) DO NOTHING;
