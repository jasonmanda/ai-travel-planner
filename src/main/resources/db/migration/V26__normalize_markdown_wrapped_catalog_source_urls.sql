-- V26: normalize source URLs accidentally stored as Markdown links.
-- Only unwrap links whose visible URL is exactly identical to their target URL.
-- Ambiguous/different-target Markdown links are deliberately left unchanged for manual review.
-- This changes documentation formatting only; source identity, scope and verification status are untouched.

WITH attraction_candidates AS (
    SELECT id,
           regexp_match(
               source_url,
               '^\[(https?://[^]]+)\]\((https?://[^)]+)\)$'
           ) AS url_parts
      FROM attractions
     WHERE source_url ~ '^\[https?://[^]]+\]\(https?://[^)]+\)$'
),
activity_candidates AS (
    SELECT id,
           regexp_match(
               source_url,
               '^\[(https?://[^]]+)\]\((https?://[^)]+)\)$'
           ) AS url_parts
      FROM activities
     WHERE source_url ~ '^\[https?://[^]]+\]\(https?://[^)]+\)$'
)
UPDATE attractions a
   SET source_url = c.url_parts[1]
  FROM attraction_candidates c
 WHERE a.id = c.id
   AND c.url_parts[1] = c.url_parts[2];

UPDATE activities a
   SET source_url = c.url_parts[1]
  FROM (
      SELECT id,
             regexp_match(
                 source_url,
                 '^\[(https?://[^]]+)\]\((https?://[^)]+)\)$'
             ) AS url_parts
        FROM activities
       WHERE source_url ~ '^\[https?://[^]]+\]\(https?://[^)]+\)$'
  ) c
 WHERE a.id = c.id
   AND c.url_parts[1] = c.url_parts[2];

COMMENT ON COLUMN attractions.source_url IS
    'URL de référence brute (HTTP/HTTPS), sans balisage Markdown.';
COMMENT ON COLUMN activities.source_url IS
    'URL de référence brute (HTTP/HTTPS), sans balisage Markdown.';
