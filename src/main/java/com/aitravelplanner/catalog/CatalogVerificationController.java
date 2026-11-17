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
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.dao.EmptyResultDataAccessException;

import java.net.URI;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/admin/catalog")
public class CatalogVerificationController {

    private static final Set<String> ATTRACTION_FIELDS = Set.of(
            "name", "category", "description", "latitude", "longitude",
            "estimated_visit_cost", "cost_currency", "estimated_duration_minutes"
    );

    private static final Set<String> ACTIVITY_FIELDS = Set.of(
            "name", "category", "description", "latitude", "longitude",
            "estimated_cost", "cost_currency", "estimated_duration_minutes",
            "suitable_for_families", "min_age_years"
    );

    private final JdbcTemplate jdbc;

    public CatalogVerificationController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @PostMapping("/attractions/{id}/verifications")
    @Transactional
    public Map<String, Object> verifyAttraction(
            @PathVariable long id,
            @Valid @RequestBody CatalogVerificationRequest request,
            Authentication authentication) {
        return createVerification(
                "attractions", "attraction_verification_history", "attraction_id",
                id, request, authentication, ATTRACTION_FIELDS
        );
    }

    @PostMapping("/activities/{id}/verifications")
    @Transactional
    public Map<String, Object> verifyActivity(
            @PathVariable long id,
            @Valid @RequestBody CatalogVerificationRequest request,
            Authentication authentication) {
        return createVerification(
                "activities", "activity_verification_history", "activity_id",
                id, request, authentication, ACTIVITY_FIELDS
        );
    }

    private Map<String, Object> createVerification(
            String itemTable,
            String historyTable,
            String foreignKey,
            long itemId,
            CatalogVerificationRequest request,
            Authentication authentication,
            Set<String> allowedFields) {

        if (itemId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Identifiant invalide");
        }

        List<String> fields = request.verifiedFields().stream()
                .map(String::trim)
                .toList();

        if (new LinkedHashSet<>(fields).size() != fields.size()
                || !allowedFields.containsAll(fields)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "verifiedFields contient des champs inconnus ou dupliqués"
            );
        }

        validateSourceUrl(request.sourceUrl());

        Map<String, Object> catalogItem;
        try {
            // Lock the catalog row before reading any values used by this verification.
            catalogItem = jdbc.queryForMap(
                    "SELECT * FROM " + itemTable + " WHERE id = ? FOR UPDATE",
                    itemId
            );
        } catch (EmptyResultDataAccessException exception) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Élément du catalogue introuvable");
        }

        if (request.verificationStatus() != CatalogVerificationRequest.VerificationStatus.REJECTED) {
            validateEssentialFieldValues(fields, catalogItem);
        }

        String priceColumn = itemTable.equals("attractions")
                ? "estimated_visit_cost" : "estimated_cost";
        boolean verifiesPrice = request.verificationStatus()
                == CatalogVerificationRequest.VerificationStatus.VERIFIED
                && fields.contains(priceColumn)
                && fields.contains("cost_currency");

        BigDecimal verifiedPrice = null;
        String verifiedCurrency = null;
        if (verifiesPrice) {
            verifiedPrice = (BigDecimal) catalogItem.get(priceColumn);
            verifiedCurrency = (String) catalogItem.get("cost_currency");
            if (verifiedPrice == null || verifiedCurrency == null || verifiedCurrency.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Un tarif et une devise doivent être renseignés pour vérifier le prix"
                );
            }
        }

        // Field names come only from the server-side allowlist; values are read by PostgreSQL
        // from the row already locked above, never accepted from the HTTP request.
        String jsonbArguments = fields.stream()
                .map(field -> "'" + field + "', " + field)
                .collect(java.util.stream.Collectors.joining(", "));
        String snapshotSql = "SELECT jsonb_build_object(" + jsonbArguments + ")::text"
                + " FROM " + itemTable + " WHERE id = ?";
        String verifiedValues = jdbc.queryForObject(snapshotSql, String.class, itemId);

        String sql = "INSERT INTO " + historyTable + " (" + foreignKey
                + ", verification_status, verified_fields, source_name, source_url,"
                + " verification_notes, verified_by, verified_price, verified_currency, verified_values)"
                + " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb) RETURNING id, verified_at";

        BigDecimal priceSnapshot = verifiedPrice;
        String currencySnapshot = verifiedCurrency;
        String valuesSnapshot = verifiedValues;
        Map<String, Object> saved = jdbc.execute((ConnectionCallback<Map<String, Object>>) connection -> {
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setLong(1, itemId);
                statement.setString(2, request.verificationStatus().name());
                statement.setArray(3, connection.createArrayOf("text", fields.toArray()));
                statement.setString(4, request.sourceName().trim());
                statement.setString(5, request.sourceUrl().trim());
                statement.setString(6, request.verificationNotes().trim());
                statement.setString(7, authentication.getName());
                if (priceSnapshot == null) {
                    statement.setNull(8, Types.NUMERIC);
                    statement.setNull(9, Types.VARCHAR);
                } else {
                    statement.setBigDecimal(8, priceSnapshot);
                    statement.setString(9, currencySnapshot);
                }
                statement.setString(10, valuesSnapshot);

                try (ResultSet resultSet = statement.executeQuery()) {
                    if (!resultSet.next()) {
                        throw new IllegalStateException("L'événement de vérification n'a pas été créé");
                    }
                    Map<String, Object> result = new LinkedHashMap<>();
                    result.put("id", resultSet.getLong("id"));
                    result.put("verifiedAt", resultSet.getObject("verified_at"));
                    return result;
                }
            }
        });

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("itemId", itemId);
        response.put("verificationStatus", request.verificationStatus().name());
        response.put("verifiedFields", fields);
        response.put("sourceName", request.sourceName().trim());
        response.put("sourceUrl", request.sourceUrl().trim());
        response.put("verifiedBy", authentication.getName());
        response.put("verifiedPrice", verifiedPrice);
        response.put("verifiedCurrency", verifiedCurrency);
        response.putAll(saved);
        response.put("message", "Vérification enregistrée dans l'historique");
        return response;
    }

    private void validateEssentialFieldValues(
            List<String> fields,
            Map<String, Object> catalogItem) {
        for (String field : fields) {
            Object value = catalogItem.get(field);
            boolean invalid = switch (field) {
                case "name", "description", "category" ->
                        !(value instanceof String text) || text.isBlank();
                case "latitude", "longitude" ->
                        !(value instanceof Number);
                case "estimated_duration_minutes" ->
                        !(value instanceof Number number) || number.intValue() <= 0;
                default -> false;
            };
            if (invalid) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Le champ essentiel '" + field + "' doit contenir une valeur valide avant vérification"
                );
            }
        }
    }

    private void validateSourceUrl(String sourceUrl) {
        try {
            if (sourceUrl == null || sourceUrl.isBlank()) {
                throw new IllegalArgumentException("URL vide");
            }

            String normalizedUrl = sourceUrl.trim();

            // Une URL doit être fournie directement, pas sous forme de lien Markdown.
            if (normalizedUrl.matches("(?is)^\\[[^\\]]+\\]\\(https?://[^)]+\\)$")) {
                throw new IllegalArgumentException("Lien Markdown interdit");
            }

            // Aucun espace ou caractère blanc à l'intérieur de l'URL.
            if (normalizedUrl.chars().anyMatch(Character::isWhitespace)) {
                throw new IllegalArgumentException("Espace interdit");
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
