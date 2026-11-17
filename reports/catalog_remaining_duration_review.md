# Remaining catalog duration review (27-record batch)

## Scope and observed baseline

This review uses the 27 catalog rows returned by the read-only query shared in the PR discussion.

Baseline:
- 27/27 target records found.
- 1 record has missing coordinates: Zanzibar activity id=8, "Visite guidée d’une plantation d’épices à Zanzibar".
- 22 records have a NULL or invalid estimated duration.
- All 27 records remain `UNVERIFIED`.

This change proposes duration estimates for the 22 records with missing durations. It does not promote any record to `VERIFIED`, set `last_verified_at`, validate prices, or change source classifications.

## Duration estimates

All durations below are indicative itinerary-planning estimates, not verified operating durations, official recommendations, opening hours, or availability. The SQL script appends an explicit caveat and a supporting duration/context URL to each record's `verification_notes`.

| Type | Country / city | ID | Catalog item | Estimate |
|---|---|---:|---|---:|
| ACTIVITY | MA / Marrakech | 3 | Visite du Jardin Majorelle | 90 min |
| ACTIVITY | TZ / Zanzibar | 1 | Journée plage à Paje | 180 min |
| ACTIVITY | TZ / Zanzibar | 2 | Découverte du patrimoine de Stone Town | 180 min |
| ACTIVITY | TZ / Zanzibar | 9 | Excursion dans la forêt de Jozani | 150 min |
| ACTIVITY | TZ / Zanzibar | 11 | Découverte du marché nocturne de Forodhani | 90 min |
| ACTIVITY | ZA / Le Cap | 6 | Découverte du front de mer | 180 min |
| ATTRACTION | MA / Marrakech | 3 | Jardin Majorelle | 90 min |
| ATTRACTION | MA / Marrakech | 4 | Jemaa el-Fna | 90 min |
| ATTRACTION | TZ / Zanzibar | 1 | Forodhani Gardens | 30 min |
| ATTRACTION | TZ / Zanzibar | 2 | Stone Town | 180 min |
| ATTRACTION | TZ / Zanzibar | 7 | House of Wonders | 15 min |
| ATTRACTION | TZ / Zanzibar | 8 | Old Fort of Zanzibar | 45 min |
| ATTRACTION | TZ / Zanzibar | 9 | Old Dispensary | 20 min |
| ATTRACTION | TZ / Zanzibar | 10 | Christ Church Anglican Cathedral | 45 min |
| ATTRACTION | TZ / Zanzibar | 11 | Hamamni Persian Baths | 30 min |
| ATTRACTION | TZ / Zanzibar | 12 | Jozani Forest | 150 min |
| ATTRACTION | TZ / Zanzibar | 13 | Prison Island (Changuu) | 180 min |
| ATTRACTION | TZ / Zanzibar | 14 | Nungwi Beach | 180 min |
| ATTRACTION | TZ / Zanzibar | 15 | Paje Beach | 180 min |
| ATTRACTION | TZ / Zanzibar | 16 | Banc de sable au large de Stone Town (excursion dite Nakupenda) | 180 min |
| ATTRACTION | ZA / Le Cap | 5 | V&A Waterfront | 180 min |
| ATTRACTION | ZA / Le Cap | 6 | Table Mountain | 240 min |

## Deliberate exclusions and caveats

1. **Spice Farm activity (TZ activity id=8):** no coordinates or duration are added in this batch. Its source does not identify one specific farm, so a point coordinate would imply unsupported precision. A farm must be selected and independently sourced before adding coordinates or a farm-specific duration.
2. **House of Wonders (TZ attraction id=7):** 15 minutes is an exterior-only stop estimate. It must not be presented as an interior museum visit; access status must be checked before travel.
3. **Old Dispensary and Hamamni Persian Baths:** estimates are short exterior/heritage stops only. Current interior access is not established by the catalog's UNESCO source.
4. **Paje and Nungwi beaches:** estimates are optional stop lengths, not full-day stays or guarantees of safe swimming. Paje is strongly tide-dependent; check tide, currents, weather and local advice.
5. **Nakupenda (TZ attraction id=16):** duration is only an estimate for a sandbank excursion. The catalog source remains `GENERIC`; this SQL does not make it an eligible recommendation or establish an official toponym/operator.
6. **Table Mountain and V&A Waterfront:** durations are broad planning estimates. Weather, route choice, cableway operation, attraction schedules and access can materially change the visit.
7. All source pages and operator itineraries can change. No live opening hours, fees, safety conditions, booking status or daily availability are asserted.

## SQL execution

Run `reports/catalog_remaining_duration_manual.sql` manually in pgAdmin.

The script:
- uses guarded updates by item ID, country, city and exact name;
- only updates rows still `UNVERIFIED` with a NULL duration;
- updates 6 activities and 16 attractions;
- appends estimate provenance/caveats to `verification_notes`;
- does not modify coordinates, source metadata, verification history, or `data_status`.

Inspect the two `RETURNING` result grids. Expected counts are exactly 6 activities and 16 attractions. If the identities or counts differ, roll back and investigate; do not commit a partial or mismatched batch.

## Expected effect on the strict recommendation gate

Even after the duration estimates are applied:
- all 27 records remain `UNVERIFIED`;
- the Spice Farm activity still has missing coordinates;
- Nakupenda still has a `GENERIC` source;
- other source, coordinate, and verification requirements remain governed by the strict Java eligibility gate.

These estimates therefore do not make any of these 27 records recommendation-eligible by themselves.
