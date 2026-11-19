package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CatalogAdminControllerTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final CatalogAdminController controller = new CatalogAdminController(jdbc);

    @Test
    void returnsReadOnlyCatalogAndVerificationCoverageSummary() {
        when(jdbc.queryForList(contains("WITH catalog_items"))).thenReturn(List.of(
                Map.of("verifiedCoreFields", new String[]{"name", "category", "description", "latitude", "longitude", "estimated_duration_minutes"}),
                Map.of("verifiedCoreFields", new String[]{"name", "category"}),
                Map.of("verifiedCoreFields", new String[]{})
        ));

        Map<String, Object> result = controller.listItems();

        assertEquals(3, result.get("total"));
        assertEquals(1L, result.get("fullyVerifiedCount"));
        assertEquals(1L, result.get("partiallyVerifiedCount"));
        assertEquals(1L, result.get("unverifiedCount"));
        verify(jdbc).queryForList(contains("WHERE a.active = TRUE"));
    }

    @Test
    void reportsEmptyCatalogWithoutFailure() {
        when(jdbc.queryForList(contains("WITH catalog_items"))).thenReturn(List.of());

        Map<String, Object> result = controller.listItems();

        assertEquals(0, result.get("total"));
        assertEquals(0L, result.get("fullyVerifiedCount"));
        assertEquals(0L, result.get("partiallyVerifiedCount"));
        assertEquals(0L, result.get("unverifiedCount"));
    }
}
