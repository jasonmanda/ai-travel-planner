package com.aitravelplanner.trip;

import com.aitravelplanner.common.TripNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static com.aitravelplanner.trip.TripDtos.CreateTripRequest;
import static com.aitravelplanner.trip.TripDtos.TripResponse;

@Service
public class TripService {
    private final TripRequestRepository repo;

    public TripService(TripRequestRepository repo) {
        this.repo = repo;
    }

    @Transactional
    public TripResponse create(CreateTripRequest r) {
        String tags = r.interests() == null ? "" : String.join(",", r.interests());
        TripRequest e = new TripRequest(r.departureCity().trim(), r.nationality().trim(), r.adults(), r.children(), r.budget(), r.currency() == null || r.currency().isBlank() ? "XOF" : r.currency().toUpperCase(), r.duration(), r.travelPeriod(), r.travelStyle(), r.destinationScope(), tags, r.preferredDestination());
        return map(repo.save(e));
    }

    @Transactional(readOnly = true)
    public TripResponse get(UUID id) {
        return repo.findById(id).map(this::map).orElseThrow(() -> new TripNotFoundException(id.toString()));
    }

    private TripResponse map(TripRequest t) {
        List<String> tags = t.getInterests() == null || t.getInterests().isBlank() ? List.of() : Arrays.asList(t.getInterests().split(","));
        return new TripResponse(t.getId(), t.getDepartureCity(), t.getNationality(), t.getAdults(), t.getChildren(), t.getBudget(), t.getCurrency(), t.getDurationDays(), t.getTravelPeriod(), t.getTravelStyle(), t.getDestinationScope(), tags, t.getPreferredDestination(), t.getCreatedAt());
    }
}
