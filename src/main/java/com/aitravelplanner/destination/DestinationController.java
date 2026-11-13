package com.aitravelplanner.destination;

import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/destinations")
public class DestinationController {
    private final CityRepository cities;

    public DestinationController(CityRepository cities) {
        this.cities = cities;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<Map<String, Object>> findAll() {
        return cities.findAllByOrderByNameAsc().stream().map(c -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", c.getId());
            m.put("city", c.getName());
            m.put("country", c.getCountry().getName());
            m.put("countryCode", c.getCountry().getIsoCode());
            m.put("description", c.getDescription());
            m.put("estimatedDailyBudget", c.getEstimatedDailyBudget());
            m.put("currency", c.getEstimatedDailyBudgetCurrency());
            m.put("countryCurrency", c.getCountry().getCurrencyCode());
            m.put("tags", c.getTags() == null ? List.of() : Arrays.stream(c.getTags().split(",")).map(String::trim).toList());
            m.put("latitude", c.getLatitude());
            m.put("longitude", c.getLongitude());
            return m;
        }).toList();
    }
}
