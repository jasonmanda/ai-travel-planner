package com.aitravelplanner.catalog;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.sql.Array;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/catalog")
public class CatalogVerificationHistoryController {

    private static final int MAX_PAGE_SIZE = 100;
    private final JdbcTemplate jdbc;

    public CatalogVerificationHistoryController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/attractions/{id}/verifications")
    public Map<String, Object> getAttractionVerifications(
            @PathVariable long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return getHistory("attractions", "attraction_verification_history", "attraction_id",
                id, page, size);
    }

    @GetMapping("/activities/{id}/verifications")
    public Map<String, Object> getActivityVerifications(
            @PathVariable long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return getHistory("activities", "activity_verification_history", "activity_id",
                id, page, size);
    }

    private Map<String, Object> getHistory(
            String itemTable, String historyTable, String foreignKey,
            long itemId, int page, int size) {

        if (itemId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Identifiant invalide");
        }
        if (page < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "page doit être positif ou nul");
        }
        if (size < 1 || size > MAX_PAGE_SIZE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "size doit être compris entre 1 et " + MAX_PAGE_SIZE);
        }

        Long itemCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM " + itemTable + " WHERE id = ?", Long.class, itemId);
        if (itemCount == null || itemCount == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Élément du catalogue introuvable");
        }

        Long totalElements = jdbc.queryForObject(
                "SELECT COUNT(*) FROM " + historyTable + " WHERE " + foreignKey + " = ?",
                Long.class, itemId);
        if (totalElements == null) {
            totalElements = 0L;
        }

        long offset = (long) page * size;
        String sql = "SELECT id, " + foreignKey
                + " AS item_id, verification_status, verified_fields, source_name, source_url,"
                + " verification_notes, verified_by, verified_at"
                + " FROM " + historyTable + " WHERE " + foreignKey + " = ?"
                + " ORDER BY verified_at DESC, id DESC LIMIT ? OFFSET ?";

        List<Map<String, Object>> content = jdbc.query(sql, (resultSet, rowNum) -> {
            Map<String, Object> event = new LinkedHashMap<>();
            event.put("id", resultSet.getLong("id"));
            event.put("itemId", resultSet.getLong("item_id"));
            event.put("verificationStatus", resultSet.getString("verification_status"));
            Array sqlArray = resultSet.getArray("verified_fields");
            try {
                Object[] fields = sqlArray == null ? new Object[0] : (Object[]) sqlArray.getArray();
                event.put("verifiedFields", Arrays.stream(fields).map(String::valueOf).toList());
            } finally {
                if (sqlArray != null) {
                    sqlArray.free();
                }
            }
            event.put("sourceName", resultSet.getString("source_name"));
            event.put("sourceUrl", resultSet.getString("source_url"));
            event.put("verificationNotes", resultSet.getString("verification_notes"));
            event.put("verifiedBy", resultSet.getString("verified_by"));
            event.put("verifiedAt", resultSet.getObject("verified_at"));
            return event;
        }, itemId, size, offset);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("itemId", itemId);
        response.put("content", content);
        response.put("page", page);
        response.put("size", size);
        response.put("totalElements", totalElements);
        response.put("totalPages", totalElements == 0 ? 0 : (int) Math.ceil((double) totalElements / size));
        response.put("hasNext", offset + content.size() < totalElements);
        response.put("hasPrevious", page > 0);
        return response;
    }
}
