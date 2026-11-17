package com.aitravelplanner.catalog;

import com.aitravelplanner.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.security.autoconfigure.SecurityAutoConfiguration;
import org.springframework.boot.security.autoconfigure.web.servlet.ServletWebSecurityAutoConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = {CatalogVerificationController.class, CatalogVerificationHistoryController.class},
        properties = {
                "APP_ADMIN_USERNAME=test-admin",
                "APP_ADMIN_PASSWORD=test-password"
        }
)
@Import(SecurityConfig.class)
@ImportAutoConfiguration({
        SecurityAutoConfiguration.class,
        ServletWebSecurityAutoConfiguration.class
})
class CatalogVerificationSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private JdbcTemplate jdbcTemplate;

    private static final String ENDPOINT =
            "/api/v1/admin/catalog/attractions/1/verifications";
    private static final String HISTORY_ENDPOINT = ENDPOINT;

    private static final String VALID_BODY = """
            {
              "verificationStatus": "VERIFIED",
              "verifiedFields": ["name"],
              "sourceName": "Office du tourisme",
              "sourceUrl": "https://example.org/source",
              "verificationNotes": "Nom vérifié auprès de la source"
            }
            """;

    @Test
    void anonymousHistoryRequestIsUnauthorized() throws Exception {
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(HISTORY_ENDPOINT))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void nonAdminCannotReadVerificationHistory() throws Exception {
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(HISTORY_ENDPOINT)
                        .with(user("ordinary-user").roles("USER")))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanReachVerificationHistoryEndpoint() throws Exception {
        when(jdbcTemplate.queryForObject(
                eq("SELECT COUNT(*) FROM attractions WHERE id = ?"),
                eq(Long.class),
                eq(1L)
        )).thenReturn(0L);

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(HISTORY_ENDPOINT)
                        .with(httpBasic("test-admin", "test-password")))
                .andExpect(status().isNotFound());
    }

    @Test
    void anonymousRequestIsUnauthorized() throws Exception {
        mockMvc.perform(post(ENDPOINT)
                        .contentType("application/json")
                        .content(VALID_BODY))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedUserWithoutAdminRoleIsForbidden() throws Exception {
        mockMvc.perform(post(ENDPOINT)
                        .with(user("ordinary-user").roles("USER"))
                        .contentType("application/json")
                        .content(VALID_BODY))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanReachVerificationEndpoint() throws Exception {
        when(jdbcTemplate.queryForMap(
                org.mockito.ArgumentMatchers.contains("FOR UPDATE"),
                eq(1L)
        )).thenThrow(new org.springframework.dao.EmptyResultDataAccessException(1));

        mockMvc.perform(post(ENDPOINT)
                        .with(httpBasic("test-admin", "test-password"))
                        .contentType("application/json")
                        .content(VALID_BODY))
                .andExpect(status().isNotFound());

        verify(jdbcTemplate).queryForMap(
                org.mockito.ArgumentMatchers.contains("FOR UPDATE"),
                eq(1L)
        );
    }
}
