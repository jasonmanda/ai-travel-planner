package com.aitravelplanner.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

class CatalogVerificationHistoryControllerTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final CatalogVerificationHistoryController controller =
            new CatalogVerificationHistoryController(jdbc);

    @Test
    void rejectsNonPositiveItemIdBeforeDatabaseAccess() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.getAttractionVerifications(0L, 0, 20)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsNegativePageBeforeDatabaseAccess() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.getAttractionVerifications(1L, -1, 20)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsPageSizeAboveMaximumBeforeDatabaseAccess() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.getActivityVerifications(1L, 0, 101)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }

    @Test
    void rejectsZeroPageSizeBeforeDatabaseAccess() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> controller.getActivityVerifications(1L, 0, 0)
        );

        assertEquals(400, exception.getStatusCode().value());
        verifyNoInteractions(jdbc);
    }
}
