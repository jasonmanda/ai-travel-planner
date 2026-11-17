package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CatalogSourceTransparencyTest {

    @Test
    void distinguishesDocumentedButUnverifiedFromVerified() {
        Map<String, Object> result = CatalogSourceTransparency.describe(item("UNVERIFIED"));

        assertEquals("DOCUMENTED_UNVERIFIED", result.get("verificationLevel"));
        assertTrue((Boolean) result.get("documented"));
        assertFalse((Boolean) result.get("partiallyVerified"));
        assertFalse((Boolean) result.get("verified"));
        assertTrue(String.valueOf(result.get("explanation")).contains("aucune vérification factuelle"));
    }

    @Test
    void exposesPartialVerificationWithoutClaimingAllFieldsAreConfirmed() {
        Map<String, Object> result = CatalogSourceTransparency.describe(item("PARTIALLY_VERIFIED"));

        assertEquals("PARTIALLY_VERIFIED", result.get("verificationLevel"));
        assertTrue((Boolean) result.get("documented"));
        assertTrue((Boolean) result.get("partiallyVerified"));
        assertFalse((Boolean) result.get("verified"));
        assertTrue(String.valueOf(result.get("explanation")).contains("Certains champs seulement"));
        assertTrue(((String[]) result.get("limitations"))[0].contains("champs listés"));
    }

    @Test
    void exposesVerifiedStatusSeparately() {
        Map<String, Object> result = CatalogSourceTransparency.describe(item("VERIFIED"));

        assertEquals("VERIFIED", result.get("verificationLevel"));
        assertTrue((Boolean) result.get("verified"));
        assertFalse((Boolean) result.get("partiallyVerified"));
        assertTrue(String.valueOf(result.get("explanation")).contains("historique d'audit"));
    }

    @Test
    void reportsUndocumentedWhenSourceUrlIsMissing() {
        Map<String, Object> item = item("UNVERIFIED");
        item.put("sourceUrl", null);

        Map<String, Object> result = CatalogSourceTransparency.describe(item);

        assertEquals("UNDOCUMENTED", result.get("verificationLevel"));
        assertFalse((Boolean) result.get("documented"));
    }

    @Test
    void doesNotTreatDestinationWideSourceAsItemSpecificProof() {
        Map<String, Object> item = item("UNVERIFIED");
        item.put("sourceScope", "DESTINATION_GENERAL");

        Map<String, Object> result = CatalogSourceTransparency.describe(item);

        assertTrue(((String[]) result.get("limitations"))[0]
                .contains("destination dans son ensemble"));
    }

    private static Map<String, Object> item(String status) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("sourceName", "Portail touristique");
        item.put("sourceUrl", "https://example.org/zanzibar");
        item.put("sourceType", "OFFICIAL");
        item.put("sourceScope", "ITEM_SPECIFIC");
        item.put("dataStatus", status);
        item.put("verificationNotes", "Notes de contrôle");
        item.put("lastVerifiedAt", null);
        return item;
    }
}
