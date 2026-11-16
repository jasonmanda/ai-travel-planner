package com.aitravelplanner.itinerary;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
public class ItineraryController {
    private final ItineraryService service;

    public ItineraryController(ItineraryService service) {
        this.service = service;
    }

    @PostMapping("/api/v1/trips/{tripId}/itinerary")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> generate(@PathVariable UUID tripId,
                                        @RequestParam long destinationId) {
        return service.generate(tripId, destinationId);
    }

    @GetMapping("/api/v1/itineraries/{itineraryId}")
    public Map<String, Object> get(@PathVariable UUID itineraryId) {
        return service.get(itineraryId);
    }
}
