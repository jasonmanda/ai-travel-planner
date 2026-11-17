-- Read-only audit of source suitability for attractions and activities.
-- Run manually in pgAdmin. This report does not update catalog data or verification status.

WITH catalog_items AS (
    SELECT 'ATTRACTION'::TEXT AS item_type, a.id, c.name AS city, co.name AS country,
           a.name, a.source_name, a.source_url, a.source_type, a.source_scope,
           a.data_status, a.verification_notes
      FROM attractions a
      JOIN cities c ON c.id = a.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE a.active = TRUE
    UNION ALL
    SELECT 'ACTIVITY'::TEXT, act.id, c.name, co.name,
           act.name, act.source_name, act.source_url, act.source_type, act.source_scope,
           act.data_status, act.verification_notes
      FROM activities act
      JOIN cities c ON c.id = act.city_id
      JOIN countries co ON co.id = c.country_id
     WHERE act.active = TRUE
),
classified AS (
    SELECT *,
           CASE
             WHEN NULLIF(BTRIM(source_name), '') IS NULL
               OR NULLIF(BTRIM(source_url), '') IS NULL
               OR source_url !~* '^https?://[^[:space:]]+$'
               THEN 'NO_USABLE_SOURCE'
             WHEN source_scope = 'DESTINATION_GENERAL'
               THEN 'DESTINATION_CONTEXT_ONLY'
             WHEN source_type = 'SCIENTIFIC'
               THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
             WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC')
               THEN 'SECONDARY_REFERENCE_ONLY'
             WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
               THEN 'ITEM_SPECIFIC_PRIMARY_REQUIRES_CONTENT_REVIEW'
             ELSE 'SOURCE_REQUIRES_REVIEW'
           END AS source_quality
      FROM catalog_items
)
SELECT item_type, id, city, country, name, source_name, source_url,
       source_type, source_scope, source_quality, data_status, verification_notes
  FROM classified
 ORDER BY country, city, item_type, name;

-- Summary counts by source quality and verification status.
WITH catalog_items AS (
    SELECT source_name, source_url, source_type, source_scope, data_status
      FROM attractions WHERE active = TRUE
    UNION ALL
    SELECT source_name, source_url, source_type, source_scope, data_status
      FROM activities WHERE active = TRUE
),
classified AS (
    SELECT data_status,
           CASE
             WHEN NULLIF(BTRIM(source_name), '') IS NULL
               OR NULLIF(BTRIM(source_url), '') IS NULL
               OR source_url !~* '^https?://[^[:space:]]+$'
               THEN 'NO_USABLE_SOURCE'
             WHEN source_scope = 'DESTINATION_GENERAL'
               THEN 'DESTINATION_CONTEXT_ONLY'
             WHEN source_type = 'SCIENTIFIC'
               THEN 'SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE'
             WHEN source_type IN ('ENCYCLOPEDIC', 'GENERIC')
               THEN 'SECONDARY_REFERENCE_ONLY'
             WHEN source_type = 'OFFICIAL' AND source_scope = 'ITEM_SPECIFIC'
               THEN 'ITEM_SPECIFIC_PRIMARY_REQUIRES_CONTENT_REVIEW'
             ELSE 'SOURCE_REQUIRES_REVIEW'
           END AS source_quality
      FROM catalog_items
)
SELECT source_quality, data_status, COUNT(*) AS item_count
  FROM classified
 GROUP BY source_quality, data_status
 ORDER BY source_quality, data_status;
