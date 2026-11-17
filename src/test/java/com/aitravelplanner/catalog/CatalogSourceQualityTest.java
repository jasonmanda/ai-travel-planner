package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CatalogSourceQualityTest {

    @Test
    void destinationPortalIsContextOnlyAndCannotSupportAnItemRecommendation() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of(
                "sourceName", "Visit Zanzibar",
                "sourceUrl", "https://visitzanzibar.go.tz/",
                "sourceType", "OFFICIAL",
                "sourceScope", "DESTINATION_GENERAL",
                "dataStatus", "UNVERIFIED"
        ));

        assertEquals("DESTINATION_CONTEXT_ONLY", result.get("sourceQuality"));
        assertFalse((Boolean) result.get("sourceSupportsRecommendation"));
        assertEquals("UNVERIFIED", result.get("verificationStatus"));
        assertTrue(String.valueOf(result.get("sourceQualityReason")).contains("destination"));
    }

    @Test
    void scientificReferenceIsNotTreatedAsTourismEvidence() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of(
                "sourceName", "AntWeb",
                "sourceUrl", "https://www.antweb.org/locality.do?code=CEPF-TZ-10",
                "sourceType", "SCIENTIFIC",
                "sourceScope", "ITEM_SPECIFIC",
                "dataStatus", "UNVERIFIED"
        ));

        assertEquals("SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE", result.get("sourceQuality"));
        assertFalse((Boolean) result.get("sourceSupportsRecommendation"));
        assertTrue(String.valueOf(result.get("sourceQualityReason")).contains("offre touristique"));
    }

    @Test
    void missingSourceIsClassifiedAsUnusable() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of(
                "sourceType", "UNKNOWN",
                "sourceScope", "UNKNOWN",
                "dataStatus", "UNVERIFIED"
        ));

        assertEquals("NO_USABLE_SOURCE", result.get("sourceQuality"));
        assertEquals("UNDOCUMENTED", result.get("verificationLevel"));
        assertFalse((Boolean) result.get("sourceSupportsRecommendation"));
    }

    @Test
    void itemSpecificOfficialSourceIsFlaggedForContentReviewRatherThanAutoVerified() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of(
                "sourceName", "Official site",
                "sourceUrl", "https://example.org/place",
                "sourceType", "OFFICIAL",
                "sourceScope", "ITEM_SPECIFIC",
                "dataStatus", "UNVERIFIED"
        ));

        assertEquals("ITEM_SPECIFIC_PRIMARY", result.get("sourceQuality"));
        assertFalse((Boolean) result.get("verified"));
        assertEquals("DOCUMENTED_UNVERIFIED", result.get("verificationLevel"));
    }

    @Test
    void secondaryReferenceIsNotConsideredPrimaryEvidence() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of(
                "sourceName", "Wikipedia",
                "sourceUrl", "https://en.wikipedia.org/wiki/Old_Fort_of_Zanzibar",
                "sourceType", "ENCYCLOPEDIC",
                "sourceScope", "ITEM_SPECIFIC",
                "dataStatus", "UNVERIFIED"
        ));

        assertEquals("SECONDARY_REFERENCE_ONLY", result.get("sourceQuality"));
        assertFalse((Boolean) result.get("sourceSupportsRecommendation"));
    }
}
