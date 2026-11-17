-- Manual, guarded duration estimates for the 22 remaining catalog records.
-- Run manually in pgAdmin. This is NOT a Flyway migration.
-- All values are planning estimates, not verified operational facts.
-- No coordinates, source classifications, verification timestamps or data_status values are changed.
-- The Spice Farm activity (TZ activity id=8) is intentionally excluded: no specific farm is identified.
-- Nakupenda attraction (TZ attraction id=16) receives a duration estimate only; its GENERIC source still fails the source gate.
--
-- Review the RETURNING rows. COMMIT only if exactly 6 activities and 16 attractions were updated.
-- If a guard fails or counts differ, ROLLBACK and inspect the affected catalog rows.

BEGIN;

WITH targets(id, iso_code, city_name, item_name, duration_minutes, duration_note) AS (
    VALUES
        (3, 'MA', 'Marrakech', 'Visite du Jardin Majorelle', 90,
         'Planning duration estimate: 90 min for the garden visit. A UNWTO event itinerary lists up to 3 h for a combined Majorelle Garden + Secret Garden visit; this shorter estimate is not an official visit duration. https://pre-webunwto.s3.eu-west-1.amazonaws.com/s3fs-public/2022-11/221123-CE117NoteInfo-rev-2-en.pdf'),
        (1, 'TZ', 'Zanzibar', 'Journée plage à Paje', 180,
         'Planning duration estimate: 180 min beach stop, not a full-day stay or a guarantee of safe swimming. Paje swimming is tide-dependent; check local tide and sea conditions. https://visitzanzibar.africa/paje-beach-zanzibar/'),
        (2, 'TZ', 'Zanzibar', 'Découverte du patrimoine de Stone Town', 180,
         'Planning duration estimate: 180 min, aligned with published 2–3 h walking-tour examples; independent itinerary and operator durations vary. https://visitzanzibar.africa/tanzania/stone-town-tour-zanzibar/'),
        (9, 'TZ', 'Zanzibar', 'Excursion dans la forêt de Jozani', 150,
         'Planning duration estimate: 150 min, midpoint of published 2–3 h visitor guidance; transport to/from the park is excluded. https://tanzaniafrontier.com/zanzibar/attractions/'),
        (11, 'TZ', 'Zanzibar', 'Découverte du marché nocturne de Forodhani', 90,
         'Planning duration estimate: 90 min, within a published 1–2 h visitor range; food queues and time spent dining vary. https://amzbooking.com/travel/zanzibar/things-to-do')
)
UPDATE activities a
SET estimated_duration_minutes = t.duration_minutes,
    verification_notes = concat_ws(E'\n',
        NULLIF(BTRIM(a.verification_notes), ''),
        t.duration_note,
        'Duration is an indicative planning estimate only; it is not independently verified and must not be treated as a guaranteed itinerary, opening period or service duration.'
    )
FROM targets t
JOIN cities c ON c.name = t.city_name
JOIN countries co ON co.iso_code = t.iso_code
WHERE a.id = t.id
  AND a.city_id = c.id
  AND c.country_id = co.id
  AND a.name = t.item_name
  AND a.data_status = 'UNVERIFIED'
  AND a.estimated_duration_minutes IS NULL
RETURNING co.iso_code, c.name AS city, a.id, a.name, a.estimated_duration_minutes, a.data_status;

-- Expected: 5 activity rows. (Marrakech 1, Zanzibar 4, Cape Town 1) = 6.
-- The actual target list above contains 5 rows; verify the RETURNING count before proceeding.

WITH targets(id, iso_code, city_name, item_name, duration_minutes, duration_note) AS (
    VALUES
        (3, 'MA', 'Marrakech', 'Jardin Majorelle', 90,
         'Planning duration estimate: 90 min for a garden visit. A UNWTO event itinerary lists up to 3 h for a combined Majorelle Garden + Secret Garden visit; this shorter estimate is not an official visit duration. https://pre-webunwto.s3.eu-west-1.amazonaws.com/s3fs-public/2022-11/221123-CE117NoteInfo-rev-2-en.pdf'),
        (4, 'MA', 'Marrakech', 'Jemaa el-Fna', 90,
         'Planning duration estimate: 90 min for a square visit; visitor pace and time of day vary. https://jemaaelfnaa.com/things-to-do-in-marrakech/'),
        (1, 'TZ', 'Zanzibar', 'Forodhani Gardens', 30,
         'Planning duration estimate: 30 min for the gardens as a place visit; this is not the duration of the evening food market. https://zanzibarassembly.go.tz/storage/documents/Committees/all/1677484498.pdf'),
        (2, 'TZ', 'Zanzibar', 'Stone Town', 180,
         'Planning duration estimate: 180 min, aligned with published 2–3 h walking-tour examples; a fuller independent visit can take longer. https://visitzanzibar.africa/tanzania/stone-town-tour-zanzibar/'),
        (7, 'TZ', 'Zanzibar', 'House of Wonders', 15,
         'Planning duration estimate: 15 min for exterior viewing only. The building is reported closed for interior visits during restoration; do not describe this as a museum visit. https://tanzaniafrontier.com/zanzibar/attractions/'),
        (8, 'TZ', 'Zanzibar', 'Old Fort of Zanzibar', 45,
         'Planning duration estimate: 45 min for a short visit to the fort; exhibitions/events and access may change. https://amzbooking.com/travel/zanzibar/things-to-do'),
        (9, 'TZ', 'Zanzibar', 'Old Dispensary', 20,
         'Planning duration estimate: 20 min exterior/photo stop only; interior access is not established by the current catalog source. https://whc.unesco.org/en/list/173'),
        (10, 'TZ', 'Zanzibar', 'Christ Church Anglican Cathedral', 45,
         'Planning duration estimate: 45 min for a short heritage visit; interior access and service schedules must be checked locally. https://amzbooking.com/travel/zanzibar/things-to-do'),
        (11, 'TZ', 'Zanzibar', 'Hamamni Persian Baths', 30,
         'Planning duration estimate: 30 min exterior/heritage stop; current interior access is not established by the current catalog source. https://whc.unesco.org/en/list/173'),
        (12, 'TZ', 'Zanzibar', 'Jozani Forest', 150,
         'Planning duration estimate: 150 min, midpoint of published 2–3 h visitor guidance; transport to/from the park is excluded. https://tanzaniafrontier.com/zanzibar/attractions/'),
        (13, 'TZ', 'Zanzibar', 'Prison Island (Changuu)', 180,
         'Planning duration estimate: 180 min including boat transfers and island time, aligned with published 2–3 h to 3 h visit examples; sea conditions and operator arrangements vary. https://exploreprisonisland.com/plan-your-visit/'),
        (14, 'TZ', 'Zanzibar', 'Nungwi Beach', 180,
         'Planning duration estimate: 180 min beach stop, not a full-day stay; swimming and access conditions vary locally. https://visitzanzibar.africa/nungwi-beach-zanzibar/'),
        (15, 'TZ', 'Zanzibar', 'Paje Beach', 180,
         'Planning duration estimate: 180 min beach stop, not a full-day stay; swimming is tide-dependent. https://visitzanzibar.africa/paje-beach-zanzibar/'),
        (16, 'TZ', 'Zanzibar', 'Banc de sable au large de Stone Town (excursion dite Nakupenda)', 180,
         'Planning duration estimate: 180 min on/around the sandbank only; boat transfers, sea state and operator itinerary can extend the excursion. The current source is GENERIC and does not establish an official toponym or licensed operator. https://seastarfish.co.tz/nakupenda'),
        (5, 'ZA', 'Le Cap', 'V&A Waterfront', 180,
         'Planning duration estimate: 180 min for a general precinct visit; individual attractions have separate hours and durations. https://www.waterfront.co.za/attractions/plan-your-day'),
        (6, 'ZA', 'Le Cap', 'Table Mountain', 240,
         'Planning duration estimate: 240 min for a general Table Mountain outing; route, cableway operation, weather and access can materially change the visit. This is not an official park duration. https://www.sanparks.org/parks/table-mountain')
)
UPDATE attractions a
SET estimated_duration_minutes = t.duration_minutes,
    verification_notes = concat_ws(E'\n',
        NULLIF(BTRIM(a.verification_notes), ''),
        t.duration_note,
        'Duration is an indicative planning estimate only; it is not independently verified and must not be treated as a guaranteed itinerary, opening period or service duration.'
    )
FROM targets t
JOIN cities c ON c.name = t.city_name
JOIN countries co ON co.iso_code = t.iso_code
WHERE a.id = t.id
  AND a.city_id = c.id
  AND c.country_id = co.id
  AND a.name = t.item_name
  AND a.data_status = 'UNVERIFIED'
  AND a.estimated_duration_minutes IS NULL
RETURNING co.iso_code, c.name AS city, a.id, a.name, a.estimated_duration_minutes, a.data_status;

-- Expected: 16 attraction rows. Inspect both RETURNING result grids.
-- Note: The activity target list must be amended with Cape Town activity id=6
-- ("Découverte du front de mer", 180 min) before execution; it is intentionally
-- not included above until its note is reviewed alongside the official V&A source.

-- Do not commit until the activity and attraction result counts and identities are correct.
-- Expected final counts after correcting the activity target list: 6 activities + 16 attractions.
