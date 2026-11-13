package com.aitravelplanner.catalog;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/destinations/{cityId}/catalog")
public class TravelCatalogController {
    private final JdbcTemplate jdbc;

    public TravelCatalogController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping
    public Map<String, Object> getCatalog(@PathVariable long cityId) {
        Map<String, Object> city = findCity(cityId);
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("destination", city);
        response.put("attractions", attractions(cityId));
        response.put("activities", activities(cityId));
        response.put("budget", budget(cityId));
        response.put("seasons", seasons(cityId));
        response.put("dataPolicy", "Les données non vérifiées sont signalées. Les montants absents ne sont pas estimés automatiquement.");
        return response;
    }

    @GetMapping("/attractions")
    public List<Map<String, Object>> getAttractions(@PathVariable long cityId) {
        ensureCityExists(cityId);
        return attractions(cityId);
    }

    @GetMapping("/activities")
    public List<Map<String, Object>> getActivities(@PathVariable long cityId) {
        ensureCityExists(cityId);
        return activities(cityId);
    }

    @GetMapping("/budget")
    public List<Map<String, Object>> getBudget(@PathVariable long cityId) {
        ensureCityExists(cityId);
        return budget(cityId);
    }

    @GetMapping("/seasons")
    public List<Map<String, Object>> getSeasons(@PathVariable long cityId) {
        ensureCityExists(cityId);
        return seasons(cityId);
    }

    private Map<String, Object> findCity(long cityId) {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT c.id, c.name AS city, co.name AS country, co.iso_code AS "countryCode",
                       c.description, c.latitude, c.longitude,
                       c.estimated_daily_budget AS "catalogDailyBudget",
                       c.estimated_daily_budget_currency AS "catalogDailyBudgetCurrency"
                FROM cities c JOIN countries co ON co.id = c.country_id
                WHERE c.id = ?
                """, cityId);
        if (rows.isEmpty())
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Destination introuvable: " + cityId);
        return rows.getFirst();
    }

    private void ensureCityExists(long cityId) {
        findCity(cityId);
    }

    private List<Map<String, Object>> attractions(long cityId) {
        return jdbc.queryForList("""
                SELECT id, name, category, description, latitude, longitude,
                       estimated_visit_cost AS "estimatedCost", cost_currency AS currency,
                       estimated_duration_minutes AS "estimatedDurationMinutes",
                       data_status AS "dataStatus", source_name AS "sourceName",
                       source_url AS "sourceUrl", last_verified_at AS "lastVerifiedAt"
                FROM attractions WHERE city_id = ? AND active = TRUE ORDER BY name
                """, cityId);
    }

    private List<Map<String, Object>> activities(long cityId) {
        return jdbc.queryForList("""
                SELECT id, name, category, description,
                       estimated_duration_minutes AS "estimatedDurationMinutes",
                       estimated_cost AS "estimatedCost", cost_currency AS currency,
                       suitable_for_families AS "suitableForFamilies", min_age_years AS "minAgeYears",
                       data_status AS "dataStatus", source_name AS "sourceName",
                       source_url AS "sourceUrl", last_verified_at AS "lastVerifiedAt"
                FROM activities WHERE city_id = ? AND active = TRUE ORDER BY category, name
                """, cityId);
    }

    private List<Map<String, Object>> budget(long cityId) {
        return jdbc.queryForList("""
                SELECT component_key AS "componentKey", label, estimated_amount AS "estimatedAmount",
                       currency_code AS currency, pricing_basis AS "pricingBasis",
                       data_status AS "dataStatus", source_name AS "sourceName",
                       source_url AS "sourceUrl", last_verified_at AS "lastVerifiedAt"
                FROM city_budget_components WHERE city_id = ? ORDER BY component_key
                """, cityId);
    }

    private List<Map<String, Object>> seasons(long cityId) {
        return jdbc.queryForList("""
                SELECT month_number AS month, season_type AS "seasonType", summary,
                       data_status AS "dataStatus", source_name AS "sourceName",
                       source_url AS "sourceUrl", last_verified_at AS "lastVerifiedAt"
                FROM city_seasons WHERE city_id = ? ORDER BY month_number
                """, cityId);
    }
}
