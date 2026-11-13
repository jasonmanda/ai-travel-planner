package com.aitravelplanner.trip;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

import static com.aitravelplanner.trip.TripDtos.CreateTripRequest;
import static com.aitravelplanner.trip.TripDtos.TripResponse;

@RestController
@RequestMapping("/api/v1/trips")
public class TripController {
    private final TripService service;

    public TripController(TripService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TripResponse create(@Valid @RequestBody CreateTripRequest r) {
        return service.create(r);
    }

    @GetMapping("/{id}")
    public TripResponse get(@PathVariable UUID id) {
        return service.get(id);
    }
}
