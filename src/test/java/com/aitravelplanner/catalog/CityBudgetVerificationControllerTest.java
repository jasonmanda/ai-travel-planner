package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class CityBudgetVerificationControllerTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final CityBudgetVerificationController controller =
            new CityBudgetVerificationController(jdbc);
    private final UsernamePasswordAuthenticationToken admin =
            UsernamePasswordAuthenticationToken.authenticated("budget-admin", "N/A", List.of());

    @Test
    void rejectsNonPositiveCityIdBeforeDatabaseAccess() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyDailyBudget(0L, request(), admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsInvalidSourceUrlBeforeDatabaseAccess() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyDailyBudget(1L, request(
                        "javascript:alert(1)"
                ), admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void returnsNotFoundWhenCityDoesNotExist() {
        when(jdbc.queryForList(anyString(), eq(Long.class), eq(999L)))
                .thenReturn(List.of());

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyDailyBudget(999L, request(), admin)
        );

        assertEquals(404, exception.getStatusCode().value());
        verify(jdbc).queryForList(anyString(), eq(Long.class), eq(999L));
    }

    @Test
    void recordsAuditSnapshotAndPromotesCityToVerified() {
        when(jdbc.queryForList(anyString(), eq(Long.class), eq(7L)))
                .thenReturn(List.of(7L));
        Instant verifiedAt = Instant.parse("2026-11-17T06:00:00Z");
        when(jdbc.queryForMap(
                contains("INSERT INTO city_budget_verification_history"),
                any(Object[].class)
        )).thenReturn(Map.of("id", 41L, "verified_at", verifiedAt));
        when(jdbc.update(anyString(), any(Object[].class))).thenReturn(1);

        Map<String, Object> response = controller.verifyDailyBudget(7L, request(), admin);

        assertEquals(7L, response.get("cityId"));
        assertEquals("VERIFIED", response.get("verificationStatus"));
        assertEquals(new BigDecimal("52000.00"), response.get("verifiedDailyBudget"));
        assertEquals("XOF", response.get("verifiedCurrency"));
        assertEquals("budget-admin", response.get("verifiedBy"));
        assertEquals(41L, response.get("id"));
        assertEquals(verifiedAt, response.get("verifiedAt"));

        verify(jdbc).queryForList(anyString(), eq(Long.class), eq(7L));
        verify(jdbc).queryForMap(
                contains("INSERT INTO city_budget_verification_history"),
                any(Object[].class)
        );
        verify(jdbc).update(anyString(), any(Object[].class));
    }

    private CityBudgetVerificationRequest request() {
        return request("https://example.org/city-budget-source");
    }

    private CityBudgetVerificationRequest request(String sourceUrl) {
        return new CityBudgetVerificationRequest(
                new BigDecimal("52000.00"),
                "XOF",
                "Office national du tourisme",
                sourceUrl,
                "Budget journalier contrôlé pour un voyageur, hors transport international."
        );
    }
}
