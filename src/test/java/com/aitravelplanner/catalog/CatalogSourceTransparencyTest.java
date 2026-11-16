package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
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
        assertTrue(String.valueOf(result.get("explanation")).contains("historique d'audit"));
        assertEquals("SOURCE_CONTEXT_NOT_FACTUAL_VERIFICATION", result.get("metric"));
    }

    @Test
    void exposesSourceMetadataAndVerificationSnapshotDetails() {
        Instant verifiedAt = Instant.parse("2026-11-16T10:00:00Z");
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("sourceName", "Tourism authority");
        item.put("sourceUrl", "https://example.org/place");
        item.put("sourceType", "OFFICIAL");
        item.put("sourceScope", "ITEM_SPECIFIC");
        item.put("dataStatus", "PARTIALLY_VERIFIED");
        item.put("verificationNotes", "Access information still needs confirmation.");
        item.put("lastVerifiedAt", verifiedAt);

        Map<String, Object> transparency = CatalogSourceTransparency.describe(item);

        assertEquals("Tourism authority", transparency.get("sourceName"));
        assertEquals("https://example.org/place", transparency.get("sourceUrl"));
        assertEquals("OFFICIAL", transparency.get("sourceType"));
        assertEquals("ITEM_SPECIFIC", transparency.get("sourceScope"));
        assertEquals("PARTIALLY_VERIFIED", transparency.get("verificationStatus"));
        assertEquals("Access information still needs confirmation.",
                transparency.get("verificationNotes"));
        assertSame(verifiedAt, transparency.get("lastVerifiedAt"));
        assertFalse((Boolean) transparency.get("verified"));
        assertEquals("SOURCE_CONTEXT_NOT_FACTUAL_VERIFICATION", transparency.get("metric"));
    }
}
