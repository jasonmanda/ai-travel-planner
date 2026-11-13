package com.aitravelplanner.trip;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TripRequestRepository extends JpaRepository<TripRequest, UUID> {
}
