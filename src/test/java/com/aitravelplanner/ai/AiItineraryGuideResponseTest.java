package com.aitravelplanner.ai;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AiItineraryGuideResponseTest {

    @Test
    void responseKeepsStructuredDayGuidance() {
        AiItineraryGuideResponse response = new AiItineraryGuideResponse(
                "Programme culturel et détente.",
                List.of(new AiItineraryGuideResponse.DayGuidance(1, "Découverte", "Regrouper les visites prévues.")),
                List.of("Vérifier les horaires auprès des sources."),
                "Contenu indicatif.");

        assertEquals(1, response.dayGuidance().getFirst().dayNumber());
        assertEquals("Découverte", response.dayGuidance().getFirst().focus());
        assertEquals(1, response.reminders().size());
    }
}
