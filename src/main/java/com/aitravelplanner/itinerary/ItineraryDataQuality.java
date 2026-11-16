package com.aitravelplanner.itinerary;

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
    private static final int TOTAL_WEIGHT = 100;

    private ItineraryDataQuality() {
    }

    static Map<String, Object> assessDay(List<Map<String, Object>> items) {
        List<String> warnings = new ArrayList<>();
        if (items.isEmpty()) {
            warnings.add("NO_CATALOG_ITEMS");
            return result(0, "NO_DATA", 0, warnings);
        }

        int totalScore = 0;
        Set<String> uniqueWarnings = new LinkedHashSet<>();
        for (Map<String, Object> item : items) {
            int itemScore = 0;
            if (hasText(item.get("sourceUrl"))) {
                itemScore += SOURCE_WEIGHT;
            } else {
                uniqueWarnings.add("SOURCE_MISSING");
            }

            if ("VERIFIED".equalsIgnoreCase(String.valueOf(item.get("dataStatus")))) {
                itemScore += VERIFIED_WEIGHT;
            } else {
                uniqueWarnings.add("NOT_VERIFIED");
            }

            if (item.get("latitude") instanceof Number
                    && item.get("longitude") instanceof Number) {
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
        return result(score, status, items.size(), warnings);
    }

    static Map<String, Object> assessItinerary(List<Map<String, Object>> days) {
        int weightedScore = 0;
        int itemCount = 0;
        int daysWithoutItems = 0;
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
        }
        int score = itemCount == 0 ? 0 : (int) Math.round(weightedScore / (double) itemCount);
        String status = itemCount == 0 ? "NO_DATA"
                : score >= 80 ? "WELL_DOCUMENTED" : score >= 50 ? "PARTIAL" : "LOW";

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("score", score);
        summary.put("status", status);
        summary.put("itemCount", itemCount);
        summary.put("daysWithoutItems", daysWithoutItems);
        summary.put("metric", "DATA_COMPLETENESS_NOT_EXPERIENCE_QUALITY");
        return summary;
    }

    private static Map<String, Object> result(
            int score, String status, int itemCount, List<String> warnings) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("score", score);
        result.put("status", status);
        result.put("itemCount", itemCount);
        result.put("warnings", warnings);
        result.put("metric", "DATA_COMPLETENESS_NOT_EXPERIENCE_QUALITY");
        return result;
    }

    private static boolean hasText(Object value) {
        return value != null && !String.valueOf(value).isBlank();
    }
}
