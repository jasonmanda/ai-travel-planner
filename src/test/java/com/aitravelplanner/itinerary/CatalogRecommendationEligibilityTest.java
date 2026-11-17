package com.aitravelplanner.itinerary;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CatalogRecommendationEligibilityTest {

    @Test
    void acceptsOnlyVerifiedItemsWithOfficialSpecificSourceAndPlanningFields() {
        Map<String, Object> item = validItem();

        CatalogRecommendationEligibility.Evaluation result =
                CatalogRecommendationEligibility.evaluate(item);

        assertTrue(result.eligible());
        assertEquals(0, result.reasons().size());
    }

    @Test
    void excludesUnverifiedAndPartiallyVerifiedItems() {
        Map<String, Object> item = validItem();
        item.put("dataStatus", "PARTIALLY_VERIFIED");

        CatalogRecommendationEligibility.Evaluation result =
                CatalogRecommendationEligibility.evaluate(item);

        assertFalse(result.eligible());
        assertTrue(result.reasons().contains("CATALOG_ITEM_NOT_VERIFIED"));
    }

    @Test
    void excludesItemsWithDestinationWideOrSecondarySources() {
        Map<String, Object> item = validItem();
        item.put("sourceScope", "DESTINATION_GENERAL");

        CatalogRecommendationEligibility.Evaluation result =
                CatalogRecommendationEligibility.evaluate(item);

        assertFalse(result.eligible());
        assertTrue(result.reasons().contains("OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED"));
    }

    @Test
    void excludesItemsWithoutCoordinatesOrDuration() {
        Map<String, Object> item = validItem();
        item.put("latitude", null);
        item.put("estimatedDurationMinutes", null);

        CatalogRecommendationEligibility.Evaluation result =
                CatalogRecommendationEligibility.evaluate(item);

        assertFalse(result.eligible());
        assertTrue(result.reasons().contains("VALID_COORDINATES_REQUIRED"));
        assertTrue(result.reasons().contains("VERIFIED_DURATION_REQUIRED"));
    }

    @Test
    void excludesMalformedCoordinatesAndNonPositiveDuration() {
        Map<String, Object> item = validItem();
        item.put("latitude", 91.0);
        item.put("estimatedDurationMinutes", 0);

        CatalogRecommendationEligibility.Evaluation result =
                CatalogRecommendationEligibility.evaluate(item);

        assertFalse(result.eligible());
        assertTrue(result.reasons().contains("VALID_COORDINATES_REQUIRED"));
        assertTrue(result.reasons().contains("VERIFIED_DURATION_REQUIRED"));
    }

    @Test
    void excludesOfficialHomepageEvenWhenMarkedItemSpecific() {
        Map<String, Object> item = validItem();
        item.put("sourceUrl", "https://example.org/");

        CatalogRecommendationEligibility.Evaluation result =
                CatalogRecommendationEligibility.evaluate(item);

        assertFalse(result.eligible());
        assertTrue(result.reasons().contains("OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED"));
    }

    @Test
    void excludesOperatorPrimarySourceEvenWhenOtherFieldsAreValid() {
        Map<String, Object> item = validItem();
        item.put("sourceType", "OPERATOR_PRIMARY");
        item.put("sourceUrl", "https://safariblue.net/tours/original-experience/");

        CatalogRecommendationEligibility.Evaluation result =
                CatalogRecommendationEligibility.evaluate(item);

        assertFalse(result.eligible());
        assertTrue(result.reasons().contains("OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED"));
    }


    private static Map<String, Object> validItem() {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("title", "Example attraction");
        item.put("category", "CULTURE");
        item.put("dataStatus", "VERIFIED");
        item.put("latitude", -6.16);
        item.put("longitude", 39.19);
        item.put("estimatedDurationMinutes", 90);
        item.put("sourceName", "Official attraction page");
        item.put("sourceUrl", "https://example.org/attraction/example");
        item.put("sourceType", "OFFICIAL");
        item.put("sourceScope", "ITEM_SPECIFIC");
        return item;
    }
}
