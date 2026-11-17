package com.aitravelplanner.catalog;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/catalog/cities")
public class CityBudgetVerificationController {

    private final JdbcTemplate jdbc;

    public CityBudgetVerificationController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @PostMapping("/{id}/budget-verifications")
    @Transactional
    public Map<String, Object> verifyDailyBudget(
            @PathVariable long id,
            @Valid @RequestBody CityBudgetVerificationRequest request,
            Authentication authentication) {

        if (id <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Identifiant de ville invalide");
        }

        validateSourceUrl(request.sourceUrl());

        // Serialize concurrent verifications for the same city and fail before writing
        // if the target city does not exist.
        List<Long> cityIds = jdbc.queryForList(
                "SELECT id FROM cities WHERE id = ? FOR UPDATE",
                Long.class,
                id
        );
        if (cityIds.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Ville introuvable");
        }

        String sourceName = request.sourceName().trim();
        String sourceUrl = request.sourceUrl().trim();
        String notes = request.verificationNotes().trim();
        String verifiedBy = authentication.getName();

        Map<String, Object> history = jdbc.queryForMap(
                """
                INSERT INTO city_budget_verification_history
                    (city_id, verified_daily_budget, verified_currency,
                     source_name, source_url, verification_notes, verified_by)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                RETURNING id, verified_at
                """,
                id,
                request.dailyBudget(),
                request.currency(),
                sourceName,
                sourceUrl,
                notes,
                verifiedBy
        );

        int updated = jdbc.update(
                """
                UPDATE cities
                   SET estimated_daily_budget = ?,
                       estimated_daily_budget_currency = ?,
                       estimated_daily_budget_status = 'VERIFIED',
                       estimated_daily_budget_source_name = ?,
                       estimated_daily_budget_source_url = ?,
                       estimated_daily_budget_verified_at = ?,
                       estimated_daily_budget_notes = ?
                 WHERE id = ?
                """,
                request.dailyBudget(),
                request.currency(),
                sourceName,
                sourceUrl,
                history.get("verified_at"),
                notes,
                id
        );

        if (updated != 1) {
            throw new IllegalStateException("La ville n'a pas pu être mise à jour après vérification");
        }

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("cityId", id);
        response.put("verificationStatus", "VERIFIED");
        response.put("verifiedDailyBudget", request.dailyBudget());
        response.put("verifiedCurrency", request.currency());
        response.put("sourceName", sourceName);
        response.put("sourceUrl", sourceUrl);
        response.put("verificationNotes", notes);
        response.put("verifiedBy", verifiedBy);
        response.put("id", history.get("id"));
        response.put("verifiedAt", history.get("verified_at"));
        response.put("message", "Budget journalier vérifié et historique enregistré");
        return response;
    }

    private void validateSourceUrl(String sourceUrl) {
        try {
            if (sourceUrl == null || sourceUrl.isBlank()) {
                throw new IllegalArgumentException("URL vide");
            }

            String normalizedUrl = sourceUrl.trim();
            if (normalizedUrl.matches("(?is)^\\[[^\\]]+\\]\\(https?://[^)]+\\)$")
                    || normalizedUrl.chars().anyMatch(Character::isWhitespace)) {
                throw new IllegalArgumentException("URL non normalisée");
            }

            URI uri = URI.create(normalizedUrl);
            String scheme = uri.getScheme();
            if (!uri.isAbsolute()
                    || uri.getHost() == null
                    || uri.getRawAuthority() == null
                    || uri.getUserInfo() != null
                    || uri.getPort() > 65535
                    || scheme == null
                    || !("http".equalsIgnoreCase(scheme)
                    || "https".equalsIgnoreCase(scheme))) {
                throw new IllegalArgumentException("URL non HTTP(S)");
            }
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "sourceUrl doit être une URL HTTP ou HTTPS valide, sans format Markdown"
            );
        }
    }
}
