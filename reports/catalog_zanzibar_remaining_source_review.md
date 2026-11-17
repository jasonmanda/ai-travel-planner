# Revue des 11 fiches Zanzibar restantes après PR #56

Date: 2026-11-17

## Décision générale

Cette revue distingue quatre types de preuve. Elle ne vérifie pas les données terrain et ne promeut aucune fiche.

| Fiche | Décision | Motif |
|---|---|---|
| Activité 1 — journée plage à Paje | Contexte général uniquement | L'enquête de la Bank of Tanzania cite les plages de Zanzibar et Paje parmi les sites fréquentés; elle ne documente pas les conditions actuelles de cette plage. |
| Activité 2 — découverte du patrimoine de Stone Town | Contexte général uniquement | Les consignes UNESCO concernent le site patrimonial et ses visiteurs; elles ne prouvent pas une offre de visite organisée précise. |
| Activité 7 — visite à pied de Stone Town | Contexte général uniquement | Le guide CHAN est lié à un événement et ne prouve pas une visite pédestre actuellement proposée. |
| Activité 8 — visite d'une ferme d'épices | Source primaire d'opérateur | Sea Star Fish publie une page dédiée à son Spice Tour. Elle documente cette offre commerciale, pas toutes les fermes de l'île ni sa disponibilité future. |
| Activité 9 — excursion dans la forêt de Jozani | Candidate institutionnelle | Le site du parc, géré par l'autorité du parc national, décrit les visites guidées, promenades nature et attractions. Le site est consacré à Jozani, même si sa page d'accueil est la page institutionnelle principale. |
| Activité 10 — excursion Safari Blue | Source primaire d'opérateur | Safari Blue publie sa page Original Experience et décrit son propre circuit dans la zone de Menai. |
| Attraction 12 — Jozani Forest | Candidate institutionnelle | Même source officielle dédiée au parc; elle ne confirme pas les horaires, tarifs ou accès du jour. |
| Attraction 13 — Prison Island | À examiner, inchangée | La circulaire EAPCE25 mentionne Changuu/Prison Island, mais reste un document d'événement ancien, insuffisant pour les conditions actuelles d'accès ou de visite. |
| Attraction 14 — Nungwi Beach | Contexte général uniquement | L'enquête touristique nationale cite Nungwi parmi les plages fréquentées; elle ne valide pas les limites, accès ou conditions de baignade actuelles. |
| Attraction 15 — Paje Beach | Contexte général uniquement | Même limite que Nungwi; le rapport national est un contexte touristique, pas une fiche visiteurs dédiée. |
| Attraction 16 — Nakupenda sandbank | À examiner, inchangée | La page Sea Star Fish décrit une excursion commerciale vers Nakupenda, pas une source institutionnelle sur le statut géographique, la protection, les limites ou l'accès au banc de sable. |

## Nouvelle classification de source

`OPERATOR_PRIMARY` est ajouté pour distinguer les pages publiées par un opérateur au sujet de sa propre prestation. Ce type de source peut décrire l'offre du prestataire; il ne doit pas être confondu avec une source institutionnelle indépendante.

Les sources opérateur ne satisfont volontairement pas le filtre strict des recommandations, qui exige toujours une source institutionnelle spécifique, le statut `VERIFIED`, des coordonnées valides, une durée positive et un nom/catégorie valides.

Le site racine `https://maliasilismz.go.tz/` est accepté uniquement comme exception contrôlée parce qu'il s'agit du site de l'autorité du parc Jozani lui-même, et non d'un portail général multi-destinations. Les autres pages d'accueil restent rejetées.

## Modifications SQL préparées

Le script manuel `catalog_zanzibar_remaining_source_updates.sql` :
- classe les deux pages de tours opérateurs en `OPERATOR_PRIMARY`;
- remplace l'URL Jozani `/index.php` par le site officiel dédié au parc;
- reclasse cinq références générales comme `DESTINATION_GENERAL`;
- laisse Prison Island et Nakupenda inchangées;
- ne modifie jamais le statut de vérification, les coordonnées, les durées, les coûts ou l'historique de vérification.

Toutes les fiches concernées restent `UNVERIFIED`. Aucune ne devient recommandable par cette PR.

## Sources examinées

- Jozani Chwaka Bay National Park: https://maliasilismz.go.tz/
- Safari Blue Original Experience: https://safariblue.net/tours/original-experience/
- Sea Star Fish Spice Tour: https://seastarfish.co.tz/spice-tour
- Bank of Tanzania Tourism Sector Survey: https://bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf
- UNESCO Stone Town visitor guidance: https://whc.unesco.org/document/218167
- Zanzibar Tourist Board CHAN participant guidebook: retained existing source URL; not used as proof of an active walking tour.
- EAPCE25 circular: retained existing source URL for Prison Island; not treated as current visitor evidence.
