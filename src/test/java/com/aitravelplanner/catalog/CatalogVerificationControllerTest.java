package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
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

    private CatalogVerificationRequest request(List<String> fields) {
        return new CatalogVerificationRequest(
                CatalogVerificationRequest.VerificationStatus.VERIFIED,
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
            // et que le contrôleur a poursuivi jusqu'à la recherche en base.
            assertEquals(404, exception.getStatusCode().value());
        }

        verify(jdbc, times(2)).queryForObject(
                anyString(),
                eq(Integer.class),
                eq(1L)
        );
    }
}
