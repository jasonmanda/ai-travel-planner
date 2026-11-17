package com.aitravelplanner.recommendation;

import com.aitravelplanner.common.TripNotFoundException;
import com.aitravelplanner.destination.City;
import com.aitravelplanner.destination.CityRepository;
import com.aitravelplanner.destination.Country;
import com.aitravelplanner.trip.TripRequest;
import com.aitravelplanner.trip.TripRequestRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class RecommendationServiceTest {

    private TripRequestRepository trips;
    private CityRepository cities;
    private RecommendationRepository recommendations;
    private RecommendationService service;

    @BeforeEach
    void setUp() {
        trips = mock(TripRequestRepository.class);
        cities = mock(CityRepository.class);
        recommendations = mock(RecommendationRepository.class);
        when(recommendations.save(any(Recommendation.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        service = new RecommendationService(trips, cities, recommendations);
    }

    @Test
    void generateReplacesPreviousRecommendationsBeforeSavingNewOnes() {
        UUID tripId = UUID.randomUUID();
        TripRequest trip = mockTrip();
        when(trips.findById(tripId)).thenReturn(Optional.of(trip));
        when(cities.findAllByOrderByNameAsc()).thenReturn(List.of());

        assertTrue(service.generate(tripId).isEmpty());

        var order = inOrder(recommendations, cities);
        order.verify(recommendations).deleteByTripId(tripId);
        order.verify(recommendations).flush();
        order.verify(cities).findAllByOrderByNameAsc();
        verify(recommendations, never()).save(any(Recommendation.class));
    }

    @Test
    void generateDoesNotDeleteRecommendationsWhenTripDoesNotExist() {
        UUID tripId = UUID.randomUUID();
        when(trips.findById(tripId)).thenReturn(Optional.empty());

        assertThrows(TripNotFoundException.class, () -> service.generate(tripId));

        verifyNoInteractions(recommendations);
        verifyNoInteractions(cities);
    }

    @Test
    void indicativeBudgetsAreDisplayedButDoNotInfluenceRecommendationScore() {
        UUID tripId = UUID.randomUUID();
        TripRequest trip = mockTrip();
        when(trips.findById(tripId)).thenReturn(Optional.of(trip));
        City cheap = mockCity("INDICATIVE", "100");
        City expensive = mockCity("INDICATIVE", "900000");
        when(cities.findAllByOrderByNameAsc()).thenReturn(List.of(cheap, expensive));

        List<Map<String, Object>> result = service.generate(tripId);

        assertEquals(2, result.size());
        assertEquals(70, ((Map<?, ?>) result.get(0).get("scoreBreakdown")).get("budget"));
        assertEquals(70, ((Map<?, ?>) result.get(1).get("scoreBreakdown")).get("budget"));
        assertEquals(result.get(0).get("score"), result.get(1).get("score"));
        assertEquals("INDICATIVE_NOT_USED_IN_SCORE", result.get(0).get("budgetStatus"));
        assertEquals(new BigDecimal("500"), result.get(0).get("estimatedTripBudget"));
        assertEquals("INDICATIVE", result.get(0).get("budgetEstimateStatus"));
        assertEquals("XOF", result.get(0).get("currency"));
    }

    @Test
    void verifiedComparableBudgetCanInfluenceRecommendationScore() {
        UUID tripId = UUID.randomUUID();
        TripRequest trip = mockTrip();
        when(trips.findById(tripId)).thenReturn(Optional.of(trip));
        City verified = mockCity("VERIFIED", "100");
        when(verified.getEstimatedDailyBudgetVerifiedAt()).thenReturn(java.time.Instant.parse("2026-01-01T00:00:00Z"));
        when(verified.getEstimatedDailyBudgetSourceName()).thenReturn("Official source");
        when(verified.getEstimatedDailyBudgetSourceUrl()).thenReturn("https://example.org/prices");
        when(cities.findAllByOrderByNameAsc()).thenReturn(List.of(verified));

        Map<String, Object> result = service.generate(tripId).get(0);

        assertEquals(100, ((Map<?, ?>) result.get("scoreBreakdown")).get("budget"));
        assertEquals("WITHIN_BUDGET", result.get("budgetStatus"));
        assertEquals("Official source", result.get("budgetSourceName"));
        assertEquals("https://example.org/prices", result.get("budgetSourceUrl"));
        assertEquals("XOF", result.get("currency"));
        assertEquals(java.time.Instant.parse("2026-01-01T00:00:00Z"), result.get("budgetVerifiedAt"));
    }

    @Test
    void unknownBudgetDoesNotCreateAnArtificialZeroEstimate() {
        UUID tripId = UUID.randomUUID();
        TripRequest trip = mockTrip();
        when(trips.findById(tripId)).thenReturn(Optional.of(trip));
        City unknown = mockCity("UNKNOWN", null);
        when(unknown.getEstimatedDailyBudgetCurrency()).thenReturn(null);
        when(cities.findAllByOrderByNameAsc()).thenReturn(List.of(unknown));

        Map<String, Object> result = service.generate(tripId).get(0);

        assertNull(result.get("estimatedTripBudget"));
        assertEquals("ESTIMATE_NOT_AVAILABLE", result.get("budgetStatus"));
        assertEquals(70, ((Map<?, ?>) result.get("scoreBreakdown")).get("budget"));
    }
 
    @Test
    void findReturnsPersistedBudgetSnapshotInsteadOfCurrentCityMetadata() {
        UUID tripId = UUID.randomUUID();
        TripRequest trip = mockTrip();
        City city = mockCity("INDICATIVE", "90000");
        when(city.getEstimatedDailyBudgetStatus()).thenReturn("VERIFIED");
        when(city.getEstimatedDailyBudgetSourceName()).thenReturn("New source");
        when(city.getEstimatedDailyBudgetSourceUrl()).thenReturn("https://new.example.org");
        when(city.getEstimatedDailyBudgetVerifiedAt())
                .thenReturn(java.time.Instant.parse("2026-11-17T00:00:00Z"));

        Recommendation recommendation = mock(Recommendation.class);
        when(recommendation.getId()).thenReturn(12L);
        when(recommendation.getCity()).thenReturn(city);
        when(recommendation.getScore()).thenReturn(80);
        when(recommendation.getEstimatedTripBudget()).thenReturn(new BigDecimal("450000"));
        when(recommendation.getBudgetStatus()).thenReturn("INDICATIVE_NOT_USED_IN_SCORE");
        when(recommendation.getBudgetEstimateStatus()).thenReturn("INDICATIVE");
        when(recommendation.getBudgetCurrency()).thenReturn("XOF");
        when(recommendation.getBudgetSourceName()).thenReturn(null);
        when(recommendation.getBudgetSourceUrl()).thenReturn(null);
        when(recommendation.getBudgetVerifiedAt()).thenReturn(null);
        when(recommendation.getBudgetEstimateNotes()).thenReturn("Old indicative scope");
        when(recommendation.getExplanation()).thenReturn("Budget indicatif.");
        when(recommendation.getGeneratedAt())
                .thenReturn(java.time.Instant.parse("2026-11-16T00:00:00Z"));
        when(trips.existsById(tripId)).thenReturn(true);
        when(recommendations.findByTripIdOrderByScoreDesc(tripId))
                .thenReturn(List.of(recommendation));

        Map<String, Object> result = service.find(tripId).get(0);

        assertEquals("INDICATIVE", result.get("budgetEstimateStatus"));
        assertEquals("XOF", result.get("currency"));
        assertNull(result.get("budgetSourceName"));
        assertNull(result.get("budgetSourceUrl"));
        assertNull(result.get("budgetVerifiedAt"));
        assertEquals("Old indicative scope", result.get("budgetEstimateNotes"));
        assertEquals(new BigDecimal("450000"), result.get("estimatedTripBudget"));
    }

    private TripRequest mockTrip() {
        TripRequest trip = mock(TripRequest.class);
        when(trip.getAdults()).thenReturn(1);
        when(trip.getChildren()).thenReturn(0);
        when(trip.getInterests()).thenReturn("");
        when(trip.getDurationDays()).thenReturn(5);
        when(trip.getBudget()).thenReturn(new BigDecimal("500000"));
        when(trip.getCurrency()).thenReturn("XOF");
        when(trip.getTravelStyle()).thenReturn(null);
        when(trip.getPreferredDestination()).thenReturn(null);
        return trip;
    }

    private City mockCity(String status, String dailyBudget) {
        City city = mock(City.class);
        Country country = mock(Country.class);
        when(country.getName()).thenReturn("Test country");
        when(country.getIsoCode()).thenReturn("TC");
        when(city.getName()).thenReturn("Test city");
        when(city.getCountry()).thenReturn(country);
        when(city.getTags()).thenReturn("");
        when(city.getEstimatedDailyBudgetStatus()).thenReturn(status);
        when(city.getEstimatedDailyBudget()).thenReturn(
                dailyBudget == null ? null : new BigDecimal(dailyBudget));
        when(city.getEstimatedDailyBudgetCurrency()).thenReturn(
                dailyBudget == null ? null : "XOF");
        return city;
    }
}
