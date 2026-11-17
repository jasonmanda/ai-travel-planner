package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

class CatalogVerificationControllerTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final CatalogVerificationController controller =
            new CatalogVerificationController(jdbc);
    private final UsernamePasswordAuthenticationToken admin =
            UsernamePasswordAuthenticationToken.authenticated("catalog-admin", "N/A", List.of());

    @Test
    void rejectsUnknownAttractionFieldsBeforeDatabaseAccess() {
        var request = request(List.of("name", "opening_hours"));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyAttraction(1L, request, admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsDuplicateVerifiedFieldsBeforeDatabaseAccess() {
        var request = request(List.of("name", "name"));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyAttraction(1L, request, admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsEmptyVerifiedFieldsBeforeDatabaseAccessForVerifiedAndRejectedEvents() {
        for (CatalogVerificationRequest.VerificationStatus status : List.of(
                CatalogVerificationRequest.VerificationStatus.VERIFIED,
                CatalogVerificationRequest.VerificationStatus.REJECTED
        )) {
            CatalogVerificationRequest request = request(status, List.of());

            ResponseStatusException exception = assertThrows(
                    ResponseStatusException.class,
                    () -> controller.verifyAttraction(1L, request, admin)
            );

            assertEquals(400, exception.getStatusCode().value());
        }

        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsBlankVerifiedFieldBeforeDatabaseAccess() {
        CatalogVerificationRequest request = request(List.of("   "));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyAttraction(1L, request, admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsInvalidSourceUrlBeforeDatabaseAccess() {
        var request = new CatalogVerificationRequest(
                CatalogVerificationRequest.VerificationStatus.VERIFIED,
                List.of("name"),
                "Office du tourisme",
                "javascript:alert(1)",
                "Nom comparé à la source officielle"
        );

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyAttraction(1L, request, admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsNonPositiveItemIdBeforeDatabaseAccess() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyActivity(0L, request(List.of("name")), admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsAttractionOnlyFieldsForActivities() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyActivity(
                        1L,
                        request(List.of("estimated_visit_cost")),
                        admin
                )
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsPriceVerificationWhenCurrentPriceOrCurrencyIsMissing() {
        Map<String, Object> catalogItem = new HashMap<>();
        catalogItem.put("estimated_visit_cost", new BigDecimal("25.00"));
        catalogItem.put("cost_currency", null);
        when(jdbc.queryForMap(anyString(), eq(1L))).thenReturn(catalogItem);

        CatalogVerificationRequest request = request(List.of(
                "estimated_visit_cost", "cost_currency"
        ));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyAttraction(1L, request, admin)
        );

        assertEquals(400, exception.getStatusCode().value());
    }


    @Test
    void rejectsEssentialFieldVerificationWhenCurrentValueIsBlank() {
        Map<String, Object> catalogItem = new HashMap<>();
        catalogItem.put("description", "   ");
        when(jdbc.queryForMap(anyString(), eq(1L))).thenReturn(catalogItem);

        CatalogVerificationRequest request = request(List.of("description"));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyAttraction(1L, request, admin)
        );

        assertEquals(400, exception.getStatusCode().value());
        verify(jdbc).queryForMap(
                org.mockito.ArgumentMatchers.contains("FOR UPDATE"),
                eq(1L)
        );
    }

    @Test
    void rejectsEssentialFieldVerificationWhenCurrentValueIsNull() {
        Map<String, Object> catalogItem = new HashMap<>();
        catalogItem.put("latitude", null);
        when(jdbc.queryForMap(anyString(), eq(1L))).thenReturn(catalogItem);

        CatalogVerificationRequest request = request(List.of("latitude"));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.verifyAttraction(1L, request, admin)
        );

        assertEquals(400, exception.getStatusCode().value());
    }

    private CatalogVerificationRequest request(List<String> fields) {
        return request(CatalogVerificationRequest.VerificationStatus.VERIFIED, fields);
    }

    private CatalogVerificationRequest request(
            CatalogVerificationRequest.VerificationStatus status,
            List<String> fields) {
        return new CatalogVerificationRequest(
                status,
                fields,
                "Office du tourisme",
                "https://example.org/source",
                "Informations comparées à la source"
        );
    }

    @Test
    void rejectsMalformedSourceUrlsBeforeDatabaseAccess() {
        List<String> invalidUrls = List.of(
                "[https://example.org](https://example.org)",
                "https://example.org/path with spaces",
                "ftp://example.org/source",
                "https:///missing-host",
                "https://example.org:99999/source",
                "relative/path",
                "javascript:alert(1)"
        );

        assertAll(invalidUrls.stream()
                .map(url -> () -> {
                    ResponseStatusException exception = assertThrows(
                            ResponseStatusException.class,
                            () -> controller.verifyAttraction(
                                    1L,
                                    requestWithSourceUrl(url),
                                    admin
                            ),
                            "Cette URL aurait dû être rejetée : " + url
                    );

                    assertEquals(400, exception.getStatusCode().value());
                }));

        verifyNoInteractions(jdbc);
    }

    private CatalogVerificationRequest requestWithSourceUrl(String sourceUrl) {
        return new CatalogVerificationRequest(
                CatalogVerificationRequest.VerificationStatus.VERIFIED,
                List.of("name"),
                "Office du tourisme",
                sourceUrl,
                "Informations comparées à la source"
        );
    }

    @Test
    void acceptsValidHttpAndHttpsSourceUrls() {
        List<String> validUrls = List.of(
                "https://example.org/official-source",
                "http://example.org/source?lang=fr"
        );

        when(jdbc.queryForMap(anyString(), eq(1L)))
                .thenThrow(new EmptyResultDataAccessException(1));

        for (String url : validUrls) {
            ResponseStatusException exception = assertThrows(
                    ResponseStatusException.class,
                    () -> controller.verifyAttraction(
                            1L,
                            requestWithSourceUrl(url),
                            admin
                    )
            );

            // 404 signifie que l'URL a passé la validation
            // et que le contrôleur a poursuivi jusqu'au verrouillage de la ligne.
            assertEquals(404, exception.getStatusCode().value());
        }

        verify(jdbc, times(2)).queryForMap(anyString(), eq(1L));
    }
}
