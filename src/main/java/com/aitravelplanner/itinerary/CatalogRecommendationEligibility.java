package com.aitravelplanner.itinerary;

import com.aitravelplanner.catalog.CatalogSourceTransparency;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Conservative gate for itinerary recommendations.
 * A source candidate is not factual verification: the catalog item must also
 * be VERIFIED by field-level verification history and have usable planning data.
 */
final class CatalogRecommendationEligibility {
    private CatalogRecommendationEligibility() {
    }

    static Evaluation evaluate(Map<String, Object> item) {
        List<String> reasons = new ArrayList<>();

        if (!"VERIFIED".equalsIgnoreCase(value(item.get("dataStatus")))) {
            reasons.add("CATALOG_ITEM_NOT_VERIFIED");
        }

        Object sourceQuality = CatalogSourceTransparency.describe(item).get("sourceQuality");
        if (!"ITEM_SPECIFIC_PRIMARY_CANDIDATE".equals(sourceQuality)) {
            reasons.add("OFFICIAL_ITEM_SPECIFIC_SOURCE_REQUIRED");
        }

        if (!validCoordinates(item)) {
            reasons.add("VALID_COORDINATES_REQUIRED");
        }

        if (!(item.get("estimatedDurationMinutes") instanceof Number duration)
                || duration.intValue() <= 0) {
            reasons.add("VERIFIED_DURATION_REQUIRED");
        }

        if (!hasText(item.get("title")) || !hasText(item.get("category"))) {
            reasons.add("NAME_AND_CATEGORY_REQUIRED");
        }

        return new Evaluation(reasons.isEmpty(), List.copyOf(reasons));
    }

    private static boolean validCoordinates(Map<String, Object> item) {
        if (!(item.get("latitude") instanceof Number latitude)
                || !(item.get("longitude") instanceof Number longitude)) {
            return false;
        }
        double lat = latitude.doubleValue();
        double lon = longitude.doubleValue();
        return Double.isFinite(lat) && Double.isFinite(lon)
                && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
    }

    private static boolean hasText(Object value) {
        return value != null && !String.valueOf(value).isBlank();
    }

    private static String value(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    record Evaluation(boolean eligible, List<String> reasons) {
    }
}
