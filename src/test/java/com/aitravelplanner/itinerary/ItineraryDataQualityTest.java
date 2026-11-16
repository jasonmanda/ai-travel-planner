package com.aitravelplanner.itinerary;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ItineraryDataQualityTest {

    @Test
    void scoresFullyDocumentedVerifiedItemAtOneHundred() {
        Map<String, Object> item = item("VERIFIED", true, true, true, true);
        Map<String, Object> quality = ItineraryDataQuality.assessDay(List.of(item));

        assertEquals(100, quality.get("score"));
        assertEquals("WELL_DOCUMENTED", quality.get("status"));
        assertEquals(List.of(), quality.get("warnings"));
    }

    @Test
    void reportsMissingEvidenceWithoutInventingValues() {
        Map<String, Object> quality = ItineraryDataQuality.assessDay(
                List.of(item("UNVERIFIED", false, false, false, false)));

        assertEquals(0, quality.get("score"));
        assertEquals("LOW", quality.get("status"));
        assertTrue(((List<?>) quality.get("warnings")).contains("NOT_VERIFIED"));
        assertTrue(((List<?>) quality.get("warnings")).contains("COST_MISSING"));
    }

    @Test
    void treatsEmptyDayAsNoData() {
        Map<String, Object> quality = ItineraryDataQuality.assessDay(List.of());

        assertEquals("NO_DATA", quality.get("status"));
        assertEquals(0, quality.get("score"));
        assertEquals(0, quality.get("itemCount"));
    }

    @Test
    void aggregatesItineraryByNumberOfItemsAndCountsEmptyDays() {
        Map<String, Object> completeDay = new LinkedHashMap<>();
        completeDay.put("dataQuality", ItineraryDataQuality.assessDay(
                List.of(item("VERIFIED", true, true, true, true))));
        Map<String, Object> incompleteDay = new LinkedHashMap<>();
        incompleteDay.put("dataQuality", ItineraryDataQuality.assessDay(
                List.of(item("UNVERIFIED", false, false, false, false))));
        Map<String, Object> emptyDay = new LinkedHashMap<>();
        emptyDay.put("dataQuality", ItineraryDataQuality.assessDay(List.of()));

        Map<String, Object> summary = ItineraryDataQuality.assessItinerary(
                List.of(completeDay, incompleteDay, emptyDay));

        assertEquals(50, summary.get("score"));
        assertEquals(2, summary.get("itemCount"));
        assertEquals(1, summary.get("daysWithoutItems"));
        assertEquals("PARTIAL", summary.get("status"));
    }

    @Test
    void doesNotCountMarkdownWrappedSourceAsValidUrl() {
        Map<String, Object> item = item("UNVERIFIED", true, true, false, false);
        item.put("sourceUrl", "[https://example.org/source](https://example.org/source)");

        Map<String, Object> quality = ItineraryDataQuality.assessDay(List.of(item));

        assertEquals(20, quality.get("score"));
        assertTrue(((List<?>) quality.get("warnings")).contains("SOURCE_MISSING"));
    }

    private static Map<String, Object> item(
            String status, boolean source, boolean coordinates,
            boolean duration, boolean cost) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("dataStatus", status);
        item.put("sourceUrl", source ? "https://example.org/source" : null);
        item.put("latitude", coordinates ? -6.1 : null);
        item.put("longitude", coordinates ? 39.2 : null);
        item.put("estimatedDurationMinutes", duration ? 60 : null);
        item.put("estimatedCost", cost ? BigDecimal.ZERO : null);
        item.put("currency", cost ? "TZS" : null);
        return item;
    }
}
