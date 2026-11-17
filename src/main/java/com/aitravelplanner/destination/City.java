package com.aitravelplanner.destination;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "cities")
public class City {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "country_id", nullable = false)
    private Country country;

    @Column(length = 1000)
    private String description;

    @Column(name = "estimated_daily_budget", precision = 12, scale = 2)
    private BigDecimal estimatedDailyBudget;

    @Column(name = "estimated_daily_budget_currency", length = 3)
    private String estimatedDailyBudgetCurrency;

    @Column(name = "estimated_daily_budget_status", nullable = false, length = 20)
    private String estimatedDailyBudgetStatus;

    @Column(name = "estimated_daily_budget_source_name", length = 180)
    private String estimatedDailyBudgetSourceName;

    @Column(name = "estimated_daily_budget_source_url", length = 1000)
    private String estimatedDailyBudgetSourceUrl;

    @Column(name = "estimated_daily_budget_verified_at")
    private Instant estimatedDailyBudgetVerifiedAt;

    @Column(name = "estimated_daily_budget_notes", length = 1000)
    private String estimatedDailyBudgetNotes;

    @Column(length = 500)
    private String tags;

    private Double latitude;
    private Double longitude;

    protected City() {
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public Country getCountry() { return country; }
    public String getDescription() { return description; }
    public BigDecimal getEstimatedDailyBudget() { return estimatedDailyBudget; }
    public String getEstimatedDailyBudgetCurrency() { return estimatedDailyBudgetCurrency; }
    public String getEstimatedDailyBudgetStatus() { return estimatedDailyBudgetStatus; }
    public String getEstimatedDailyBudgetSourceName() { return estimatedDailyBudgetSourceName; }
    public String getEstimatedDailyBudgetSourceUrl() { return estimatedDailyBudgetSourceUrl; }
    public Instant getEstimatedDailyBudgetVerifiedAt() { return estimatedDailyBudgetVerifiedAt; }
    public String getEstimatedDailyBudgetNotes() { return estimatedDailyBudgetNotes; }
    public String getTags() { return tags; }
    public Double getLatitude() { return latitude; }
    public Double getLongitude() { return longitude; }
}
