-- V27: persist the evidence gate summary used when an itinerary is generated.
-- Counts describe the deduplicated candidate set before/after the strict eligibility gate.
ALTER TABLE itineraries
    ADD COLUMN catalog_candidate_count INTEGER NOT NULL DEFAULT 0
        CHECK (catalog_candidate_count >= 0),
    ADD COLUMN recommendation_eligible_count INTEGER NOT NULL DEFAULT 0
        CHECK (recommendation_eligible_count >= 0),
    ADD COLUMN recommendation_excluded_count INTEGER NOT NULL DEFAULT 0
        CHECK (recommendation_excluded_count >= 0);

COMMENT ON COLUMN itineraries.catalog_candidate_count IS
    'Number of active non-rejected catalog candidates after semantic deduplication.';
COMMENT ON COLUMN itineraries.recommendation_eligible_count IS
    'Number of candidates that passed the strict evidence and planning-data gate.';
COMMENT ON COLUMN itineraries.recommendation_excluded_count IS
    'Number of candidates excluded because verification, source or planning data was insufficient.';
