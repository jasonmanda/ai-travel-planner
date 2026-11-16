-- V10: explicit, conservative semantic duplicate relationships for catalogue entries.
-- A relation is curated metadata, not an inferred similarity score.
-- The canonical entry remains visible; its duplicate is retained in the catalogue
-- but omitted from generated itineraries when the canonical entry is also available.

UPDATE attractions a
SET geographic_area = 'STONE_TOWN'
FROM cities c
JOIN countries co ON co.id = c.country_id
WHERE a.city_id = c.id
  AND c.name = 'Zanzibar'
  AND co.iso_code = 'TZ'
  AND a.name = 'Stone Town'
  AND (a.geographic_area IS NULL OR a.geographic_area <> 'STONE_TOWN');

CREATE TABLE IF NOT EXISTS catalog_item_relations (
    id BIGSERIAL PRIMARY KEY,
    city_id BIGINT NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    canonical_item_type VARCHAR(20) NOT NULL
        CHECK (canonical_item_type IN ('ATTRACTION', 'ACTIVITY')),
    canonical_item_id BIGINT NOT NULL,
    duplicate_item_type VARCHAR(20) NOT NULL
        CHECK (duplicate_item_type IN ('ATTRACTION', 'ACTIVITY')),
    duplicate_item_id BIGINT NOT NULL,
    relation_type VARCHAR(40) NOT NULL DEFAULT 'SAME_EXPERIENCE',
    reason TEXT NOT NULL,
    confidence NUMERIC(3,2) NOT NULL DEFAULT 1.00
        CHECK (confidence >= 0 AND confidence <= 1),
    source_name VARCHAR(255),
    source_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_catalog_item_relation UNIQUE (
        city_id, canonical_item_type, canonical_item_id,
        duplicate_item_type, duplicate_item_id, relation_type
    ),
    CONSTRAINT ck_catalog_item_relation_not_self
        CHECK (canonical_item_type <> duplicate_item_type
               OR canonical_item_id <> duplicate_item_id)
);

CREATE INDEX IF NOT EXISTS idx_catalog_item_relations_duplicate
    ON catalog_item_relations(city_id, duplicate_item_type, duplicate_item_id);

-- The attraction represents the place/experience itself. The activity is a
-- catalogue phrasing of visiting that same place, not a separate experience.
INSERT INTO catalog_item_relations (
    city_id, canonical_item_type, canonical_item_id,
    duplicate_item_type, duplicate_item_id, relation_type,
    reason, confidence, source_name, source_url
)
SELECT c.id, 'ATTRACTION', a.id, 'ACTIVITY', act.id, 'SAME_EXPERIENCE',
       'L’activité décrit la visite de la même forêt déjà représentée par l’attraction.',
       1.00, 'Curated Voyagea catalogue relationship',
       'https://visitzanzibar.go.tz/'
FROM cities c
JOIN countries co ON co.id = c.country_id
JOIN attractions a ON a.city_id = c.id AND a.name = 'Jozani Forest'
JOIN activities act ON act.city_id = c.id
                   AND act.name = 'Excursion dans la forêt de Jozani'
WHERE c.name = 'Zanzibar' AND co.iso_code = 'TZ'
ON CONFLICT (
    city_id, canonical_item_type, canonical_item_id,
    duplicate_item_type, duplicate_item_id, relation_type
) DO NOTHING;

-- The boat-trip activity is the way to visit the same sandbank, not an
-- additional catalogue attraction. It is hidden only when the attraction exists.
INSERT INTO catalog_item_relations (
    city_id, canonical_item_type, canonical_item_id,
    duplicate_item_type, duplicate_item_id, relation_type,
    reason, confidence, source_name, source_url
)
SELECT c.id, 'ATTRACTION', a.id, 'ACTIVITY', act.id, 'SAME_EXPERIENCE',
       'L’excursion en bateau désigne la visite du banc de sable déjà représenté par l’attraction.',
       0.95, 'Curated Voyagea catalogue relationship',
       'https://visitzanzibar.go.tz/'
FROM cities c
JOIN countries co ON co.id = c.country_id
JOIN attractions a ON a.city_id = c.id AND a.name = 'Nakupenda Sandbank'
JOIN activities act ON act.city_id = c.id
                   AND act.name = 'Excursion en bateau vers un banc de sable'
WHERE c.name = 'Zanzibar' AND co.iso_code = 'TZ'
ON CONFLICT (
    city_id, canonical_item_type, canonical_item_id,
    duplicate_item_type, duplicate_item_id, relation_type
) DO NOTHING;
