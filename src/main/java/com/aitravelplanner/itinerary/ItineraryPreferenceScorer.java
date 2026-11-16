package com.aitravelplanner.itinerary;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Deterministic catalogue-category matching. This is a relevance signal, not
 * an assessment of experience quality or factual reliability.
 */
final class ItineraryPreferenceScorer {
    private static final int NEUTRAL_SCORE = 70;
    private static final int MATCH_SCORE = 100;
    private static final int MISMATCH_SCORE = 40;

    private ItineraryPreferenceScorer() {
    }

    static Map<String, Object> apply(
            Map<String, Object> item, List<String> interests, String travelStyle) {
        Set<String> expected = new LinkedHashSet<>();
        if (interests != null) {
            interests.stream().filter(ItineraryPreferenceScorer::hasText)
                    .forEach(value -> expected.addAll(categoriesFor(value)));
        }
        if (hasText(travelStyle)) {
            expected.addAll(categoriesForStyle(travelStyle));
        }

        String category = normalize(String.valueOf(item.getOrDefault("category", "")));
        if (expected.isEmpty()) {
            item.put("preferenceScore", NEUTRAL_SCORE);
            item.put("preferenceReason", "Aucune préférence exploitable renseignée : classement neutre.");
        } else if (expected.contains(category)) {
            item.put("preferenceScore", MATCH_SCORE);
            item.put("preferenceReason", "La catégorie " + item.get("category")
                    + " correspond aux centres d’intérêt ou au style de voyage renseignés.");
        } else {
            item.put("preferenceScore", MISMATCH_SCORE);
            item.put("preferenceReason", "La catégorie " + item.get("category")
                    + " ne correspond pas directement aux préférences renseignées; suggestion conservée.");
        }
        return item;
    }

    private static Set<String> categoriesForStyle(String style) {
        String value = normalize(style);
        if (value.contains("famille")) return Set.of("CULTURE", "HERITAGE", "NATURE", "GARDEN", "BEACH", "FOOD");
        if (value.contains("aventure")) return Set.of("ADVENTURE", "NATURE", "NATURAL_SITE", "ISLAND", "BOAT_TRIP");
        if (value.contains("culture") || value.contains("decouverte"))
            return Set.of("CULTURE", "HERITAGE", "FOOD", "HISTORIC");
        if (value.contains("romantique") || value.contains("couple"))
            return Set.of("BEACH", "WATERFRONT", "FOOD", "GARDEN");
        if (value.contains("detente") || value.contains("repos"))
            return Set.of("BEACH", "WATERFRONT", "GARDEN", "PUBLIC_SPACE");
        if (value.contains("gastronomie")) return Set.of("FOOD", "CULTURE");
        return Set.of();
    }

    private static Set<String> categoriesFor(String interest) {
        String value = normalize(interest);
        Set<String> result = new LinkedHashSet<>();
        if (value.contains("culture") || value.contains("histoire") || value.contains("patrimoine")
                || value.contains("heritage") || value.contains("architecture")) {
            result.addAll(Set.of("CULTURE", "HERITAGE", "HISTORIC"));
        }
        if (value.contains("nature") || value.contains("foret") || value.contains("forest")
                || value.contains("faune") || value.contains("flore") || value.contains("wildlife")
                || value.contains("ecotour")) {
            result.addAll(Set.of("NATURE", "GARDEN", "NATURAL_SITE"));
        }
        if (value.contains("plage") || value.contains("beach") || value.contains("mer")
                || value.contains("baignade") || value.contains("detente")) {
            result.addAll(Set.of("BEACH", "WATERFRONT"));
        }
        if (value.contains("gastronomie") || value.contains("cuisine") || value.contains("food")
                || value.contains("restaurant")) result.add("FOOD");
        if (value.contains("aventure") || value.contains("adventure") || value.contains("randonnee")
                || value.contains("sport")) result.add("ADVENTURE");
        if (value.contains("bateau") || value.contains("boat") || value.contains("maritime"))
            result.addAll(Set.of("BOAT_TRIP", "ISLAND", "NATURAL_SITE"));
        // Exact category values remain usable without requiring a synonym dictionary.
        result.add(value.toUpperCase(Locale.ROOT));
        return result;
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private static String normalize(String value) {
        return Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").trim().toLowerCase(Locale.ROOT);
    }
}
