package com.aitravelplanner.itinerary;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ItineraryGeographicPlannerTest {

    @Test
    void groupsThreeNearbyStoneTownAttractionsOnTheSameDay() {
        List<Map<String, Object>> candidates = List.of(
                item("Forodhani Gardens", -6.160680, 39.188616),
                item("House of Wonders", -6.160914, 39.189591),
                item("Old Fort of Zanzibar", -6.161390, 39.189170),
                item("Nungwi Beach", -5.7260, 39.2980)
        );

        List<List<Map<String, Object>>> days =
                ItineraryGeographicPlanner.plan(candidates, 3, 3);

        assertEquals(List.of(
                "Forodhani Gardens",
                "House of Wonders",
                "Old Fort of Zanzibar"
        ), titles(days.getFirst()));
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

    private static Map<String, Object> item(String title, Double latitude, Double longitude) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("title", title);
        item.put("latitude", latitude);
        item.put("longitude", longitude);
        return item;
    }

    private static List<String> titles(List<Map<String, Object>> items) {
        return items.stream().map(item -> (String) item.get("title")).toList();
    }
}
