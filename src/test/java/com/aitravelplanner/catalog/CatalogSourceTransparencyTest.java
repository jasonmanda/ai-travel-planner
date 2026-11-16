package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CatalogSourceTransparencyTest {

    @Test
    void unverifiedOfficialDestinationSourceIsNotPresentedAsProof() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of(
                "sourceType", "OFFICIAL",
                "sourceScope", "DESTINATION_GENERAL",
                "dataStatus", "UNVERIFIED"
        ));

        assertEquals("Source institutionnelle ou officielle", result.get("sourceTypeLabel"));
        assertEquals("Source portant sur la destination en général", result.get("sourceScopeLabel"));
        assertEquals("UNVERIFIED", result.get("verificationStatus"));
        assertFalse((Boolean) result.get("verified"));
        assertTrue(String.valueOf(result.get("explanation")).contains("ne confirme pas"));
        assertEquals("SOURCE_CONTEXT_NOT_FACTUAL_VERIFICATION", result.get("metric"));
    }

    @Test
    void unknownSourceRemainsExplicitlyUnknown() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of());

        assertEquals("UNKNOWN", result.get("sourceType"));
        assertEquals("UNKNOWN", result.get("sourceScope"));
        assertEquals("UNVERIFIED", result.get("verificationStatus"));
        assertFalse((Boolean) result.get("verified"));
    }

    @Test
    void verifiedStatusIsReportedWithoutClaimingSourceIsInfallible() {
        Map<String, Object> result = CatalogSourceTransparency.describe(Map.of(
                "sourceType", "SCIENTIFIC",
                "sourceScope", "ITEM_SPECIFIC",
                "dataStatus", "VERIFIED"
        ));

        assertTrue((Boolean) result.get("verified"));
        assertTrue(String.valueOf(result.get("explanation")).contains("date de vérification"));
        assertEquals("SOURCE_CONTEXT_NOT_FACTUAL_VERIFICATION", result.get("metric"));
    }
}
