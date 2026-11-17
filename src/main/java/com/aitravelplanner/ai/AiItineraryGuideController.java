package com.aitravelplanner.ai;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/itineraries")
@ConditionalOnProperty(prefix = "app.ai", name = "enabled", havingValue = "true")
public class AiItineraryGuideController {
    private final AiItineraryGuideService service;

    public AiItineraryGuideController(AiItineraryGuideService service) {
        this.service = service;
    }

    @PostMapping("/{itineraryId}/ai-guide")
    public AiItineraryGuideResponse generate(@PathVariable UUID itineraryId) {
        return service.generate(itineraryId);
    }
}
