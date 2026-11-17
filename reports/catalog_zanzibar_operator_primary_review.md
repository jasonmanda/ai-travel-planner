# Zanzibar operator-primary source review

Date: 2026-11-17

## Scope

This review records the decision for the remaining Zanzibar catalog records whose current evidence is operator-primary rather than independent institutional evidence.

It is a documentation-only review. It does not change catalog rows, recommendation eligibility, coordinates, durations, verification status, or source metadata.

## Records reviewed

| Item | Catalog record | Current evidence classification | Review decision |
|---|---|---|---|
| Activity | Zanzibar, activity ID 8 — Spice Tour | `OPERATOR_PRIMARY`, `ITEM_SPECIFIC`, `UNVERIFIED` | Retain as-is. The operator page describes plantations outside Stone Town and mentions Kidichi Persian Baths, but does not identify the exact plantation or provide its GPS position. Keep latitude and longitude `NULL`. The 210-minute duration remains a planning estimate, not independently verified. |
| Activity | Zanzibar, activity ID 10 — Safari Blue | `OPERATOR_PRIMARY`, `ITEM_SPECIFIC`, `UNVERIFIED` | Retain as-is. Operator material describes the commercial excursion, but the reviewed independent material about Menai Bay does not independently establish the exact commercial itinerary, pickup point, or activity-specific coordinates. |
| Attraction | Zanzibar, attraction ID 16 — Nakupenda | `OPERATOR_PRIMARY`, `ITEM_SPECIFIC`, `UNVERIFIED` | Retain as-is. The available operator material supports that this is an offered excursion/destination label, but the review did not establish an authoritative, independently verified toponym and precise point suitable for catalog promotion. |

## Evidence and limitations

- An operator's own page can document the service it sells. It is not, by itself, independent institutional evidence for the official identity, boundaries, coordinates, access conditions, or physical characteristics of a place.
- General documentation about Menai Bay does not automatically verify the Safari Blue product or its exact route.
- A generic Kidichi spice-farm location, a different operator's meeting point, or the location of Kidichi Persian Baths must not be substituted for the plantation visited by Sea Star Fish.
- A sandbank or excursion name used by an operator must not be converted into an authoritative place record without independent evidence that identifies the place and supports its location.
- Missing coordinates remain missing. No coordinates are inferred from nearby landmarks, third-party listings, or operator itineraries.

## Decision

No SQL update is justified by this review.

Keep all three records `UNVERIFIED` and retain their current `OPERATOR_PRIMARY` source classification. Do not set `last_verified_at`, promote source types to `OFFICIAL`, or use these operator-only records to satisfy the strict recommendation evidence gate.

For Spice Tour (activity ID 8), keep latitude and longitude `NULL` until the operator confirms the exact plantation and supplies a reliable map pin or GPS coordinates.

## Expected audit impact

This documentation-only review has no database impact. The previously observed audit result remains the reference point:

- Active candidate records: 27
- Recommendation-eligible records: 0
- Records not fully verified: 27
- Source-gate failures: 3
- Records with invalid or missing coordinates: 1
- Records with missing or invalid duration: 0

Rerun `reports/catalog_recommendation_eligibility_audit.sql` against the target database to confirm its current state; these counts are not asserted as a fresh live query by this document.
