package com.aitravelplanner.itinerary;

import com.aitravelplanner.catalog.CatalogDeduplication;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;

@Service
public class ItineraryService {
    private static final int MAX_ITEMS_PER_DAY = 3;

    private final JdbcTemplate jdbc;

    public ItineraryService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public Map<String, Object> generate(UUID tripId, long destinationId) {
        Map<String, Object> trip = jdbc.query(
                "SELECT id, duration_days, adults, children FROM trip_requests WHERE id = ?",
                rs -> rs.next() ? Map.of(
                        "id", rs.getObject("id", UUID.class),
                        "durationDays", rs.getInt("duration_days"),
                        "travellers", rs.getInt("adults") + rs.getInt("children")) : null,
                tripId);
        if (trip == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Voyage introuvable: " + tripId);
        }

        List<Map<String, Object>> destinations = jdbc.queryForList("""
                SELECT c.id, c.name AS city, co.name AS country, co.iso_code AS "countryCode"
                FROM cities c JOIN countries co ON co.id = c.country_id
                WHERE c.id = ?
                """, destinationId);
        if (destinations.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Destination introuvable: " + destinationId);
        }
        Map<String, Object> destination = destinations.getFirst();
        int durationDays = (Integer) trip.get("durationDays");

        List<Map<String, Object>> rawCandidates = jdbc.queryForList("""
                SELECT id AS "catalogItemId", 'ATTRACTION' AS "itemType", name AS title,
                       description, latitude, longitude, geographic_area AS "geographicArea",
                       estimated_duration_minutes AS "estimatedDurationMinutes",
                       estimated_visit_cost AS "estimatedCost", cost_currency AS currency,
                       data_status AS "dataStatus", source_name AS "sourceName", source_url AS "sourceUrl",
                       NULL::VARCHAR AS "duplicateOfType", NULL::BIGINT AS "duplicateOfId",
                       NULL::VARCHAR AS "deduplicationRelation"
                FROM attractions
                WHERE city_id = ? AND active = TRUE
                UNION ALL
                SELECT act.id AS "catalogItemId", 'ACTIVITY' AS "itemType", act.name AS title,
                       act.description, act.latitude, act.longitude,
                       act.geographic_area AS "geographicArea",
                       act.estimated_duration_minutes AS "estimatedDurationMinutes",
                       act.estimated_cost AS "estimatedCost", act.cost_currency AS currency,
                       act.data_status AS "dataStatus", act.source_name AS "sourceName", act.source_url AS "sourceUrl",
                       rel.canonical_item_type AS "duplicateOfType",
                       rel.canonical_item_id AS "duplicateOfId",
                       rel.relation_type AS "deduplicationRelation"
                FROM activities act
                LEFT JOIN catalog_item_relations rel
                  ON rel.city_id = act.city_id
                 AND rel.duplicate_item_type = 'ACTIVITY'
                 AND rel.duplicate_item_id = act.id
                 AND rel.relation_type = 'SAME_EXPERIENCE'
                WHERE act.city_id = ? AND act.active = TRUE
                ORDER BY title
                """, destinationId, destinationId);
        List<Map<String, Object>> candidates =
                CatalogDeduplication.removeSemanticDuplicates(rawCandidates);

        // Re-generation replaces the previous itinerary for this trip/destination.
        jdbc.update("DELETE FROM itineraries WHERE trip_id = ? AND city_id = ?", tripId, destinationId);
        UUID itineraryId = jdbc.queryForObject("""
                INSERT INTO itineraries(trip_id, city_id, title, status)
                VALUES (?, ?, ?, 'GENERATED')
                RETURNING id
                """, UUID.class, tripId, destinationId,
                "Séjour à " + destination.get("city") + " — " + durationDays + " jours");

        List<List<Map<String, Object>>> dailyAssignments =
                ItineraryGeographicPlanner.plan(candidates, durationDays, MAX_ITEMS_PER_DAY);
        for (int day = 1; day <= durationDays; day++) {
            List<Map<String, Object>> dayItems = dailyAssignments.get(day - 1);

            String summary = dayItems.isEmpty()
                    ? "Aucune activité du catalogue n'est disponible pour cette journée. Complétez le catalogue avant de présenter un programme détaillé."
                    : "Suggestions issues du catalogue de destination. Vérifiez les horaires, tarifs et conditions avant le départ.";

            Long dayId = jdbc.queryForObject("""
                    INSERT INTO itinerary_days(itinerary_id, day_number, title, summary)
                    VALUES (?, ?, ?, ?)
                    RETURNING id
                    """, Long.class, itineraryId, day,
                    "Jour " + day + " — " + destination.get("city"), summary);

            int sequence = 1;
            for (Map<String, Object> item : dayItems) {
                jdbc.update("""
                        INSERT INTO itinerary_items(
                            day_id, sequence_number, item_type, catalog_item_id, title, description,
                            estimated_duration_minutes, estimated_cost, currency_code, data_status,
                            source_name, source_url, latitude, longitude, geographic_area
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        dayId, sequence++, item.get("itemType"), item.get("catalogItemId"),
                        item.get("title"), item.get("description"), item.get("estimatedDurationMinutes"),
                        item.get("estimatedCost"), item.get("currency"), item.get("dataStatus"),
                        item.get("sourceName"), item.get("sourceUrl"),
                        item.get("latitude"), item.get("longitude"), item.get("geographicArea"));
            }
        }
        return load(itineraryId);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> get(UUID itineraryId) {
        return load(itineraryId);
    }

    private Map<String, Object> load(UUID itineraryId) {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT i.id, i.trip_id AS "tripId", i.city_id AS "destinationId",
                       i.title, i.status, i.generated_at AS "generatedAt",
                       c.name AS city, co.name AS country, co.iso_code AS "countryCode"
                FROM itineraries i
                JOIN cities c ON c.id = i.city_id
                JOIN countries co ON co.id = c.country_id
                WHERE i.id = ?
                """, itineraryId);
        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Itinéraire introuvable: " + itineraryId);
        }

        Map<String, Object> itinerary = new LinkedHashMap<>(rows.getFirst());
        List<Map<String, Object>> days = jdbc.queryForList("""
                SELECT id, day_number AS "dayNumber", title, summary
                FROM itinerary_days WHERE itinerary_id = ? ORDER BY day_number
                """, itineraryId);

        for (Map<String, Object> day : days) {
            List<Map<String, Object>> items = jdbc.queryForList("""
                    SELECT id, sequence_number AS "sequence", item_type AS "type",
                           catalog_item_id AS "catalogItemId", title, description,
                           estimated_duration_minutes AS "estimatedDurationMinutes",
                           estimated_cost AS "estimatedCost", currency_code AS currency,
                           data_status AS "dataStatus", source_name AS "sourceName",
                           source_url AS "sourceUrl", latitude, longitude,
                           geographic_area AS "geographicArea"
                    FROM itinerary_items
                    WHERE day_id = ? ORDER BY sequence_number
                    """, day.get("id"));
            day.put("items", items);
        }

        itinerary.put("days", days);
        itinerary.put("estimateDisclaimer",
                "Les montants sont des estimations indicatives lorsqu'ils sont renseignés. Les éléments UNVERIFIED ne sont pas des informations confirmées. Vérifiez les tarifs, horaires, disponibilités et conditions auprès des sources officielles.");
        itinerary.put("planningPolicy",
                "Le programme est construit à partir du catalogue disponible. Aucune activité, aucun prix ni horaire n'est inventé; les journées sans données restent à compléter. Les doublons explicitement identifiés sont écartés lorsque leur entrée canonique est présente.");
        return itinerary;
    }
}
