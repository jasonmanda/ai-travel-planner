package com.aitravelplanner.itinerary;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ItineraryDistributionTest {

    @Test
    void spreadsFourCatalogItemsAcrossSevenDays() {
        List<String> items = List.of("A", "B", "C", "D");

        List<List<String>> days = ItineraryDistribution.distribute(items, 7, 3);

        assertEquals(7, days.size());
        assertEquals(List.of(1, 1, 0, 1, 0, 1, 0),
                days.stream().map(List::size).toList());
        assertEquals(items, days.stream().flatMap(List::stream).toList());
    }

    @Test
    void distributesTwelveItemsAcrossSevenDaysWithoutExceedingDailyLimit() {
        List<Integer> items = java.util.stream.IntStream.rangeClosed(1, 12)
                .boxed()
                .toList();

        List<List<Integer>> days = ItineraryDistribution.distribute(items, 7, 3);

        assertEquals(7, days.size());
        assertEquals(List.of(2, 2, 2, 1, 2, 2, 1),
                days.stream().map(List::size).toList());
        assertEquals(items, days.stream().flatMap(List::stream).toList());
        days.forEach(day -> org.junit.jupiter.api.Assertions.assertTrue(day.size() <= 3));
    }

    @Test
    void capsItemsAtMaximumCapacityWithoutDuplicatingEntries() {
        List<Integer> items = java.util.stream.IntStream.rangeClosed(1, 25)
                .boxed()
                .toList();

        List<List<Integer>> days = ItineraryDistribution.distribute(items, 7, 3);

        assertEquals(21, days.stream().mapToInt(List::size).sum());
        assertEquals(items.subList(0, 21), days.stream().flatMap(List::stream).toList());
        days.forEach(day -> org.junit.jupiter.api.Assertions.assertTrue(day.size() <= 3));
    }

    @Test
    void keepsAllDaysWhenCatalogIsEmpty() {
        List<List<String>> days = ItineraryDistribution.distribute(List.of(), 7, 3);

        assertEquals(7, days.size());
        days.forEach(List::isEmpty);
    }

    @Test
    void rejectsInvalidDayCount() {
        assertThrows(IllegalArgumentException.class,
                () -> ItineraryDistribution.distribute(List.of("A"), 0, 3));
    }
}
