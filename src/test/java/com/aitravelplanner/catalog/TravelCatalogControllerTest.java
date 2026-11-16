package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TravelCatalogControllerTest {

    @Test
    void activitiesExposeTheirGeographicCoordinates() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForList(anyString(), any(Object[].class)))
                .thenReturn(List.of(Map.of("id", 1L)))
                .thenReturn(List.of(Map.of(
                        "id", 7L,
                        "name", "Excursion dans la forêt de Jozani",
                        "latitude", -6.2667,
                        "longitude", 39.4111
                )));

        TravelCatalogController controller = new TravelCatalogController(jdbc);

        List<Map<String, Object>> activities = controller.getActivities(1L);

        assertEquals(-6.2667, ((Number) activities.getFirst().get("latitude")).doubleValue());
        assertEquals(39.4111, ((Number) activities.getFirst().get("longitude")).doubleValue());
    }
}
