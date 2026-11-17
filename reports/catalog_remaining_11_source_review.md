# Review of the 11 remaining official-source candidates

Date: 2026-11-17

## Scope and decision

This review covers the 11 active catalog rows returned by the recommendation-eligibility audit before this change. The review is about **source relevance only**. It is not a factual verification of every catalog field and does not authorize any `data_status` promotion.

| Item | Source reviewed | Decision | Reason / next action |
|---|---|---|---|
| Marrakech — Découverte des souks et de la médina (ACTIVITY 4) | [Visit Morocco — Shopping à Marrakech](https://www.visitmorocco.com/fr/voyage/marrakech/shopping) | Candidate retained | Official destination tourism board page directly describes Marrakech souks and named markets. |
| Marrakech — Visite du Jardin Majorelle (ACTIVITY 3) | [Jardin Majorelle — Le Jardin](https://www.jardinmajorelle.com/lejardin/) | Candidate retained | Official operator page describes the garden and visitor information. |
| Marrakech — Jardin Majorelle (ATTRACTION 3) | [Jardin Majorelle — Le Jardin](https://www.jardinmajorelle.com/lejardin/) | Candidate retained | Official operator page dedicated to the named attraction. |
| Marrakech — Jemaa el-Fna (ATTRACTION 4) | [UNESCO — L’espace culturel de la place Jemaa el-Fna](https://ich.unesco.org/fr/RL/l-espace-culturel-de-la-place-jemaa-el-fna-00014) | Candidate retained | UNESCO record is explicitly about Jemaa el-Fna and its cultural space. It does not establish current visitor operations. |
| Zanzibar — Découverte du marché nocturne de Forodhani (ACTIVITY 11) | Zanzibar House of Representatives committee report, [PDF](https://zanzibarassembly.go.tz/storage/documents/Committees/all/1677484498.pdf) | **Review required** | The official report is Forodhani-related, but its title/available evidence does not establish the claimed night-market visitor activity. It is now rejected as a recommendation-source candidate until a page/document directly supports that activity. |
| Zanzibar — Excursion dans la forêt de Jozani (ACTIVITY 9) | [Jozani Chwaka Bay National Park — official site](https://maliasilismz.go.tz/index.php) | Candidate retained | Current park authority page explicitly describes the national park, its visitor attractions and guided visits. |
| Zanzibar — Forodhani Gardens (ATTRACTION 1) | [Zanzibar Ministry of Finance — BIG-Z ESMF, Annex E](https://mofzanzibar.go.tz/wp-content/uploads/2025/12/UPDATED-ESMF-BIG-Z-AFTER-RESTRUCTURING_FINAL-CLEARED-VERSION-BY-THE-WB_DISCLOSED-CLEAN-VERSION-26.11.2025.pdf) | Candidate retained | Government document names Forodhani Garden and gives its historical-site context. It does not establish current access or opening hours. |
| Zanzibar — Jozani Forest (ATTRACTION 12) | [Jozani Chwaka Bay National Park — official site](https://maliasilismz.go.tz/index.php) | Candidate retained | Official park authority source explicitly describes Jozani Chwaka Bay National Park and visitor attractions. |
| Cape Town — Découverte du front de mer (ACTIVITY 6) | [V&A Waterfront — Plan Your Day](https://www.waterfront.co.za/attractions/plan-your-day) | Candidate retained | Official visitor-planning page provides trails and attractions within the V&A Waterfront. |
| Cape Town — Randonnée sur Lion's Head (ACTIVITY 5) | [SANParks — Lion's Head & Signal Hill](https://www.sanparks.org/parks/table-mountain/what-to-do/attractions/lions-head-signal-hill) | Candidate retained after URL correction | The previous trails index was less precise. This dedicated official page describes Lion's Head and the hike. SANParks' trail guidance gives an uphill duration of 1–1.5 hours; the existing 75-minute estimate is within that range. |
| Cape Town — V&A Waterfront (ATTRACTION 5) | [V&A Waterfront — Plan Your Day](https://www.waterfront.co.za/attractions/plan-your-day) | Candidate retained | Official page is dedicated to visitor experiences and attractions within the named Waterfront precinct. |

## Manual data change

The companion SQL script updates only the Lion's Head activity's source title and URL, guarded by its current value and the expected city/country. It does not modify its 75-minute duration, coordinates, verification status or verification timestamp.

## Data-quality limits

- All 11 rows were `UNVERIFIED` at review time. No row is promoted to `VERIFIED` or `PARTIALLY_VERIFIED`.
- Source suitability is not field-level factual verification.
- Missing coordinates and durations remain missing. No coordinates or durations are invented.
- The Forodhani night-market activity is explicitly excluded from source candidates pending direct evidence.
- Prices, opening hours, access conditions and live availability remain outside this source review and require their own current evidence.
- The recommendation gate remains closed for these rows until every required field is independently verified and the catalog status is updated through the established verification workflow.

## Audit impact

The read-only audit classifier now rejects the Forodhani committee PDF as insufficient evidence for the specific night-market activity. The Java transparency classifier and both SQL audit classifiers use the same exact URL guard. The audit remains SELECT-only; the separate manual update script is the only data-changing artifact in this review.
