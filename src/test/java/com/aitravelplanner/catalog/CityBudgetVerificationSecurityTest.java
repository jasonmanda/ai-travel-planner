package com.aitravelplanner.catalog;

import com.aitravelplanner.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.security.test.web.servlet.response.SecurityMockMvcResultMatchers.authenticated;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = CityBudgetVerificationController.class)
@Import(SecurityConfig.class)
@TestPropertySource(properties = {
        "APP_ADMIN_USERNAME=budget-admin",
        "APP_ADMIN_PASSWORD=test-admin-password"
})
class CityBudgetVerificationSecurityTest {

    private static final String ENDPOINT =
            "/api/v1/admin/catalog/cities/1/budget-verifications";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private JdbcTemplate jdbc;

    @Test
    void rejectsAnonymousRequestsWithUnauthorized() throws Exception {
        mockMvc.perform(post(ENDPOINT)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsAuthenticatedNonAdminUsersWithForbidden() throws Exception {
        mockMvc.perform(post(ENDPOINT)
                        .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
                                .user("catalog-reader").roles("USER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void acceptsConfiguredAdminCredentialsAndReachesRequestValidation() throws Exception {
        mockMvc.perform(post(ENDPOINT)
                        .with(httpBasic("budget-admin", "test-admin-password"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(authenticated().withUsername("budget-admin"))
                .andExpect(status().isBadRequest());
    }
}
