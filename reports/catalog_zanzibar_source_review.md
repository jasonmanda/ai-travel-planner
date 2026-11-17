# Zanzibar heritage source review — 17 source-gate failures

## Scope

This review covers the 17 records returned by the read-only source-gate query on 2026-11-17:
- 16 official-source records requiring manual review;
- 1 generic provider-source record (Nakupenda).

No record is promoted to VERIFIED or PARTIALLY_VERIFIED by this review.

## Safe source correction prepared

Six attraction records currently point to the UNESCO World Heritage Centre's general Stone Town property listing:
- attraction 2 — Stone Town;
- attraction 7 — House of Wonders;
- attraction 8 — Old Fort of Zanzibar;
- attraction 9 — Old Dispensary;
- attraction 10 — Christ Church Anglican Cathedral;
- attraction 11 — Hamamni Persian Baths.

The UNESCO Urban Heritage Atlas has named sections describing the Old Fort, House of Wonders, Old Dispensary, Anglican Cathedral and Persian baths, including Hamamni. It is materially more specific to these records than the general property-list page:
https://whc.unesco.org/en/urban-heritage-atlas/stone-town

A guarded manual SQL script updates only source_name and source_url for these six exact attraction rows, provided their current names, city/country, status, source type/scope and old URL still match. The script aborts and rolls back unless exactly six rows are updated.

The source is an official institutional evidence candidate, not proof that a monument is currently open or visitable. The six rows remain UNVERIFIED; sourceSupportsRecommendation remains false.

## Records deliberately not changed

- Activity 1, Paje beach day, and attractions 14–15, Nungwi/Paje beaches: the Bank of Tanzania survey reports visitor popularity and identifies beaches, but it does not verify the proposed activity, access conditions or current visitor arrangements.
- Activity 2 and 7, Stone Town heritage discovery/walking visit: the UNESCO material documents the heritage context and monuments, but does not establish that a guided or self-guided walking activity is currently offered in the form described.
- Activity 8, spice-farm guided visit: the EAPCE25 circular mentions spice farms and a historical guided-tour fee in an event document; it is not a current operator or visitor tariff source.
- Activity 9 and attraction 12, Jozani: the park website is official, but the currently recorded URL is a scripted homepage (/index.php). It should be replaced only after identifying a dedicated visitor/park page; no homepage substitution is used to bypass the source-quality gate.
- Activity 10, Safari Blue: the CHAN participant guidebook is not the operator's primary evidence for this named excursion. A provider page may be primary evidence for the provider's own tour, but the current model/classifier does not treat provider evidence as institutional OFFICIAL evidence. Do not mislabel it.
- Attraction 13, Prison Island: the EAPCE25 event circular is not sufficient as dedicated visitor evidence.
- Attraction 16, Nakupenda: the Sea Star Fish page is provider evidence, but the current metadata classifies it as GENERIC. It must not be silently relabeled OFFICIAL; provider-primary evidence needs an explicit separate source class/policy decision.

## Expected impact

After the SQL is applied, the six updated attraction rows may be classified as ITEM_SPECIFIC_PRIMARY_CANDIDATE by the current Java classifier and matching SQL audit. They still remain UNVERIFIED, so none becomes recommendation-eligible. The total source-gate failure count should fall by six, assuming the six guarded updates all succeed and no other data changed.

## Evidence references

- UNESCO Urban Heritage Atlas, Stone Town: https://whc.unesco.org/en/urban-heritage-atlas/stone-town
- UNESCO World Heritage Centre, Stone Town property page: https://whc.unesco.org/en/list/173
- Bank of Tanzania, Tourism Sector Survey publication index: https://www.bot.go.tz/Publications/Filter/9?lang=en
- Jozani Chwaka Bay National Park official site: https://maliasilismz.go.tz/
