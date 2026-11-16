package com.aitravelplanner.itinerary;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

/**
 * Orders geolocated catalog entries by nearest-neighbour distance, then
 * spreads the resulting route across the trip. Entries without valid
 * coordinates are retained after the geolocated entries in stable order.
 */
final class ItineraryGeographicPlanner {
    private static final double EARTH_RADIUS_KM = 6371.0088;

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

        List<Map<String, Object>> ordered = new ArrayList<>(candidates.size());
        if (!remaining.isEmpty()) {
            remaining.sort(Comparator.comparing(item -> String.valueOf(item.get("title"))));
            Map<String, Object> current = remaining.removeFirst();
            ordered.add(current);

            while (!remaining.isEmpty()) {
                Map<String, Object> previous = current;
                current = remaining.stream()
                        .min(Comparator
                                .comparingDouble((Map<String, Object> item) -> distanceKm(previous, item))
                                .thenComparing(item -> String.valueOf(item.get("title"))))
                        .orElseThrow();
                remaining.remove(current);
                ordered.add(current);
            }
        }

        ordered.addAll(withoutCoordinates);
        return ItineraryDistribution.distribute(ordered, dayCount, maxItemsPerDay);
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
