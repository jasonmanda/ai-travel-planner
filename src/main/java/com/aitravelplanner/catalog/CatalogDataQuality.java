package com.aitravelplanner.catalog;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Measures catalogue documentation completeness. It does not rate the
 * experience, prove factual accuracy, or imply current availability.
 */
public final class CatalogDataQuality {
    private CatalogDataQuality() {
    }

    public static Map<String, Object> assess(Map<String, Object> item) {
        int score = 0;
        List<String> warnings = new ArrayList<>();

        if (isHttpUrl(item.get("sourceUrl"))) {
            score += 20;
        } else {
            warnings.add("SOURCE_MISSING");
        }

        if ("VERIFIED".equalsIgnoreCase(String.valueOf(item.get("dataStatus")))) {
            score += 30;
        } else {
            warnings.add("NOT_VERIFIED");
        }

        if (hasValidCoordinates(item)) {
            score += 20;
        } else {
            warnings.add("COORDINATES_MISSING");
        }

        if (item.get("estimatedDurationMinutes") instanceof Number duration
                && duration.intValue() > 0) {
            score += 15;
        } else {
            warnings.add("DURATION_MISSING");
        }

        if (item.get("estimatedCost") instanceof Number cost
                && cost.doubleValue() >= 0 && hasText(item.get("currency"))) {
            score += 15;
        } else {
            warnings.add("COST_MISSING");
        }

        String status = score >= 80 ? "WELL_DOCUMENTED"
                : score >= 50 ? "PARTIAL" : "LOW";

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("score", score);
        result.put("status", status);
        result.put("warnings", warnings);
        result.put("metric", "DATA_COMPLETENESS_NOT_EXPERIENCE_QUALITY");
        return result;
    }

    private static boolean hasValidCoordinates(Map<String, Object> item) {
        if (!(item.get("latitude") instanceof Number latitude)
                || !(item.get("longitude") instanceof Number longitude)) {
            return false;
        }
        return latitude.doubleValue() >= -90 && latitude.doubleValue() <= 90
                && longitude.doubleValue() >= -180 && longitude.doubleValue() <= 180;
    }

    private static boolean isHttpUrl(Object value) {
        if (!hasText(value)) {
            return false;
        }
        try {
            URI uri = new URI(String.valueOf(value).trim());
            String scheme = uri.getScheme();
            return uri.isAbsolute() && uri.getHost() != null
                    && ("http".equalsIgnoreCase(scheme) || "https".equalsIgnoreCase(scheme));
        } catch (URISyntaxException exception) {
            return false;
        }
    }

    private static boolean hasText(Object value) {
        return value != null && !String.valueOf(value).isBlank();
    }
}
