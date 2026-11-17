package com.aitravelplanner.itinerary;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ItineraryGeographicPlannerTest {

    @Test
    void groupsThreeNearbyStoneTownAttractionsOnTheSameDay() {
        List<Map<String, Object>> candidates = List.of(
                item("Forodhani Gardens", -6.160680, 39.188616, "STONE_TOWN"),
                item("House of Wonders", -6.160914, 39.189591, "STONE_TOWN"),
                item("Old Fort of Zanzibar", -6.161390, 39.189170, "STONE_TOWN"),
                item("Nungwi Beach", -5.7260, 39.2980, "NUNGWI")
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 3, 3);

        assertEquals(Set.of(
                "Forodhani Gardens",
                "House of Wonders",
                "Old Fort of Zanzibar"
        ), Set.copyOf(titles(days.getFirst())));
        assertEquals(List.of("Nungwi Beach"), titles(days.get(1)));
        assertEquals(3, days.size());
        days.forEach(day -> assertTrue(day.size() <= 3));
    }

    @Test
    void keepsNearbyLocationsTogetherAndSeparatesFarLocations() {
        List<Map<String, Object>> candidates = List.of(
                item("A - Stone Town", -6.1600, 39.1900),
                item("B - North Coast", -5.9000, 39.3000),
                item("C - Nearby site", -6.1610, 39.1910),
                item("D - Far site", -6.0000, 39.5000)
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 2, 3);

        assertEquals(List.of("A - Stone Town", "C - Nearby site"),
                titles(days.get(0)));
        assertEquals(List.of("B - North Coast", "D - Far site"),
                titles(days.get(1)));
    }

    @Test
    void keepsDifferentNamedAreasOnSeparateDaysEvenWhenCoordinatesAreClose() {
        List<Map<String, Object>> candidates = List.of(
                item("A - Stone Town", -6.1600, 39.1900, "STONE_TOWN"),
                item("B - Nungwi", -6.1601, 39.1901, "NUNGWI")
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 2, 3);

        assertEquals(List.of("A - Stone Town"), titles(days.get(0)));
        assertEquals(List.of("B - Nungwi"), titles(days.get(1)));
    }

    @Test
    void preservesAllEntriesAndUsesStableOrderWhenCoordinatesAreMissing() {
        List<Map<String, Object>> candidates = List.of(
                item("A", null, null),
                item("B", null, null),
                item("C", null, null),
                item("D", null, null)
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 4, 3);

        assertEquals(List.of(List.of("A"), List.of("B"), List.of("C"), List.of("D")),
                days.stream().map(ItineraryGeographicPlannerTest::titles).toList());
    }

    @Test
    void putsEntriesWithoutCoordinatesAfterTheGeographicRoute() {
        List<Map<String, Object>> candidates = List.of(
                item("Unknown", null, null),
                item("Located A", 0.0, 0.0),
                item("Located B", 0.0, 0.01)
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 1, 3);

        assertEquals(List.of("Located A", "Located B", "Unknown"), titles(days.getFirst()));
    }

    @Test
    void ignoresOutOfRangeCoordinatesWithoutDroppingItems() {
        List<Map<String, Object>> candidates = List.of(
                item("Invalid", 120.0, 200.0),
                item("Valid", 0.0, 0.0)
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 1, 3);

        assertEquals(List.of("Valid", "Invalid"), titles(days.getFirst()));
    }

    @Test
    void rejectsInvalidDayCount() {
        assertThrows(IllegalArgumentException.class,
                () -> ItineraryGeographicPlanner.plan(List.of(), 0, 3));
    }

    @Test
    void rejectsInvalidDailyCapacity() {
        assertThrows(IllegalArgumentException.class,
                () -> ItineraryGeographicPlanner.plan(List.of(), 2, 0));
    }

    @Test
    void neverMixesGeolocatedStoneTownWithUnlocatedPaje() {
        List<Map<String, Object>> candidates = List.of(
                item("Stone Town attraction", -6.1600, 39.1900, "STONE_TOWN"),
                item("Paje activity", null, null, "PAJE")
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 2, 3);

        assertEquals(List.of("Stone Town attraction"), titles(days.get(0)));
        assertEquals(List.of("Paje activity"), titles(days.get(1)));
    }

    @Test
    void neverMixesUnlocatedStoneTownActivityWithGeolocatedJozani() {
        List<Map<String, Object>> candidates = List.of(
                item("Stone Town guided visit", null, null, "STONE_TOWN"),
                item("Jozani Forest", -6.26755, 39.41111, "JOZANI")
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 2, 3);

        assertEquals(List.of("Jozani Forest"), titles(days.get(0)));
        assertEquals(List.of("Stone Town guided visit"), titles(days.get(1)));
    }

    @Test
    void neverMixesNungwiAndOffshoreWestOnTheSameDay() {
        List<Map<String, Object>> candidates = List.of(
                item("Nungwi Beach", -5.7259, 39.2986, "NUNGWI"),
                item("Nakupenda Sandbank", null, null, "OFFSHORE_WEST")
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 2, 3);

        assertEquals(List.of("Nungwi Beach"), titles(days.get(0)));
        assertEquals(List.of("Nakupenda Sandbank"), titles(days.get(1)));
    }

    @Test
    void allowsSameAreaEntriesToShareDayWithinCapacity() {
        List<Map<String, Object>> candidates = List.of(
                item("Forodhani Gardens", -6.160680, 39.188616, "STONE_TOWN"),
                item("Stone Town guided visit", null, null, "STONE_TOWN"),
                item("Old Fort", -6.161390, 39.189170, "STONE_TOWN")
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 1, 3);

        assertEquals(3, days.getFirst().size());
        assertEquals(Set.of("Forodhani Gardens", "Stone Town guided visit", "Old Fort"),
                Set.copyOf(titles(days.getFirst())));
    }

    @Test
    void keepsUnknownAreaEntriesSeparateFromNamedAreasAndOrdersThemDeterministically() {
        List<Map<String, Object>> candidates = List.of(
                item("Unknown B", null, null),
                item("Stone Town", -6.1600, 39.1900, "STONE_TOWN"),
                item("Unknown A", null, null)
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 2, 3);

        assertEquals(List.of("Stone Town"), titles(days.get(0)));
        assertEquals(List.of("Unknown A", "Unknown B"), titles(days.get(1)));
    }

    @Test
    void prioritizesPreferenceMatchedGroupsWithoutMixingGeographicAreas() {
        Map<String, Object> culture = item("Stone Town heritage", -6.1600, 39.1900, "STONE_TOWN");
        culture.put("preferenceScore", 100);
        Map<String, Object> beach = item("Nungwi beach", -5.7259, 39.2986, "NUNGWI");
        beach.put("preferenceScore", 40);

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(List.of(beach, culture), 2, 3);

        assertEquals(List.of("Stone Town heritage"), titles(days.getFirst()));
        assertEquals(List.of("Nungwi beach"), titles(days.get(1)));
    }

    @Test
    void keepsUnlocatedSuggestionsAfterLocatedGroupsEvenWhenTheirTitlesSortFirst() {
        Map<String, Object> unlocated = item("A - Unknown location", null, null);
        unlocated.put("preferenceScore", 100);
        Map<String, Object> located = item("Z - Located attraction", -6.1600, 39.1900, "STONE_TOWN");
        located.put("preferenceScore", 40);

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(List.of(unlocated, located), 2, 3);

        assertEquals(List.of("Z - Located attraction"), titles(days.getFirst()));
        assertEquals(List.of("A - Unknown location"), titles(days.get(1)));
    }


    @Test
    void prefersBetterDocumentedGroupWhenPreferenceScoresAreEqual() {
        Map<String, Object> wellDocumented = item("Well documented", -6.1600, 39.1900, "STONE_TOWN");
        wellDocumented.put("preferenceScore", 100);
        wellDocumented.put("documentationScore", 80);
        Map<String, Object> poorlyDocumented = item("Poorly documented", -5.7259, 39.2986, "NUNGWI");
        poorlyDocumented.put("preferenceScore", 100);
        poorlyDocumented.put("documentationScore", 20);

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(List.of(poorlyDocumented, wellDocumented), 2, 3);

        assertEquals(List.of("Well documented"), titles(days.getFirst()));
        assertEquals(List.of("Poorly documented"), titles(days.get(1)));
    }

    @Test
    void preferenceMatchRemainsMoreImportantThanDocumentationCompleteness() {
        Map<String, Object> preferenceMatch = item("Preference match", -6.1600, 39.1900, "STONE_TOWN");
        preferenceMatch.put("preferenceScore", 100);
        preferenceMatch.put("documentationScore", 0);
        Map<String, Object> documentationMatch = item("Documentation match", -5.7259, 39.2986, "NUNGWI");
        documentationMatch.put("preferenceScore", 40);
        documentationMatch.put("documentationScore", 100);

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(List.of(documentationMatch, preferenceMatch), 2, 3);

        assertEquals(List.of("Preference match"), titles(days.getFirst()));
        assertEquals(List.of("Documentation match"), titles(days.get(1)));
    }

    @Test
    void reportsCandidatesThatCannotFitWithinDailyCapacity() {
        List<Map<String, Object>> candidates = List.of(
                item("A", 0.0, 0.0),
                item("B", 10.0, 10.0),
                item("C", 20.0, 20.0));

        ItineraryGeographicPlanner.PlanningResult result =
                ItineraryGeographicPlanner.planWithUnplanned(candidates, 1, 2);

        assertEquals(2, result.days().stream().mapToInt(List::size).sum());
        assertEquals(List.of("C"), titles(result.unplannedItems()));
    }

    private static Map<String, Object> item(String title, Double latitude, Double longitude) {
        return item(title, latitude, longitude, null);
    }

    private static Map<String, Object> item(
            String title, Double latitude, Double longitude, String geographicArea) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("title", title);
        item.put("latitude", latitude);
        item.put("longitude", longitude);
        item.put("geographicArea", geographicArea);
        return item;
    }

    private static List<String> titles(List<Map<String, Object>> items) {
        return items.stream().map(item -> (String) item.get("title")).toList();
    }
}
