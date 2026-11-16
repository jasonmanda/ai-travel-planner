package com.aitravelplanner.catalog;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Converts catalog source metadata into user-readable, conservative explanations.
 * It does not independently verify source contents or factual claims.
 */
public final class CatalogSourceTransparency {
    private CatalogSourceTransparency() {
    }

    public static Map<String, Object> describe(Map<String, Object> item) {
        String sourceType = value(item.get("sourceType"), "UNKNOWN");
        String sourceScope = value(item.get("sourceScope"), "UNKNOWN");
        String dataStatus = value(item.get("dataStatus"), "UNVERIFIED");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("sourceType", sourceType);
        result.put("sourceTypeLabel", sourceTypeLabel(sourceType));
        result.put("sourceScope", sourceScope);
        result.put("sourceScopeLabel", sourceScopeLabel(sourceScope));
        result.put("verificationStatus", dataStatus);
        result.put("verified", "VERIFIED".equalsIgnoreCase(dataStatus));
        result.put("explanation", explanation(sourceType, sourceScope, dataStatus));
        result.put("limitations", limitations(sourceType, sourceScope));
        result.put("metric", "SOURCE_CONTEXT_NOT_FACTUAL_VERIFICATION");
        return result;
    }

    private static String sourceTypeLabel(String type) {
        return switch (type.toUpperCase()) {
            case "OFFICIAL" -> "Source institutionnelle ou officielle";
            case "SCIENTIFIC" -> "Source scientifique";
            case "ENCYCLOPEDIC" -> "Source encyclopédique";
            case "GENERIC" -> "Source documentaire générale";
            default -> "Nature de la source inconnue";
        };
    }

    private static String sourceScopeLabel(String scope) {
        return switch (scope.toUpperCase()) {
            case "ITEM_SPECIFIC" -> "Source portant sur ce lieu ou cette activité";
            case "DESTINATION_GENERAL" -> "Source portant sur la destination en général";
            default -> "Portée de la source inconnue";
        };
    }

    private static String explanation(String type, String scope, String status) {
        String source = sourceTypeLabel(type);
        String coverage = sourceScopeLabel(scope);
        if ("VERIFIED".equalsIgnoreCase(status)) {
            return source + ". " + coverage
                    + ". Cette fiche porte le statut VERIFIED dans le catalogue ; consultez les notes et la date de vérification pour connaître les éléments effectivement contrôlés.";
        }
        return source + ". " + coverage
                + ". Cette classification décrit la documentation disponible et ne confirme pas l'exactitude des informations de cette fiche.";
    }

    private static String[] limitations(String type, String scope) {
        if ("UNKNOWN".equalsIgnoreCase(type) || "UNKNOWN".equalsIgnoreCase(scope)) {
            return new String[]{
                    "La nature ou la portée de la source n'est pas établie.",
                    "Les informations pratiques doivent être vérifiées auprès d'une source compétente."
            };
        }
        if ("DESTINATION_GENERAL".equalsIgnoreCase(scope)) {
            return new String[]{
                    "La source concerne la destination dans son ensemble et ne confirme pas nécessairement ce lieu ou cette activité.",
                    "Les horaires, tarifs, accès, disponibilité et conditions actuelles doivent être vérifiés séparément."
            };
        }
        return new String[]{
                "Une source portant sur cet élément ne garantit pas que toutes les données de la fiche sont exactes ou à jour.",
                "Les horaires, tarifs, accès, disponibilité et conditions actuelles doivent être vérifiés séparément."
        };
    }

    private static String value(Object value, String fallback) {
        return value == null || String.valueOf(value).isBlank()
                ? fallback : String.valueOf(value).trim();
    }
}
