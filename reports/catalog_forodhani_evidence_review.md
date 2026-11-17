# Forodhani night-market source reassessment

Date: 2026-11-17

## Finding

The official Zanzibar House of Representatives Budget Committee Report 2022/2023 (February 2023) contains a dedicated section on pages 77–78 titled, in translation, **assessment of revenue collection from businesses and services in the Forodhani area for FY 2021/2022**.

The report states that Forodhani Gardens is especially active in the evening, when many vendors gather to provide services to residents and visitors. This is direct, item-specific institutional evidence for evening commercial activity at Forodhani. It is materially more precise than a generic destination reference.

Primary source: [Zanzibar House of Representatives — Budget Committee Report 2022/2023](https://zanzibarassembly.go.tz/storage/documents/Committees/all/1677484498.pdf), printed pages 77–78.

The Tanzania Tourist Board's CHAN 2024 participant guidebook independently labels Forodhani as a famous evening food market with street food, but it is an event participant guide and is not used as the primary catalog source: [CHAN 2024 Participant Guidebook](https://www.tanzaniatourism.go.tz/data/2025/08/CHAN-2024-Participant-Guidebook-1.pdf).

## Classification decision

For the row ACTIVITY / id=11, Zanzibar:

- Keep the existing Zanzibar House of Representatives PDF URL.
- Remove the URL-specific Java rejection that previously forced this report to `SOURCE_REQUIRES_REVIEW`.
- Classify it as `ITEM_SPECIFIC_PRIMARY_CANDIDATE` when the row metadata is `OFFICIAL` + `ITEM_SPECIFIC`.
- Keep `sourceSupportsRecommendation=false`. Source suitability is not factual verification and does not independently open the itinerary gate.
- Keep `data_status=UNVERIFIED`; do not set `last_verified_at` or write verification history.

## Historical and operational limits

The report concerns FY 2021/2022 and was published in February 2023. It supports the presence of evening vendor activity at the gardens in that period. It does **not** prove:

- that the market currently operates every evening;
- current opening or closing hours;
- today's vendor roster or food selection;
- prices, food hygiene, safety or accessibility;
- that every activity description or catalog field is accurate.

These operational details must remain unclaimed until checked against current evidence.

## Manual database note update

`reports/catalog_forodhani_evidence_update.sql` updates only the source label, source type/scope and provenance notes for the exact unverified activity row. It does not change status, verification timestamps, coordinates, duration or verification history. It is a manual pgAdmin script, not a Flyway migration.

## Test coverage

A regression test now asserts that the exact Forodhani report URL is an item-specific official-source candidate while the record remains `UNVERIFIED`, `verified=false` and `sourceSupportsRecommendation=false`. The remaining known destination-wide official references continue to be rejected.
