package com.aitravelplanner.trip;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "trip_requests")
public class TripRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "departure_city", nullable = false, length = 150)
    private String departureCity;
    @Column(nullable = false, length = 100)
    private String nationality;
    @Column(nullable = false)
    private Integer adults;
    @Column(nullable = false)
    private Integer children;
    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal budget;
    @Column(nullable = false, length = 3)
    private String currency;
    @Column(name = "duration_days", nullable = false)
    private Integer durationDays;
    @Column(name = "travel_period", length = 80)
    private String travelPeriod;
    @Column(name = "travel_style", length = 80)
    private String travelStyle;
    @Column(name = "destination_scope", length = 80)
    private String destinationScope;
    @Column(length = 1000)
    private String interests;
    @Column(name = "preferred_destination", length = 150)
    private String preferredDestination;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected TripRequest() {
    }

    public TripRequest(String departureCity, String nationality, Integer adults, Integer children, BigDecimal budget, String currency, Integer durationDays, String travelPeriod, String travelStyle, String destinationScope, String interests, String preferredDestination) {
        this.departureCity = departureCity;
        this.nationality = nationality;
        this.adults = adults;
        this.children = children;
        this.budget = budget;
        this.currency = currency;
        this.durationDays = durationDays;
        this.travelPeriod = travelPeriod;
        this.travelStyle = travelStyle;
        this.destinationScope = destinationScope;
        this.interests = interests;
        this.preferredDestination = preferredDestination;
        this.createdAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public String getDepartureCity() {
        return departureCity;
    }

    public String getNationality() {
        return nationality;
    }

    public Integer getAdults() {
        return adults;
    }

    public Integer getChildren() {
        return children;
    }

    public BigDecimal getBudget() {
        return budget;
    }

    public String getCurrency() {
        return currency;
    }

    public Integer getDurationDays() {
        return durationDays;
    }

    public String getTravelPeriod() {
        return travelPeriod;
    }

    public String getTravelStyle() {
        return travelStyle;
    }

    public String getDestinationScope() {
        return destinationScope;
    }

    public String getInterests() {
        return interests;
    }

    public String getPreferredDestination() {
        return preferredDestination;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
