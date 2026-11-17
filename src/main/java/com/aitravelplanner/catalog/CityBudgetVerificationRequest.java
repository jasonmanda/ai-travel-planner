package com.aitravelplanner.catalog;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record CityBudgetVerificationRequest(
        @NotNull
        @DecimalMin("0.00")
        @Digits(integer = 10, fraction = 2)
        BigDecimal dailyBudget,

        @NotBlank
        @Pattern(regexp = "[A-Z]{3}")
        String currency,

        @NotBlank
        @Size(max = 180)
        String sourceName,

        @NotBlank
        @Size(max = 1000)
        String sourceUrl,

        @NotBlank
        @Size(max = 1000)
        String verificationNotes
) {
}
