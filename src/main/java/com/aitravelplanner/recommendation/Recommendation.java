package com.aitravelplanner.recommendation;

import com.aitravelplanner.destination.City;
import com.aitravelplanner.trip.TripRequest;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "trip_recommendations", uniqueConstraints = @UniqueConstraint(name = "uk_trip_city", columnNames = {"trip_id", "city_id"}))
public class Recommendation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_id", nullable = false)
    private TripRequest trip;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "city_id", nullable = false)
    private City city;
    @Column(nullable = false)
    private Integer score;
    @Column(name = "estimated_trip_budget", nullable = false, precision = 14, scale = 2)
    private BigDecimal estimatedTripBudget;
    @Column(name = "budget_status", nullable = false, length = 30)
    private String budgetStatus;
    @Column(length = 1000)
    private String explanation;
    @Column(name = "generated_at", nullable = false)
    private Instant generatedAt;

    protected Recommendation() {
    }

    public Recommendation(TripRequest trip, City city, Integer score, BigDecimal estimate, String status, String explanation) {
        this.trip = trip;
        this.city = city;
        this.score = score;
        this.estimatedTripBudget = estimate;
        this.budgetStatus = status;
        this.explanation = explanation;
        this.generatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public TripRequest getTrip() {
        return trip;
    }

    public City getCity() {
        return city;
    }

    public Integer getScore() {
        return score;
    }

    public BigDecimal getEstimatedTripBudget() {
        return estimatedTripBudget;
    }

    public String getBudgetStatus() {
        return budgetStatus;
    }

    public String getExplanation() {
        return explanation;
    }

    public Instant getGeneratedAt() {
        return generatedAt;
    }
}
