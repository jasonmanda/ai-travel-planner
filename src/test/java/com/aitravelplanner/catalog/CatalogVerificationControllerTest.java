package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
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
}
