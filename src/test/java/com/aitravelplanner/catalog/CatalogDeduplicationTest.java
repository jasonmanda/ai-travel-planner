package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class CatalogDeduplicationTest {

    @Test
    void removesActivityWhenItsCanonicalAttractionIsPresent() {
        Map<String, Object> attraction = item("ATTRACTION", 12L, null, null, null);
        Map<String, Object> activity = item("ACTIVITY", 9L, "ATTRACTION", 12L, "SAME_EXPERIENCE");

        List<Map<String, Object>> result =
                CatalogDeduplication.removeSemanticDuplicates(List.of(attraction, activity));

        assertEquals(List.of(attraction), result);
    }

    @Test
    void keepsActivityWhenCanonicalAttractionIsNotAvailable() {
        Map<String, Object> activity = item("ACTIVITY", 9L, "ATTRACTION", 12L, "SAME_EXPERIENCE");

        List<Map<String, Object>> result =
                CatalogDeduplication.removeSemanticDuplicates(List.of(activity));

        assertEquals(List.of(activity), result);
    }

    @Test
    void doesNotRemoveComplementaryActivities() {
        Map<String, Object> activity = item("ACTIVITY", 8L, null, null, null);

        List<Map<String, Object>> result =
                CatalogDeduplication.removeSemanticDuplicates(List.of(activity));

        assertEquals(List.of(activity), result);
    }

    @Test
    void doesNotRemoveItemsForOtherRelationTypes() {
        Map<String, Object> attraction = item("ATTRACTION", 12L, null, null, null);
        Map<String, Object> activity = item("ACTIVITY", 9L, "ATTRACTION", 12L, "RELATED_TO");

        List<Map<String, Object>> result =
                CatalogDeduplication.removeSemanticDuplicates(List.of(attraction, activity));

        assertEquals(2, result.size());
    }

    private static Map<String, Object> item(
            String type, long id, String duplicateOfType, Long duplicateOfId, String relation) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("itemType", type);
        item.put("catalogItemId", id);
        item.put("duplicateOfType", duplicateOfType);
        item.put("duplicateOfId", duplicateOfId);
        item.put("deduplicationRelation", relation);
        return item;
    }
}
