package com.aitravelplanner.itinerary;

import java.util.ArrayList;
import java.util.List;

/**
 * Distributes available catalog entries across the trip without creating
 * activities or exceeding the configured daily item limit.
 */
final class ItineraryDistribution {
    private ItineraryDistribution() {
    }

    static <T> List<List<T>> distribute(List<T> items, int dayCount, int maxItemsPerDay) {
        if (dayCount < 1) {
            throw new IllegalArgumentException("dayCount must be greater than zero");
        }
        if (maxItemsPerDay < 1) {
            throw new IllegalArgumentException("maxItemsPerDay must be greater than zero");
        }

        List<List<T>> days = new ArrayList<>(dayCount);
        for (int day = 0; day < dayCount; day++) {
            days.add(new ArrayList<>());
        }

        int itemCount = Math.min(items.size(), dayCount * maxItemsPerDay);
        for (int itemIndex = 0; itemIndex < itemCount; itemIndex++) {
            int dayIndex = (int) ((long) itemIndex * dayCount / itemCount);
            days.get(dayIndex).add(items.get(itemIndex));
        }

        return days;
    }
}
