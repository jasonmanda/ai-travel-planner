package com.aitravelplanner.trip;

import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class TripDtos {
    private TripDtos() {
    }

    public record CreateTripRequest(@NotBlank @Size(max = 150) String departureCity,
                                    @NotBlank @Size(max = 100) String nationality,
                                    @NotNull @Min(1) @Max(20) Integer adults,
                                    @NotNull @Min(0) @Max(20) Integer children,
                                    @NotNull @DecimalMin("1.00") BigDecimal budget,
                                    @Size(min = 3, max = 3) String currency, @NotNull @Min(1) @Max(90) Integer duration,
                                    @Size(max = 80) String travelPeriod, @Size(max = 80) String travelStyle,
                                    @Size(max = 80) String destinationScope, List<@Size(max = 50) String> interests,
                                    @Size(max = 150) String preferredDestination) {
    }

    public record TripResponse(UUID id, String departureCity, String nationality, Integer adults, Integer children,
                               BigDecimal budget, String currency, Integer duration, String travelPeriod,
                               String travelStyle, String destinationScope, List<String> interests,
                               String preferredDestination, Instant createdAt) {
    }
}
