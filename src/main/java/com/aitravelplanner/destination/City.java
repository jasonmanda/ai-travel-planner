package com.aitravelplanner.destination;

import jakarta.persistence.*;

import java.math.BigDecimal;

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

    @Column(name = "estimated_daily_budget", nullable = false, precision = 12, scale = 2)
    private BigDecimal estimatedDailyBudget;

    @Column(name = "estimated_daily_budget_currency", nullable = false, length = 3)
    private String estimatedDailyBudgetCurrency;

    @Column(length = 500)
    private String tags;

    private Double latitude;
    private Double longitude;

    protected City() {
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Country getCountry() {
        return country;
    }

    public String getDescription() {
        return description;
    }

    public BigDecimal getEstimatedDailyBudget() {
        return estimatedDailyBudget;
    }

    public String getEstimatedDailyBudgetCurrency() {
        return estimatedDailyBudgetCurrency;
    }

    public String getTags() {
        return tags;
    }

    public Double getLatitude() {
        return latitude;
    }

    public Double getLongitude() {
        return longitude;
    }
}
