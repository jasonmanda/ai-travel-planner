-- Read-only audit of the 27 catalog records reviewed in the November 2026 batch.
-- Run manually in pgAdmin. SELECT statements only; NOT a Flyway migration.
-- Reports missing coordinate pairs and durations without changing catalog data.

WITH targets(item_type, iso_code, city, item_id) AS (
    VALUES
      ('ACTIVITY', 'MA', 'Marrakech', 3),
      ('ACTIVITY', 'MA', 'Marrakech', 4),
      ('ATTRACTION', 'MA', 'Marrakech', 3),
      ('ATTRACTION', 'MA', 'Marrakech', 4),
      ('ACTIVITY', 'TZ', 'Zanzibar', 1),
      ('ACTIVITY', 'TZ', 'Zanzibar', 2),
      ('ACTIVITY', 'TZ', 'Zanzibar', 7),
      ('ACTIVITY', 'TZ', 'Zanzibar', 8),
      ('ACTIVITY', 'TZ', 'Zanzibar', 9),
      ('ACTIVITY', 'TZ', 'Zanzibar', 10),
      ('ACTIVITY', 'TZ', 'Zanzibar', 11),
      ('ATTRACTION', 'TZ', 'Zanzibar', 1),
      ('ATTRACTION', 'TZ', 'Zanzibar', 2),
      ('ATTRACTION', 'TZ', 'Zanzibar', 7),
      ('ATTRACTION', 'TZ', 'Zanzibar', 8),
      ('ATTRACTION', 'TZ', 'Zanzibar', 9),
      ('ATTRACTION', 'TZ', 'Zanzibar', 10),
      ('ATTRACTION', 'TZ', 'Zanzibar', 11),
      ('ATTRACTION', 'TZ', 'Zanzibar', 12),
      ('ATTRACTION', 'TZ', 'Zanzibar', 13),
      ('ATTRACTION', 'TZ', 'Zanzibar', 14),
      ('ATTRACTION', 'TZ', 'Zanzibar', 15),
      ('ATTRACTION', 'TZ', 'Zanzibar', 16),
      ('ACTIVITY', 'ZA', 'Le Cap', 5),
      ('ACTIVITY', 'ZA', 'Le Cap', 6),
      ('ATTRACTION', 'ZA', 'Le Cap', 5),
      ('ATTRACTION', 'ZA', 'Le Cap', 6)
),
catalog_items AS (
    SELECT t.item_type, t.iso_code, t.city, t.item_id,
           a.id IS NOT NULL AS record_found,
           a.name, a.category, a.active, a.data_status, a.last_verified_at,
           a.latitude, a.longitude, a.estimated_duration_minutes,
           a.source_name, a.source_url, a.source_type, a.source_scope
      FROM targets t
      LEFT JOIN countries co ON co.iso_code = t.iso_code
      LEFT JOIN cities c ON c.country_id = co.id AND c.name = t.city
      LEFT JOIN activities a ON a.city_id = c.id AND a.id = t.item_id
     WHERE t.item_type = 'ACTIVITY'

    UNION ALL

    SELECT t.item_type, t.iso_code, t.city, t.item_id,
           a.id IS NOT NULL,
           a.name, a.category, a.active, a.data_status, a.last_verified_at,
           a.latitude, a.longitude, a.estimated_duration_minutes,
           a.source_name, a.source_url, a.source_type, a.source_scope
      FROM targets t
      LEFT JOIN countries co ON co.iso_code = t.iso_code
      LEFT JOIN cities c ON c.country_id = co.id AND c.name = t.city
      LEFT JOIN attractions a ON a.city_id = c.id AND a.id = t.item_id
     WHERE t.item_type = 'ATTRACTION'
)
SELECT item_type, iso_code, city, item_id, record_found,
       name, category, active, data_status, last_verified_at,
       latitude, longitude,
       (latitude IS NOT NULL AND longitude IS NOT NULL
        AND latitude BETWEEN -90 AND 90
        AND longitude BETWEEN -180 AND 180) AS coordinates_valid,
       estimated_duration_minutes,
       (estimated_duration_minutes IS NOT NULL
        AND estimated_duration_minutes > 0) AS duration_valid,
       source_name, source_url, source_type, source_scope
  FROM catalog_items
 WHERE NOT record_found
    OR latitude IS NULL OR longitude IS NULL
    OR estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0
 ORDER BY iso_code, city, item_type, item_id;

-- Batch summary for the same 27 target records.
WITH targets(item_type, iso_code, city, item_id) AS (
    VALUES
      ('ACTIVITY', 'MA', 'Marrakech', 3), ('ACTIVITY', 'MA', 'Marrakech', 4),
      ('ATTRACTION', 'MA', 'Marrakech', 3), ('ATTRACTION', 'MA', 'Marrakech', 4),
      ('ACTIVITY', 'TZ', 'Zanzibar', 1), ('ACTIVITY', 'TZ', 'Zanzibar', 2),
      ('ACTIVITY', 'TZ', 'Zanzibar', 7), ('ACTIVITY', 'TZ', 'Zanzibar', 8),
      ('ACTIVITY', 'TZ', 'Zanzibar', 9), ('ACTIVITY', 'TZ', 'Zanzibar', 10),
      ('ACTIVITY', 'TZ', 'Zanzibar', 11),
      ('ATTRACTION', 'TZ', 'Zanzibar', 1), ('ATTRACTION', 'TZ', 'Zanzibar', 2),
      ('ATTRACTION', 'TZ', 'Zanzibar', 7), ('ATTRACTION', 'TZ', 'Zanzibar', 8),
      ('ATTRACTION', 'TZ', 'Zanzibar', 9), ('ATTRACTION', 'TZ', 'Zanzibar', 10),
      ('ATTRACTION', 'TZ', 'Zanzibar', 11), ('ATTRACTION', 'TZ', 'Zanzibar', 12),
      ('ATTRACTION', 'TZ', 'Zanzibar', 13), ('ATTRACTION', 'TZ', 'Zanzibar', 14),
      ('ATTRACTION', 'TZ', 'Zanzibar', 15), ('ATTRACTION', 'TZ', 'Zanzibar', 16),
      ('ACTIVITY', 'ZA', 'Le Cap', 5), ('ACTIVITY', 'ZA', 'Le Cap', 6),
      ('ATTRACTION', 'ZA', 'Le Cap', 5), ('ATTRACTION', 'ZA', 'Le Cap', 6)
),
items AS (
    SELECT t.item_type, a.id IS NOT NULL AS record_found, a.data_status,
           a.latitude, a.longitude, a.estimated_duration_minutes
      FROM targets t
      LEFT JOIN countries co ON co.iso_code = t.iso_code
      LEFT JOIN cities c ON c.country_id = co.id AND c.name = t.city
      LEFT JOIN activities a ON a.city_id = c.id AND a.id = t.item_id
     WHERE t.item_type = 'ACTIVITY'
    UNION ALL
    SELECT t.item_type, a.id IS NOT NULL, a.data_status,
           a.latitude, a.longitude, a.estimated_duration_minutes
      FROM targets t
      LEFT JOIN countries co ON co.iso_code = t.iso_code
      LEFT JOIN cities c ON c.country_id = co.id AND c.name = t.city
      LEFT JOIN attractions a ON a.city_id = c.id AND a.id = t.item_id
     WHERE t.item_type = 'ATTRACTION'
)
SELECT COUNT(*) AS target_count,
       COUNT(*) FILTER (WHERE record_found) AS found_count,
       COUNT(*) FILTER (WHERE NOT record_found) AS missing_target_count,
       COUNT(*) FILTER (WHERE record_found AND (latitude IS NULL OR longitude IS NULL))
           AS missing_coordinate_pair_count,
       COUNT(*) FILTER (WHERE record_found
                         AND (estimated_duration_minutes IS NULL OR estimated_duration_minutes <= 0))
           AS missing_or_invalid_duration_count,
       COUNT(*) FILTER (WHERE record_found AND data_status <> 'VERIFIED')
           AS not_verified_count
  FROM items;
