package com.aitravelplanner.itinerary;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Measures how well itinerary catalogue entries are documented.
 * This is a data-completeness indicator, not a rating of the experience itself.
 */
final class ItineraryDataQuality {
    private static final int SOURCE_WEIGHT = 20;
    private static final int VERIFIED_WEIGHT = 30;
    private static final int COORDINATES_WEIGHT = 20;
    private static final int DURATION_WEIGHT = 15;
    private static final int COST_WEIGHT = 15;
    private static final List<String> VERIFICATION_STATUSES = List.of(
            "VERIFIED", "PARTIALLY_VERIFIED", "UNVERIFIED", "REJECTED", "UNKNOWN"
    );

    private ItineraryDataQuality() {
    }

    static Map<String, Object> assessDay(List<Map<String, Object>> items) {
        List<String> warnings = new ArrayList<>();
        if (items.isEmpty()) {
            warnings.add("NO_CATALOG_ITEMS");
            return result(0, "NO_DATA", 0, warnings, items);
        }

        int totalScore = 0;
        Set<String> uniqueWarnings = new LinkedHashSet<>();
        for (Map<String, Object> item : items) {
            int itemScore = 0;
            if (isHttpUrl(item.get("sourceUrl"))) {
                itemScore += SOURCE_WEIGHT;
            } else {
                uniqueWarnings.add("SOURCE_MISSING");
            }

            if ("VERIFIED".equalsIgnoreCase(String.valueOf(item.get("dataStatus")))) {
                itemScore += VERIFIED_WEIGHT;
            } else {
                uniqueWarnings.add("NOT_VERIFIED");
            }

            if (hasValidCoordinates(item)) {
                itemScore += COORDINATES_WEIGHT;
            } else {
                uniqueWarnings.add("COORDINATES_MISSING");
            }

            if (item.get("estimatedDurationMinutes") instanceof Number duration
                    && duration.intValue() > 0) {
                itemScore += DURATION_WEIGHT;
            } else {
                uniqueWarnings.add("DURATION_MISSING");
            }

            if (item.get("estimatedCost") instanceof Number cost
                    && cost.doubleValue() >= 0 && hasText(item.get("currency"))) {
                itemScore += COST_WEIGHT;
            } else {
                uniqueWarnings.add("COST_MISSING");
            }
            totalScore += itemScore;
        }

        int score = (int) Math.round(totalScore / (double) items.size());
        String status = score >= 80 ? "WELL_DOCUMENTED"
                : score >= 50 ? "PARTIAL" : "LOW";
        warnings.addAll(uniqueWarnings);
        return result(score, status, items.size(), warnings, items);
    }

    static Map<String, Object> assessItinerary(List<Map<String, Object>> days) {
        int weightedScore = 0;
        int itemCount = 0;
        int daysWithoutItems = 0;
        Map<String, Integer> statusCounts = emptyStatusCounts();
        for (Map<String, Object> day : days) {
            @SuppressWarnings("unchecked")
            Map<String, Object> quality = (Map<String, Object>) day.get("dataQuality");
            int count = ((Number) quality.get("itemCount")).intValue();
            if (count == 0) {
                daysWithoutItems++;
            } else {
                weightedScore += ((Number) quality.get("score")).intValue() * count;
                itemCount += count;
            }
            @SuppressWarnings("unchecked")
            Map<String, Number> dayStatusCounts =
                    (Map<String, Number>) quality.get("verificationStatusCounts");
            if (dayStatusCounts != null) {
                dayStatusCounts.forEach((status, value) ->
                        statusCounts.merge(status, value.intValue(), Integer::sum));
            }
        }
        int score = itemCount == 0 ? 0 : (int) Math.round(weightedScore / (double) itemCount);
        String status = itemCount == 0 ? "NO_DATA"
                : score >= 80 ? "WELL_DOCUMENTED" : score >= 50 ? "PARTIAL" : "LOW";

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("score", score);
        summary.put("status", status);
        summary.put("itemCount", itemCount);
        summary.put("daysWithoutItems", daysWithoutItems);
        summary.put("verificationStatusCounts", statusCounts);
        summary.put("metric", "DATA_COMPLETENESS_NOT_EXPERIENCE_QUALITY");
        return summary;
    }

    private static Map<String, Object> result(
            int score, String status, int itemCount, List<String> warnings,
            List<Map<String, Object>> items) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("score", score);
        result.put("status", status);
        result.put("itemCount", itemCount);
        result.put("warnings", warnings);
        result.put("verificationStatusCounts", verificationStatusCounts(items));
        result.put("metric", "DATA_COMPLETENESS_NOT_EXPERIENCE_QUALITY");
        return result;
    }

    private static Map<String, Integer> verificationStatusCounts(List<Map<String, Object>> items) {
        Map<String, Integer> counts = emptyStatusCounts();
        for (Map<String, Object> item : items) {
            String status = item.get("dataStatus") == null
                    ? "UNKNOWN" : String.valueOf(item.get("dataStatus")).trim().toUpperCase();
            if (!counts.containsKey(status)) {
                status = "UNKNOWN";
            }
            counts.merge(status, 1, Integer::sum);
        }
        return counts;
    }

    private static Map<String, Integer> emptyStatusCounts() {
        Map<String, Integer> counts = new LinkedHashMap<>();
        VERIFICATION_STATUSES.forEach(status -> counts.put(status, 0));
        return counts;
    }

    private static boolean hasValidCoordinates(Map<String, Object> item) {
        if (!(item.get("latitude") instanceof Number latitude)
                || !(item.get("longitude") instanceof Number longitude)) {
            return false;
        }
        double lat = latitude.doubleValue();
        double lon = longitude.doubleValue();
        return Double.isFinite(lat) && Double.isFinite(lon)
                && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
    }

    private static boolean isHttpUrl(Object value) {
        if (!hasText(value)) {
            return false;
        }
        try {
            URI uri = new URI(String.valueOf(value).trim());
            String scheme = uri.getScheme();
            return uri.isAbsolute()
                    && uri.getHost() != null
                    && ("http".equalsIgnoreCase(scheme) || "https".equalsIgnoreCase(scheme));
        } catch (URISyntaxException exception) {
            return false;
        }
    }

    private static boolean hasText(Object value) {
        return value != null && !String.valueOf(value).isBlank();
    }
}
