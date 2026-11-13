package com.aitravelplanner.recommendation;

import com.aitravelplanner.common.TripNotFoundException;
import com.aitravelplanner.destination.City;
import com.aitravelplanner.destination.CityRepository;
import com.aitravelplanner.trip.TripRequest;
import com.aitravelplanner.trip.TripRequestRepository;
import com.aitravelplanner.trip.TripService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class RecommendationService {
    private static final int NEUTRAL_SCORE = 70;
    private static final int INTEREST_WEIGHT = 45;
    private static final int BUDGET_WEIGHT = 40;
    private static final int STYLE_WEIGHT = 10;
    private static final int PREFERENCE_WEIGHT = 5;

    private final TripRequestRepository trips;
    private final CityRepository cities;
    private final RecommendationRepository recommendations;

    public RecommendationService(TripRequestRepository trips, CityRepository cities,
                                 RecommendationRepository recommendations) {
        this.trips = trips;
        this.cities = cities;
        this.recommendations = recommendations;
    }

    @Transactional
    public List<Map<String, Object>> generate(UUID tripId) {
        TripRequest trip = trips.findById(tripId)
                .orElseThrow(() -> new TripNotFoundException(tripId.toString()));

        List<String> interests = split(trip.getInterests());
        int travellers = trip.getAdults() + trip.getChildren();
        List<Map<String, Object>> results = new ArrayList<>();

        for (City city : cities.findAllByOrderByNameAsc()) {
            List<String> tags = split(city.getTags());
            List<String> matchedInterests = interests.stream()
                    .filter(interest -> containsIgnoreCase(tags, interest))
                    .toList();

            int interestScore = interests.isEmpty()
                    ? NEUTRAL_SCORE
                    : percentage(matchedInterests.size(), interests.size());

            BigDecimal estimatedTripBudget = city.getEstimatedDailyBudget()
                    .multiply(BigDecimal.valueOf(trip.getDurationDays()))
                    .multiply(BigDecimal.valueOf(travellers))
                    .setScale(0, RoundingMode.HALF_UP);

            boolean comparableCurrency = city.getEstimatedDailyBudgetCurrency() != null
                    && city.getEstimatedDailyBudgetCurrency().equalsIgnoreCase(trip.getCurrency());

            int budgetScore = comparableCurrency
                    ? calculateBudgetScore(trip.getBudget(), estimatedTripBudget)
                    : NEUTRAL_SCORE;

            int styleScore = calculateStyleScore(trip.getTravelStyle(), tags);
            int preferenceScore = calculatePreferenceScore(trip.getPreferredDestination(), city);

            int totalScore = weightedScore(interestScore, budgetScore, styleScore, preferenceScore);
            String budgetStatus = !comparableCurrency
                    ? "CURRENCY_NOT_COMPARABLE"
                    : estimatedTripBudget.compareTo(trip.getBudget()) <= 0
                    ? "WITHIN_BUDGET" : "OVER_BUDGET_ESTIMATE";

            String explanation = buildExplanation(matchedInterests, interests, comparableCurrency,
                    budgetStatus, trip.getTravelStyle(), trip.getPreferredDestination());

            Recommendation saved = recommendations.save(new Recommendation(
                    trip, city, totalScore, estimatedTripBudget, budgetStatus, explanation));

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", saved.getId());
            item.put("destinationId", city.getId());
            item.put("city", city.getName());
            item.put("country", city.getCountry().getName());
            item.put("countryCode", city.getCountry().getIsoCode());
            item.put("score", totalScore);
            item.put("scoreBreakdown", Map.of(
                    "interests", interestScore,
                    "budget", budgetScore,
                    "travelStyle", styleScore,
                    "preferredDestination", preferenceScore));
            item.put("estimatedTripBudget", estimatedTripBudget);
            item.put("currency", city.getEstimatedDailyBudgetCurrency());
            item.put("requestedBudget", trip.getBudget());
            item.put("requestedBudgetCurrency", trip.getCurrency());
            item.put("budgetStatus", budgetStatus);
            item.put("matchedInterests", matchedInterests);
            item.put("explanation", explanation);
            item.put("estimateBasis", "Budget journalier catalogue × durée × nombre de voyageurs");
            item.put("estimateLimitations", "Estimation indicative. Le catalogue ne détaille pas encore les composantes incluses; vols, hébergement, repas, activités et formalités doivent être vérifiés séparément.");
            item.put("notEvaluatedCriteria", List.of("nationality_and_entry_formalities", "travel_period_and_seasonality", "departure_transport_cost", "destination_scope"));
            item.put("latitude", city.getLatitude());
            item.put("longitude", city.getLongitude());
            item.put("generatedAt", saved.getGeneratedAt());
            results.add(item);
        }

        results.sort(Comparator.comparingInt((Map<String, Object> item) -> (Integer) item.get("score")).reversed());
        return results.stream().limit(10).toList();
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> find(UUID tripId) {
        if (!trips.existsById(tripId)) {
            throw new TripNotFoundException(tripId.toString());
        }
        return recommendations.findByTripIdOrderByScoreDesc(tripId).stream().map(r -> {
            City city = r.getCity();
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", r.getId());
            item.put("destinationId", city.getId());
            item.put("city", city.getName());
            item.put("country", city.getCountry().getName());
            item.put("countryCode", city.getCountry().getIsoCode());
            item.put("score", r.getScore());
            item.put("estimatedTripBudget", r.getEstimatedTripBudget());
            item.put("currency", city.getEstimatedDailyBudgetCurrency());
            item.put("budgetStatus", r.getBudgetStatus());
            item.put("explanation", r.getExplanation());
            item.put("generatedAt", r.getGeneratedAt());
            return item;
        }).toList();
    }

    private int calculateBudgetScore(BigDecimal requested, BigDecimal estimate) {
        if (estimate.signum() <= 0) return 0;
        if (estimate.compareTo(requested) <= 0) return 100;
        return requested.multiply(BigDecimal.valueOf(100))
                .divide(estimate, 0, RoundingMode.HALF_UP)
                .intValue();
    }

    private int calculateStyleScore(String style, List<String> tags) {
        if (style == null || style.isBlank()) return NEUTRAL_SCORE;
        List<String> expectedTags = styleTags(style);
        if (expectedTags.isEmpty()) return NEUTRAL_SCORE;
        long matches = expectedTags.stream().filter(tag -> containsIgnoreCase(tags, tag)).count();
        return percentage((int) matches, expectedTags.size());
    }

    private List<String> styleTags(String style) {
        String normalized = normalize(style);
        if (normalized.contains("famille")) return List.of("famille", "plage", "nature", "culture", "detente");
        if (normalized.contains("aventure")) return List.of("aventure", "nature", "randonnee", "sport");
        if (normalized.contains("culture") || normalized.contains("decouverte"))
            return List.of("culture", "histoire", "gastronomie");
        if (normalized.contains("romantique") || normalized.contains("couple"))
            return List.of("plage", "detente", "gastronomie");
        if (normalized.contains("detente") || normalized.contains("repos"))
            return List.of("plage", "detente", "bien-etre");
        if (normalized.contains("gastronomie")) return List.of("gastronomie", "culture");
        return List.of();
    }

    private int calculatePreferenceScore(String preferred, City city) {
        if (preferred == null || preferred.isBlank()) return NEUTRAL_SCORE;
        String query = normalize(preferred);
        return normalize(city.getName()).contains(query)
                || normalize(city.getCountry().getName()).contains(query) ? 100 : 0;
    }

    private int weightedScore(int interests, int budget, int style, int preference) {
        return (int) Math.round((interests * INTEREST_WEIGHT
                + budget * BUDGET_WEIGHT
                + style * STYLE_WEIGHT
                + preference * PREFERENCE_WEIGHT) / 100.0);
    }

    private String buildExplanation(List<String> matched, List<String> requested,
                                    boolean comparableCurrency, String budgetStatus,
                                    String style, String preferred) {
        List<String> reasons = new ArrayList<>();
        if (requested.isEmpty()) reasons.add("aucun intérêt particulier n'a été renseigné");
        else if (matched.isEmpty()) reasons.add("aucun intérêt renseigné ne correspond aux tags de cette destination");
        else reasons.add("intérêts correspondants : " + String.join(", ", matched));

        if (!comparableCurrency)
            reasons.add("budget non comparé : la devise du catalogue et celle de la demande sont différentes");
        else if ("WITHIN_BUDGET".equals(budgetStatus)) reasons.add("estimation catalogue dans le budget demandé");
        else reasons.add("estimation catalogue supérieure au budget demandé");

        if (style != null && !style.isBlank())
            reasons.add("style de voyage pris en compte à partir des tags du catalogue");
        if (preferred != null && !preferred.isBlank()) reasons.add("destination préférée prise en compte");
        reasons.add("nationalité, saison et transport au départ non évalués faute de données vérifiées");
        return String.join(". ", reasons) + ".";
    }

    private int percentage(int numerator, int denominator) {
        if (denominator <= 0) return NEUTRAL_SCORE;
        return (int) Math.round(numerator * 100.0 / denominator);
    }

    private boolean containsIgnoreCase(List<String> values, String expected) {
        String normalized = normalize(expected);
        return values.stream().map(this::normalize).anyMatch(normalized::equals);
    }

    private String normalize(String value) {
        return java.text.Normalizer.normalize(value == null ? "" : value, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT).trim();
    }

    private List<String> split(String csv) {
        if (csv == null || csv.isBlank()) return List.of();
        return Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .collect(Collectors.toList());
    }
}
