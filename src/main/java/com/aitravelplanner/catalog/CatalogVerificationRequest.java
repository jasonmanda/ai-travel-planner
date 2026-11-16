package com.aitravelplanner.catalog;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CatalogVerificationRequest(
        @NotNull VerificationStatus verificationStatus,
        @NotEmpty List<@NotBlank @Size(max = 80) String> verifiedFields,
        @NotBlank @Size(max = 180) String sourceName,
        @NotBlank @Size(max = 1000) String sourceUrl,
        @NotBlank @Size(max = 1200) String verificationNotes
) {
    public enum VerificationStatus {
        VERIFIED,
        PARTIALLY_VERIFIED,
        REJECTED
    }
}
