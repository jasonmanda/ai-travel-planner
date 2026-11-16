package com.aitravelplanner.itinerary;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ItineraryPreferenceScorerTest {

    @Test
    void matchesCultureInterestToHeritageCategory() {
        Map<String, Object> item = item("HERITAGE");

        ItineraryPreferenceScorer.apply(item, List.of("culture"), null);

        assertEquals(100, item.get("preferenceScore"));
        assertTrue(((String) item.get("preferenceReason")).contains("correspond"));
    }

    @Test
    void matchesFrenchNatureInterestToNatureCategory() {
        Map<String, Object> item = item("NATURE");

        ItineraryPreferenceScorer.apply(item, List.of("forêt et nature"), null);

        assertEquals(100, item.get("preferenceScore"));
    }

    @Test
    void usesTravelStyleWhenNoInterestsAreProvided() {
        Map<String, Object> item = item("BEACH");

        ItineraryPreferenceScorer.apply(item, List.of(), "Détente");

        assertEquals(100, item.get("preferenceScore"));
    }

    @Test
    void keepsNonMatchingSuggestionsWithLowerRelevanceScore() {
        Map<String, Object> item = item("BEACH");

        ItineraryPreferenceScorer.apply(item, List.of("culture"), null);

        assertEquals(40, item.get("preferenceScore"));
        assertTrue(((String) item.get("preferenceReason")).contains("conservée"));
    }

    @Test
    void staysNeutralWhenNoPreferenceIsProvided() {
        Map<String, Object> item = item("NATURE");

        ItineraryPreferenceScorer.apply(item, List.of(), null);

        assertEquals(70, item.get("preferenceScore"));
    }

    private static Map<String, Object> item(String category) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("category", category);
        return item;
    }
}
