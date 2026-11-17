package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TravelCatalogControllerTest {

    @Test
    void activitiesExposeCoordinatesAndGeographicArea() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForList(anyString(), any(Object[].class)))
                .thenReturn(List.of(Map.of("id", 1L)))
                .thenReturn(List.of(Map.ofEntries(
                        Map.entry("id", 7L),
                        Map.entry("name", "Excursion dans la forêt de Jozani"),
                        Map.entry("latitude", -6.26755),
                        Map.entry("longitude", 39.41111),
                        Map.entry("geographicArea", "JOZANI"),
                        Map.entry("sourceName", "AntWeb"),
                        Map.entry("sourceUrl", "https://www.antweb.org/locality.do?code=CEPF-TZ-10"),
                        Map.entry("sourceType", "SCIENTIFIC"),
                        Map.entry("sourceScope", "ITEM_SPECIFIC"),
                        Map.entry("dataStatus", "UNVERIFIED"),
                        Map.entry("duplicateOfType", "ATTRACTION"),
                        Map.entry("duplicateOfId", 12L),
                        Map.entry("deduplicationRelation", "SAME_EXPERIENCE")
                )));

        TravelCatalogController controller = new TravelCatalogController(jdbc);

        List<Map<String, Object>> activities = controller.getActivities(1L);

        assertEquals(-6.26755, ((Number) activities.getFirst().get("latitude")).doubleValue());
        assertEquals(39.41111, ((Number) activities.getFirst().get("longitude")).doubleValue());
        assertEquals("JOZANI", activities.getFirst().get("geographicArea"));
        assertEquals("ATTRACTION", activities.getFirst().get("duplicateOfType"));
        assertEquals(12L, activities.getFirst().get("duplicateOfId"));
        @SuppressWarnings("unchecked")
        Map<String, Object> quality = (Map<String, Object>) activities.getFirst().get("catalogQuality");
        assertEquals("DATA_COMPLETENESS_NOT_EXPERIENCE_QUALITY", quality.get("metric"));
        assertEquals(20, quality.get("score"));
        @SuppressWarnings("unchecked")
        Map<String, Object> transparency = (Map<String, Object>) activities.getFirst().get("sourceTransparency");
        assertEquals("SCIENTIFIC_OR_GEOGRAPHIC_REFERENCE", transparency.get("sourceQuality"));
        assertFalse((Boolean) transparency.get("sourceSupportsRecommendation"));
        assertTrue(String.valueOf(transparency.get("sourceQualityReason")).contains("offre touristique"));
    }
}
