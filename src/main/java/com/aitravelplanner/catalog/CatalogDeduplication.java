package com.aitravelplanner.catalog;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Removes only explicitly curated SAME_EXPERIENCE duplicates.
 * Catalogue entries are retained; suppression applies to a generated itinerary
 * only when the canonical counterpart is also present in the candidate set.
 */
public final class CatalogDeduplication {
    private CatalogDeduplication() {
    }

    public static List<Map<String, Object>> removeSemanticDuplicates(
            List<Map<String, Object>> candidates) {
        Set<String> available = new HashSet<>();
        for (Map<String, Object> candidate : candidates) {
            available.add(key(candidate.get("itemType"), candidate.get("catalogItemId")));
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Map<String, Object> candidate : candidates) {
            if (!"SAME_EXPERIENCE".equals(candidate.get("deduplicationRelation"))) {
                result.add(candidate);
                continue;
            }

            Object canonicalType = candidate.get("duplicateOfType");
            Object canonicalId = candidate.get("duplicateOfId");
            if (canonicalType == null || canonicalId == null
                    || !available.contains(key(canonicalType, canonicalId))) {
                result.add(candidate);
            }
        }
        return result;
    }

    private static String key(Object type, Object id) {
        return String.valueOf(type).toUpperCase() + ":" + String.valueOf(id);
    }
}
