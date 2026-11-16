package com.aitravelplanner.itinerary;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

/**
 * Builds daily geographic clusters. Nearby entries stay together instead of
 * being split across the trip by a global balancing pass.
 */
final class ItineraryGeographicPlanner {
    private static final double EARTH_RADIUS_KM = 6371.0088;
    static final double MAX_CLUSTER_DISTANCE_KM = 2.0;

    private ItineraryGeographicPlanner() {
    }

    static List<List<Map<String, Object>>> plan(
            List<Map<String, Object>> candidates,
            int dayCount,
            int maxItemsPerDay) {

        if (dayCount < 1) {
            throw new IllegalArgumentException("dayCount must be greater than zero");
        }
        if (maxItemsPerDay < 1) {
            throw new IllegalArgumentException("maxItemsPerDay must be greater than zero");
        }

        List<Map<String, Object>> remaining = new ArrayList<>();
        List<Map<String, Object>> withoutCoordinates = new ArrayList<>();
        for (Map<String, Object> candidate : candidates) {
            if (hasValidCoordinates(candidate)) {
                remaining.add(candidate);
            } else {
                withoutCoordinates.add(candidate);
            }
        }

        Comparator<Map<String, Object>> byRecommendationThenTitle =
                Comparator.<Map<String, Object>>comparingInt(ItineraryGeographicPlanner::preferenceScore)
                        .reversed()
                        .thenComparing(Comparator.comparingInt(
                                ItineraryGeographicPlanner::documentationScore).reversed())
                        .thenComparing(item -> String.valueOf(item.get("title")));
        remaining.sort(byRecommendationThenTitle);
        withoutCoordinates.sort(byRecommendationThenTitle);
        List<List<Map<String, Object>>> groups = new ArrayList<>();

        while (!remaining.isEmpty()) {
            List<Map<String, Object>> group = new ArrayList<>();
            Map<String, Object> seed = remaining.removeFirst();
            group.add(seed);

            while (group.size() < maxItemsPerDay && !remaining.isEmpty()) {
                Map<String, Object> nearest = remaining.stream()
                        .map(candidate -> Map.entry(candidate, minimumDistanceKm(group, candidate)))
                        .filter(entry -> entry.getValue() <= MAX_CLUSTER_DISTANCE_KM)
                        .min(Comparator
                                .comparingDouble((Map.Entry<Map<String, Object>, Double> entry) -> entry.getValue())
                                .thenComparing(Comparator.comparingInt(
                                        (Map.Entry<Map<String, Object>, Double> entry) ->
                                                preferenceScore(entry.getKey())).reversed())
                                .thenComparing(Comparator.comparingInt(
                                        (Map.Entry<Map<String, Object>, Double> entry) ->
                                                documentationScore(entry.getKey())).reversed())
                                .thenComparing(entry -> String.valueOf(entry.getKey().get("title"))))
                        .map(Map.Entry::getKey)
                        .orElse(null);

                if (nearest == null) {
                    break;
                }
                group.add(nearest);
                remaining.remove(nearest);
            }
            group.sort(byRecommendationThenTitle);
            groups.add(group);
        }

        // Entries without coordinates are retained as singleton groups. Their
        // location is unknown, so they are never treated as geographically close.
        for (Map<String, Object> item : withoutCoordinates) {
            groups.add(List.of(item));
        }
        List<List<Map<String, Object>>> days = new ArrayList<>(dayCount);
        for (int i = 0; i < dayCount; i++) {
            days.add(new ArrayList<>());
        }

        int capacity = dayCount * maxItemsPerDay;
        int placed = 0;
        for (List<Map<String, Object>> group : groups) {
            if (placed + group.size() > capacity) {
                continue;
            }
            int targetDay = -1;
            for (int day = 0; day < days.size(); day++) {
                if (days.get(day).size() + group.size() <= maxItemsPerDay
                        && compatibleDayArea(days.get(day), group)
                        && (targetDay == -1
                        || days.get(day).size() < days.get(targetDay).size())) {
                    targetDay = day;
                }
            }
            if (targetDay == -1) {
                continue;
            }
            days.get(targetDay).addAll(group);
            placed += group.size();
        }

        return days;
    }

    private static double minimumDistanceKm(
            List<Map<String, Object>> group, Map<String, Object> candidate) {
        return group.stream()
                .filter(item -> compatibleAreas(item, candidate))
                .mapToDouble(item -> distanceKm(item, candidate))
                .min()
                .orElse(Double.POSITIVE_INFINITY);
    }

    private static boolean compatibleAreas(Map<String, Object> first, Map<String, Object> second) {
        return sameArea(first.get("geographicArea"), second.get("geographicArea"));
    }

    /**
     * A day is reserved for one geographic area. Null is treated as its own
     * unknown area: unknown-location entries can share with each other, but
     * are never mixed with a named area without evidence of compatibility.
     */
    private static boolean compatibleDayArea(
            List<Map<String, Object>> day, List<Map<String, Object>> group) {
        if (day.isEmpty() || group.isEmpty()) {
            return true;
        }
        Object targetArea = group.getFirst().get("geographicArea");
        return day.stream().allMatch(item -> sameArea(item.get("geographicArea"), targetArea));
    }

    private static boolean sameArea(Object firstArea, Object secondArea) {
        if (firstArea == null || secondArea == null) {
            return firstArea == null && secondArea == null;
        }
        return String.valueOf(firstArea).trim().equalsIgnoreCase(String.valueOf(secondArea).trim());
    }

    private static int preferenceScore(Map<String, Object> item) {
        Object score = item.get("preferenceScore");
        return score instanceof Number number ? number.intValue() : 70;
    }

    private static int documentationScore(Map<String, Object> item) {
        Object score = item.get("documentationScore");
        return score instanceof Number number ? number.intValue() : 0;
    }

    private static boolean hasValidCoordinates(Map<String, Object> item) {
        Double latitude = coordinate(item.get("latitude"));
        Double longitude = coordinate(item.get("longitude"));
        return latitude != null && longitude != null
                && latitude >= -90 && latitude <= 90
                && longitude >= -180 && longitude <= 180;
    }

    private static Double coordinate(Object value) {
        return value instanceof Number number ? number.doubleValue() : null;
    }

    private static double distanceKm(Map<String, Object> first, Map<String, Object> second) {
        double lat1 = Math.toRadians(coordinate(first.get("latitude")));
        double lon1 = Math.toRadians(coordinate(first.get("longitude")));
        double lat2 = Math.toRadians(coordinate(second.get("latitude")));
        double lon2 = Math.toRadians(coordinate(second.get("longitude")));

        double latDelta = lat2 - lat1;
        double lonDelta = lon2 - lon1;
        double a = Math.pow(Math.sin(latDelta / 2), 2)
                + Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(lonDelta / 2), 2);
        return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(Math.min(1, a)));
    }
}
