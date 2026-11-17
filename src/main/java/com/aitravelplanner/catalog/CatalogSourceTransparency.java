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
        boolean documented = hasText(item.get("sourceName")) && isHttpUrl(item.get("sourceUrl"));
        String verificationLevel = verificationLevel(dataStatus, documented);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("sourceName", item.get("sourceName"));
        result.put("sourceUrl", item.get("sourceUrl"));
        result.put("sourceType", sourceType);
        result.put("sourceTypeLabel", sourceTypeLabel(sourceType));
        result.put("sourceScope", sourceScope);
        result.put("sourceScopeLabel", sourceScopeLabel(sourceScope));
        result.put("verificationStatus", dataStatus);
        result.put("verificationLevel", verificationLevel);
        result.put("documented", documented);
        result.put("partiallyVerified", "PARTIALLY_VERIFIED".equalsIgnoreCase(dataStatus));
        result.put("verified", "VERIFIED".equalsIgnoreCase(dataStatus));
        result.put("verificationNotes", item.get("verificationNotes"));
        result.put("lastVerifiedAt", item.get("lastVerifiedAt"));
        result.put("explanation", explanation(sourceType, sourceScope, dataStatus, documented));
        result.put("limitations", limitations(sourceType, sourceScope, dataStatus, documented));
        result.put("metric", "SOURCE_CONTEXT_NOT_FACTUAL_VERIFICATION");
        return result;
    }

    private static String verificationLevel(String status, boolean documented) {
        if ("VERIFIED".equalsIgnoreCase(status)) {
            return "VERIFIED";
        }
        if ("PARTIALLY_VERIFIED".equalsIgnoreCase(status)) {
            return "PARTIALLY_VERIFIED";
        }
        return documented ? "DOCUMENTED_UNVERIFIED" : "UNDOCUMENTED";
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

    private static String explanation(String type, String scope, String status, boolean documented) {
        String source = sourceTypeLabel(type);
        String coverage = sourceScopeLabel(scope);
        if ("VERIFIED".equalsIgnoreCase(status)) {
            return source + ". " + coverage
                    + ". Cette fiche porte le statut VERIFIED ; l'historique d'audit précise les champs effectivement contrôlés.";
        }
        if ("PARTIALLY_VERIFIED".equalsIgnoreCase(status)) {
            return source + ". " + coverage
                    + ". Certains champs seulement ont été vérifiés. Les autres informations ne doivent pas être présentées comme confirmées.";
        }
        if (documented) {
            return source + ". " + coverage
                    + ". La source est documentée, mais elle ne confirme pas à elle seule l'exactitude des informations de cette fiche ; aucune vérification factuelle des champs n'est enregistrée.";
        }
        return source + ". " + coverage
                + ". Aucune source exploitable n'est enregistrée ; aucune source ne confirme les informations de cette fiche, qui restent non vérifiées.";
    }

    private static String[] limitations(
            String type, String scope, String status, boolean documented) {
        if (!documented || "UNKNOWN".equalsIgnoreCase(type) || "UNKNOWN".equalsIgnoreCase(scope)) {
            return new String[]{
                    "La nature, la portée ou l'URL de la source n'est pas suffisamment établie.",
                    "Les informations pratiques doivent être vérifiées auprès d'une source compétente."
            };
        }
        if ("PARTIALLY_VERIFIED".equalsIgnoreCase(status)) {
            return new String[]{
                    "Seuls les champs listés dans l'historique de vérification sont confirmés.",
                    "Les horaires, tarifs, accès, disponibilité et conditions actuelles doivent être vérifiés séparément."
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

    private static boolean isHttpUrl(Object value) {
        if (!hasText(value)) {
            return false;
        }
        try {
            java.net.URI uri = new java.net.URI(String.valueOf(value).trim());
            String scheme = uri.getScheme();
            return uri.isAbsolute() && uri.getHost() != null
                    && ("http".equalsIgnoreCase(scheme) || "https".equalsIgnoreCase(scheme));
        } catch (java.net.URISyntaxException exception) {
            return false;
        }
    }

    private static boolean hasText(Object value) {
        return value != null && !String.valueOf(value).isBlank();
    }

    private static String value(Object value, String fallback) {
        return value == null || String.valueOf(value).isBlank()
                ? fallback : String.valueOf(value).trim();
    }
}
