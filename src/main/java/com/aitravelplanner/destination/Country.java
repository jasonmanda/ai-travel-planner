package com.aitravelplanner.destination;

import jakarta.persistence.*;

@Entity
@Table(name = "countries")
public class Country {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "iso_code", nullable = false, unique = true, length = 2)
    private String isoCode;
    @Column(nullable = false, length = 100)
    private String name;
    @Column(name = "currency_code", length = 3)
    private String currencyCode;
    @Column(length = 255)
    private String languages;

    protected Country() {
    }

    public Long getId() {
        return id;
    }

    public String getIsoCode() {
        return isoCode;
    }

    public String getName() {
        return name;
    }

    public String getCurrencyCode() {
        return currencyCode;
    }
}
