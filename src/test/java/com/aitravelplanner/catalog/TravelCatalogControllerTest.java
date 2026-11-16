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
    void activitiesExposeCoordinatesAndGeographicArea() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForList(anyString(), any(Object[].class)))
                .thenReturn(List.of(Map.of("id", 1L)))
                .thenReturn(List.of(Map.of(
                        "id", 7L,
                        "name", "Excursion dans la forêt de Jozani",
                        "latitude", -6.26755,
                        "longitude", 39.41111,
                        "geographicArea", "JOZANI"
                )));

        TravelCatalogController controller = new TravelCatalogController(jdbc);

        List<Map<String, Object>> activities = controller.getActivities(1L);

        assertEquals(-6.26755, ((Number) activities.getFirst().get("latitude")).doubleValue());
        assertEquals(39.41111, ((Number) activities.getFirst().get("longitude")).doubleValue());
        assertEquals("JOZANI", activities.getFirst().get("geographicArea"));
    }
}
