package com.aitravelplanner.ai;

import com.aitravelplanner.itinerary.ItineraryService;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@ConditionalOnProperty(prefix = "app.ai", name = "enabled", havingValue = "true")
public class AiItineraryGuideService {
    private static final String DISCLAIMER =
            "Contenu généré par IA à titre d'aide à la préparation. Les sources, tarifs, horaires, accès, formalités et disponibilités doivent être vérifiés auprès des organismes compétents. L'IA ne confirme aucune information absente du catalogue.";

    private static final String SYSTEM_PROMPT = """
            Tu es un assistant de préparation de voyage prudent et francophone.
            Tu dois uniquement interpréter et organiser les informations présentes dans le contexte fourni.
            N'invente jamais de lieux, prix, horaires, distances, durées, moyens de transport, règles de visa,
            conditions d'accès, disponibilités, coordonnées ou faits historiques.
            Ne transforme jamais une donnée ESTIMATED ou UNVERIFIED en fait confirmé.
            Ne présente jamais une source opérateur comme une validation institutionnelle.
            Si les données sont insuffisantes, dis-le explicitement et formule un rappel de vérification.
            Les jours et activités du programme fourni ne doivent pas être remplacés par des lieux externes.
            Réponds en français, de façon concise et pratique. Le champ disclaimer sera remplacé côté serveur.
            """;

    private final ChatClient chatClient;
    private final ItineraryService itineraries;

    public AiItineraryGuideService(ChatClient.Builder chatClientBuilder, ItineraryService itineraries) {
        this.chatClient = chatClientBuilder.build();
        this.itineraries = itineraries;
    }

    public AiItineraryGuideResponse generate(UUID itineraryId) {
        Map<String, Object> itinerary = itineraries.get(itineraryId);
        List<Map<String, Object>> days = castDays(itinerary.get("days"));
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("destination", Map.of(
                "city", String.valueOf(itinerary.getOrDefault("city", "")),
                "country", String.valueOf(itinerary.getOrDefault("country", "")),
                "countryCode", String.valueOf(itinerary.getOrDefault("countryCode", ""))));
        context.put("durationDays", days.size());
        context.put("days", days.stream().map(this::safeDayContext).toList());
        context.put("planningPolicy", itinerary.get("planningPolicy"));
        context.put("estimateDisclaimer", itinerary.get("estimateDisclaimer"));

        AiItineraryGuideResponse generated = chatClient.prompt()
                .system(SYSTEM_PROMPT)
                .user("Prépare un guide de lecture du programme ci-dessous. N'ajoute aucun élément au programme. "
                        + "Retourne un objet structuré avec overview, dayGuidance (dayNumber, focus, rationale) "
                        + "et reminders. Contexte factuel : " + context)
                .call()
                .entity(AiItineraryGuideResponse.class);

        if (generated == null) {
            throw new IllegalStateException("Le modèle IA n'a retourné aucun guide.");
        }

        List<Integer> validDays = days.stream()
                .map(day -> ((Number) day.get("dayNumber")).intValue()).toList();
        List<AiItineraryGuideResponse.DayGuidance> safeGuidance =
                generated.dayGuidance() == null ? List.of() : generated.dayGuidance().stream()
                        .filter(guidance -> guidance != null && validDays.contains(guidance.dayNumber()))
                        .limit(days.size())
                        .toList();
        List<String> safeReminders = generated.reminders() == null ? List.of()
                : generated.reminders().stream()
                        .filter(value -> value != null && !value.isBlank())
                        .limit(6)
                        .map(value -> value.length() > 240 ? value.substring(0, 237) + "..." : value)
                        .toList();

        return new AiItineraryGuideResponse(
                safeText(generated.overview(), 1200),
                safeGuidance,
                safeReminders,
                DISCLAIMER);
    }

    private Map<String, Object> safeDayContext(Map<String, Object> day) {
        Map<String, Object> safe = new LinkedHashMap<>();
        safe.put("dayNumber", day.get("dayNumber"));
        safe.put("title", day.get("title"));
        List<Map<String, Object>> items = castItems(day.get("items"));
        safe.put("items", items.stream().map(item -> {
            Map<String, Object> selected = new LinkedHashMap<>();
            for (String key : List.of("type", "title", "description", "estimatedDurationMinutes",
                    "estimatedCost", "currency", "dataStatus", "sourceName", "sourceUrl",
                    "priceVerificationStatus")) {
                if (item.containsKey(key)) selected.put(key, item.get(key));
            }
            return selected;
        }).toList());
        return safe;
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> castDays(Object value) {
        return value instanceof List<?> list
                ? list.stream().filter(Map.class::isInstance)
                    .map(item -> (Map<String, Object>) item).toList()
                : List.of();
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> castItems(Object value) {
        return value instanceof List<?> list
                ? list.stream().filter(Map.class::isInstance)
                    .map(item -> (Map<String, Object>) item).toList()
                : List.of();
    }

    private String safeText(String value, int maxLength) {
        if (value == null || value.isBlank()) return "Les informations du programme sont insuffisantes pour produire une synthèse fiable.";
        return value.length() > maxLength ? value.substring(0, maxLength - 3) + "..." : value;
    }
}
