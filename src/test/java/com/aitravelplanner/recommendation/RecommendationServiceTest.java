package com.aitravelplanner.recommendation;

import com.aitravelplanner.common.TripNotFoundException;
import com.aitravelplanner.destination.CityRepository;
import com.aitravelplanner.trip.TripRequest;
import com.aitravelplanner.trip.TripRequestRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertTrue;
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
        service = new RecommendationService(trips, cities, recommendations);
    }

    @Test
    void generateReplacesPreviousRecommendationsBeforeSavingNewOnes() {
        UUID tripId = UUID.randomUUID();
        TripRequest trip = mock(TripRequest.class);
        when(trips.findById(tripId)).thenReturn(Optional.of(trip));
        when(trip.getAdults()).thenReturn(1);
        when(trip.getChildren()).thenReturn(0);
        when(trip.getInterests()).thenReturn("");
        when(trip.getDurationDays()).thenReturn(5);
        when(trip.getBudget()).thenReturn(new BigDecimal("500000"));
        when(trip.getCurrency()).thenReturn("XOF");
        when(trip.getTravelStyle()).thenReturn(null);
        when(trip.getPreferredDestination()).thenReturn(null);
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

        org.junit.jupiter.api.Assertions.assertThrows(
                TripNotFoundException.class, () -> service.generate(tripId));

        verifyNoInteractions(recommendations);
        verifyNoInteractions(cities);
    }
}
