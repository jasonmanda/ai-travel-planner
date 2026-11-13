package com.aitravelplanner.recommendation;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RecommendationRepository extends JpaRepository<Recommendation, Long> {
    List<Recommendation> findByTripIdOrderByScoreDesc(UUID tripId);

    void deleteByTripId(UUID tripId);
}
