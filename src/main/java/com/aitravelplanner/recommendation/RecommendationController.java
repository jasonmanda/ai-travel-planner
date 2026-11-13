package com.aitravelplanner.recommendation;

import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/trips/{tripId}/recommendations")
public class RecommendationController {
    private final RecommendationService service;

    public RecommendationController(RecommendationService service) {
        this.service = service;
    }

    @PostMapping
    public List<Map<String, Object>> generate(@PathVariable UUID tripId) {
        return service.generate(tripId);
    }

    @GetMapping
    public List<Map<String, Object>> find(@PathVariable UUID tripId) {
        return service.find(tripId);
    }
}
