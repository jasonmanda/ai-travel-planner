package com.aitravelplanner.catalog;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Read-only administration view of catalog records and their factual verification coverage.
 * All mutations continue to use CatalogVerificationController's guarded history workflow.
 */
@RestController
@RequestMapping("/api/v1/admin/catalog")
public class CatalogAdminController {

    private static final String ITEMS_SQL = """
            WITH catalog_items AS (
                SELECT
                    'ATTRACTION'::text AS item_type,
                    a.id,
                    co.iso_code AS country_code,
                    co.name AS country,
                    c.name AS city,
                    a.name,
                    a.category,
                    a.description,
                    a.latitude,
                    a.longitude,
                    a.estimated_duration_minutes,
                    a.estimated_visit_cost AS estimated_cost,
                    a.cost_currency AS currency,
                    a.data_status::text AS data_status,
                    a.source_name,
                    a.source_url,
                    a.source_type::text AS source_type,
                    a.source_scope::text AS source_scope,
                    a.verification_notes,
                    jsonb_build_object(
                        'name', a.name,
                        'category', a.category,
                        'description', a.description,
                        'latitude', a.latitude,
                        'longitude', a.longitude,
                        'estimated_duration_minutes', a.estimated_duration_minutes
                    ) AS current_values
                FROM attractions a
                JOIN cities c ON c.id = a.city_id
                JOIN countries co ON co.id = c.country_id
                WHERE a.active = TRUE AND a.data_status::text <> 'REJECTED'

                UNION ALL

                SELECT
                    'ACTIVITY'::text,
                    act.id,
                    co.iso_code,
                    co.name,
                    c.name,
                    act.name,
                    act.category,
                    act.description,
                    act.latitude,
                    act.longitude,
                    act.estimated_duration_minutes,
                    act.estimated_cost,
                    act.cost_currency,
                    act.data_status::text,
                    act.source_name,
                    act.source_url,
                    act.source_type::text,
                    act.source_scope::text,
                    act.verification_notes,
                    jsonb_build_object(
                        'name', act.name,
                        'category', act.category,
                        'description', act.description,
                        'latitude', act.latitude,
                        'longitude', act.longitude,
                        'estimated_duration_minutes', act.estimated_duration_minutes
                    )
                FROM activities act
                JOIN cities c ON c.id = act.city_id
                JOIN countries co ON co.id = c.country_id
                WHERE act.active = TRUE AND act.data_status::text <> 'REJECTED'
            ),
            history AS (
                SELECT
                    'ATTRACTION'::text AS item_type,
                    h.attraction_id AS item_id,
                    h.id AS event_id,
                    h.verification_status::text AS verification_status,
                    h.verified_fields,
                    h.verified_values,
                    h.source_name AS event_source_name,
                    h.source_url AS event_source_url,
                    h.verification_notes AS event_notes,
                    h.verified_by,
                    h.verified_at
                FROM attraction_verification_history h
                UNION ALL
                SELECT
                    'ACTIVITY'::text,
                    h.activity_id,
                    h.id,
                    h.verification_status::text,
                    h.verified_fields,
                    h.verified_values,
                    h.source_name,
                    h.source_url,
                    h.verification_notes,
                    h.verified_by,
                    h.verified_at
                FROM activity_verification_history h
            ),
            latest_rejection AS (
                SELECT item_type, item_id, MAX(event_id) AS event_id
                FROM history
                WHERE verification_status = 'REJECTED'
                GROUP BY item_type, item_id
            )
            SELECT
                i.item_type AS "itemType",
                i.id AS "id",
                i.country_code AS "countryCode",
                i.country AS "country",
                i.city AS "city",
                i.name AS "name",
                i.category AS "category",
                i.description AS "description",
                i.latitude AS "latitude",
                i.longitude AS "longitude",
                i.estimated_duration_minutes AS "estimatedDurationMinutes",
                i.estimated_cost AS "estimatedCost",
                i.currency AS "currency",
                i.data_status AS "dataStatus",
                i.source_name AS "sourceName",
                i.source_url AS "sourceUrl",
                i.source_type AS "sourceType",
                i.source_scope AS "sourceScope",
                i.verification_notes AS "verificationNotes",
                ARRAY(
                    SELECT required.field_name
                    FROM (VALUES
                        ('name'), ('category'), ('description'),
                        ('latitude'), ('longitude'), ('estimated_duration_minutes')
                    ) AS required(field_name)
                    WHERE EXISTS (
                        SELECT 1
                        FROM history h
                        WHERE h.item_type = i.item_type
                          AND h.item_id = i.id
                          AND h.event_id > COALESCE(lr.event_id, 0)
                          AND h.verification_status IN ('VERIFIED', 'PARTIALLY_VERIFIED')
                          AND COALESCE(h.verified_fields, ARRAY[]::text[]) @> ARRAY[required.field_name]::text[]
                          AND COALESCE(h.verified_values, '{}'::jsonb) -> required.field_name
                              = i.current_values -> required.field_name
                    )
                    ORDER BY required.field_name
                ) AS "verifiedCoreFields",
                latest.event_id AS "latestEventId",
                latest.verification_status AS "latestEventStatus",
                latest.event_source_name AS "latestEventSourceName",
                latest.event_source_url AS "latestEventSourceUrl",
                latest.event_notes AS "latestEventNotes",
                latest.verified_by AS "latestVerifiedBy",
                latest.verified_at AS "latestVerifiedAt",
                (SELECT COUNT(*) FROM history h
                 WHERE h.item_type = i.item_type AND h.item_id = i.id) AS "verificationEventCount"
            FROM catalog_items i
            LEFT JOIN latest_rejection lr
              ON lr.item_type = i.item_type AND lr.item_id = i.id
            LEFT JOIN LATERAL (
                SELECT h.*
                FROM history h
                WHERE h.item_type = i.item_type AND h.item_id = i.id
                ORDER BY h.verified_at DESC, h.event_id DESC
                LIMIT 1
            ) latest ON TRUE
            ORDER BY i.country, i.city, i.item_type, i.name
            """;

    private final JdbcTemplate jdbc;

    public CatalogAdminController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/items")
    public Map<String, Object> listItems() {
        List<Map<String, Object>> rows = jdbc.queryForList(ITEMS_SQL);
        List<Map<String, Object>> items = rows.stream().map(row -> {
            Map<String, Object> normalized = new LinkedHashMap<>(row);
            normalized.put("verifiedCoreFields", verifiedCoreFields(row.get("verifiedCoreFields")));
            return normalized;
        }).toList();
        long fullyVerified = items.stream()
                .filter(item -> verifiedCoreFieldCount(item) == 6)
                .count();
        long partiallyVerified = items.stream()
                .filter(item -> verifiedCoreFieldCount(item) > 0 && verifiedCoreFieldCount(item) < 6)
                .count();

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("items", items);
        response.put("total", items.size());
        response.put("fullyVerifiedCount", fullyVerified);
        response.put("partiallyVerifiedCount", partiallyVerified);
        response.put("unverifiedCount", items.size() - fullyVerified - partiallyVerified);
        response.put("requiredCoreFields", List.of(
                "name", "category", "description", "latitude", "longitude",
                "estimated_duration_minutes"
        ));
        response.put("policy", "A field is counted only when a non-rejected verification event stores the exact current catalog value. This endpoint is read-only.");
        return response;
    }

    private List<String> verifiedCoreFields(Object fields) {
        if (fields instanceof String[] values) {
            return List.of(values);
        }
        if (fields instanceof java.sql.Array values) {
            try {
                Object array = values.getArray();
                if (array instanceof Object[] entries) {
                    return java.util.Arrays.stream(entries).map(String::valueOf).toList();
                }
            } catch (java.sql.SQLException ignored) {
                return List.of();
            }
        }
        if (fields instanceof Object[] values) {
            return java.util.Arrays.stream(values).map(String::valueOf).toList();
        }
        if (fields instanceof List<?> values) {
            return values.stream().map(String::valueOf).toList();
        }
        return List.of();
    }

    private int verifiedCoreFieldCount(Map<String, Object> item) {
        Object fields = item.get("verifiedCoreFields");
        return fields instanceof List<?> values ? values.size() : 0;
    }
}
