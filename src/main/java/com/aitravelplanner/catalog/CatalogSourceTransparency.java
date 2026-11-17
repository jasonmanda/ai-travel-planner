package com.aitravelplanner.catalog;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Converts catalog source metadata into conservative, user-readable explanations.
 * Source suitability is not factual verification of the catalog item.
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
        boolean specificOfficialSource = isSpecificOfficialSource(sourceType, sourceScope, item.get("sourceUrl"), documented);
        String sourceQuality = sourceQuality(sourceType, sourceScope, documented, specificOfficialSource);
        String sourceQualityReason = sourceQualityReason(sourceType, sourceScope, documented, specificOfficialSource);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("sourceName", item.get("sourceName"));
        result.put("sourceUrl", item.get("sourceUrl"));
        result.put("sourceType", sourceType);
        result.put("sourceTypeLabel", sourceTypeLabel(sourceType));
        result.put("sourceScope", sourceScope);
        result.put("sourceScopeLabel", sourceScopeLabel(sourceScope));
        result.put("sourceQuality", sourceQuality);
        result.put("sourceQualityLabel", sourceQualityLabel(sourceQuality));
        result.put("sourceQualityReason", sourceQualityReason);
        result.put("sourceSupportsRecommendation", false);
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

    private static String sourceQuality(String type, String scope, boolean documented, boolean specificOfficialSource) {
        if (!documented) {
            return "NO_USABLE_SOURCE";
        }
        if ("DESTINATION_GENERAL".equalsIgnoreCase(scope)) {
            return "DESTINATION_CONTEXT_ONLY";
        }
        if ("SCIENTIFIC".equalsIgnoreCase(type)) {
            return "SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE";
        }
        if ("ENCYCLOPEDIC".equalsIgnoreCase(type) || "GENERIC".equalsIgnoreCase(type)) {
            return "SECONDARY_REFERENCE_ONLY";
        }
        if ("OFFICIAL".equalsIgnoreCase(type) && "ITEM_SPECIFIC".equalsIgnoreCase(scope)
                && specificOfficialSource) {
            return "ITEM_SPECIFIC_PRIMARY_CANDIDATE";
        }
        return "SOURCE_REQUIRES_REVIEW";
    }

    private static String sourceQualityLabel(String quality) {
        return switch (quality) {
            case "NO_USABLE_SOURCE" -> "Aucune source exploitable";
            case "DESTINATION_CONTEXT_ONLY" -> "Contexte général de destination";
            case "SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE" -> "Référence scientifique ou géographique";
            case "SECONDARY_REFERENCE_ONLY" -> "Référence secondaire uniquement";
            case "ITEM_SPECIFIC_PRIMARY_CANDIDATE" -> "Source institutionnelle spécifique à examiner";
            default -> "Qualité de source à examiner";
        };
    }

    private static String sourceQualityReason(String type, String scope, boolean documented, boolean specificOfficialSource) {
        if (!documented) {
            return "Aucun couple nom de source et URL HTTP/HTTPS exploitable n’est enregistré. Cette fiche ne dispose donc pas d’appui documentaire utilisable.";
        }
        if ("DESTINATION_GENERAL".equalsIgnoreCase(scope)) {
            return "La source porte sur la destination dans son ensemble. Elle ne suffit pas à confirmer ce lieu ou cette activité, ses opérateurs, son accès ou ses conditions actuelles.";
        }
        if ("SCIENTIFIC".equalsIgnoreCase(type)) {
            return "La référence scientifique ou de localité peut étayer un contexte, une existence ou une localisation. Elle ne prouve pas qu’il s’agit d’une offre touristique visitable ni ses modalités pratiques.";
        }
        if ("ENCYCLOPEDIC".equalsIgnoreCase(type)) {
            return "La source encyclopédique est une référence secondaire. Les informations de visite, l’accès, les horaires et les conditions actuelles doivent être confirmés indépendamment.";
        }
        if ("GENERIC".equalsIgnoreCase(type)) {
            return "La source secondaire peut aider à identifier le lieu, mais ne constitue pas une confirmation institutionnelle des services, horaires, tarifs ou conditions actuelles.";
        }
        if ("OFFICIAL".equalsIgnoreCase(type) && "ITEM_SPECIFIC".equalsIgnoreCase(scope)
                && !specificOfficialSource) {
            return "La source est déclarée spécifique, mais son URL correspond à une page générale ou à un document institutionnel couvrant un territoire, un parc, un ensemble patrimonial ou un événement. Elle doit être remplacée par une preuve dédiée à l’élément ou examinée manuellement.";
        }
        if ("OFFICIAL".equalsIgnoreCase(type) && "ITEM_SPECIFIC".equalsIgnoreCase(scope)
                && specificOfficialSource) {
            return "La source est institutionnelle et son URL mène à une page dédiée à l’élément. Le contenu et les champs qu’elle étaye doivent néanmoins être contrôlés avant toute vérification factuelle.";
        }
        return "La nature ou la portée de la source ne permet pas encore de déterminer précisément les affirmations qu’elle étaye. Un examen manuel est nécessaire.";
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
                + ". Aucune source exploitable n'est enregistrée ; l'absence de source ne confirme pas l'exactitude des informations de cette fiche, qui restent non vérifiées.";
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

    /**
     * An official label and ITEM_SPECIFIC scope are not sufficient on their own.
     * Reject homepages and known general directory/information paths. This is only
     * a structural safeguard: a human must still review the actual page content.
     */
    private static boolean isSpecificOfficialSource(
            String type, String scope, Object sourceUrl, boolean documented) {
        if (!documented || !"OFFICIAL".equalsIgnoreCase(type)
                || !"ITEM_SPECIFIC".equalsIgnoreCase(scope)) {
            return false;
        }
        try {
            java.net.URI uri = new java.net.URI(String.valueOf(sourceUrl).trim());
            String path = uri.getPath();
            if (path == null || path.isBlank() || "/".equals(path)) {
                return false;
            }
            String normalizedPath = path.replaceAll("/+$", "");
            if (isKnownGeneralOfficialReference(uri.getHost(), normalizedPath)) {
                return false;
            }
            String finalSegment = normalizedPath.substring(normalizedPath.lastIndexOf('/') + 1)
                    .toLowerCase(Locale.ROOT);
            Set<String> generalFinalSegments = Set.of(
                    "attractions", "visitor-information", "useful-information",
                    "visitor-tips", "patrimoine-materiel-national", "standards-catalogue"
            );
            // A nested page under a general section (for example /attractions/plan-your-day)
            // can still be item-specific. Reject only when the URL itself ends at a known
            // generic directory/information page.
            return !generalFinalSegments.contains(finalSegment);
        } catch (java.net.URISyntaxException exception) {
            return false;
        }
    }

    /**
     * Known institutional pages/documents that describe a wider destination, park,
     * heritage area or event rather than the individual visitor attraction/activity.
     * Keep this list conservative and mirrored by the manual SQL audit.
     */
    private static boolean isKnownGeneralOfficialReference(String host, String path) {
        if (host == null) {
            return false;
        }
        String normalizedHost = host.toLowerCase(Locale.ROOT);
        if (normalizedHost.startsWith("www.")) {
            normalizedHost = normalizedHost.substring(4);
        }
        String normalizedPath = path.toLowerCase(Locale.ROOT);
        if ("whc.unesco.org".equals(normalizedHost)) {
            return normalizedPath.equals("/en/list/173")
                    || normalizedPath.equals("/document/218167");
        }
        if ("bot.go.tz".equals(normalizedHost)) {
            return normalizedPath.replace("%20", " ").contains("tanzania tourism sector survey");
        }
        if ("sanparks.org".equals(normalizedHost)) {
            return normalizedPath.equals("/parks/table-mountain");
        }
        if ("tanzaniatourism.go.tz".equals(normalizedHost)) {
            return normalizedPath.contains("chan-2024-participant-guidebook");
        }
        if ("nishati.go.tz".equals(normalizedHost)) {
            return normalizedPath.contains("eapce25");
        }
        // The Forodhani committee report is institutionally hosted and place-related,
        // but does not establish the claimed night-market visitor activity.
        if ("zanzibarassembly.go.tz".equals(normalizedHost)) {
            return normalizedPath.equals("/storage/documents/committees/all/1677484498.pdf");
        }
        return false;
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
