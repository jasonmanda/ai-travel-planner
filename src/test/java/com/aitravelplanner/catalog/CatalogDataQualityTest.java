package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CatalogDataQualityTest {

    @Test
    void scoresFullyDocumentedVerifiedItemAtOneHundred() {
        Map<String, Object> item = item();
        item.put("dataStatus", "VERIFIED");
        item.put("sourceUrl", "https://example.org/official-source");
        item.put("latitude", -6.1);
        item.put("longitude", 39.2);
        item.put("estimatedDurationMinutes", 60);
        item.put("estimatedCost", BigDecimal.ZERO);
        item.put("currency", "TZS");

        Map<String, Object> quality = CatalogDataQuality.assess(item);

        assertEquals(100, quality.get("score"));
        assertEquals("WELL_DOCUMENTED", quality.get("status"));
        assertEquals(List.of(), quality.get("warnings"));
    }

    @Test
    void givesPartialVerificationLessWeightThanFullVerification() {
        Map<String, Object> item = item();
        item.put("dataStatus", "PARTIALLY_VERIFIED");
        item.put("sourceUrl", "https://example.org/source");

        Map<String, Object> quality = CatalogDataQuality.assess(item);

        assertEquals(35, quality.get("score"));
        assertTrue(((List<?>) quality.get("warnings")).contains("PARTIALLY_VERIFIED"));
        assertTrue(!((List<?>) quality.get("warnings")).contains("NOT_VERIFIED"));
    }

    @Test
    void reportsMissingFieldsWithoutInventingValues() {
        Map<String, Object> quality = CatalogDataQuality.assess(item());

        assertEquals(0, quality.get("score"));
        assertEquals("LOW", quality.get("status"));
        assertTrue(((List<?>) quality.get("warnings")).contains("SOURCE_MISSING"));
        assertTrue(((List<?>) quality.get("warnings")).contains("NOT_VERIFIED"));
        assertTrue(((List<?>) quality.get("warnings")).contains("COORDINATES_MISSING"));
    }

    @Test
    void rejectsMarkdownWrappedSourceUrl() {
        Map<String, Object> item = item();
        item.put("sourceUrl", "[https://example.org](https://example.org)");

        Map<String, Object> quality = CatalogDataQuality.assess(item);

        assertTrue(((List<?>) quality.get("warnings")).contains("SOURCE_MISSING"));
        assertEquals(0, quality.get("score"));
    }

    @Test
    void rejectsInvalidCoordinates() {
        Map<String, Object> item = item();
        item.put("latitude", 120.0);
        item.put("longitude", 39.2);

        Map<String, Object> quality = CatalogDataQuality.assess(item);

        assertTrue(((List<?>) quality.get("warnings")).contains("COORDINATES_MISSING"));
    }

    private static Map<String, Object> item() {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("dataStatus", "UNVERIFIED");
        item.put("sourceUrl", null);
        item.put("latitude", null);
        item.put("longitude", null);
        item.put("estimatedDurationMinutes", null);
        item.put("estimatedCost", null);
        item.put("currency", null);
        return item;
    }
}
