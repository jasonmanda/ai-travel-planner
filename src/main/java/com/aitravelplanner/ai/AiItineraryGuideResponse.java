package com.aitravelplanner.ai;

import java.util.List;

public record AiItineraryGuideResponse(
        String overview,
        List<DayGuidance> dayGuidance,
        List<String> reminders,
        String disclaimer) {

    public record DayGuidance(int dayNumber, String focus, String rationale) {
    }
}
