# Revue des 8 échecs de source — Zanzibar

Date: 2026-11-17

## État pgAdmin de départ

Après la correction de Prison Island, l'audit exécuté par l'utilisateur donne:

| Contrôle | Résultat |
|---|---:|
| Fiches actives | 27 |
| Éligibles aux recommandations | 0 |
| Non vérifiées | 27 |
| Échecs du filtre de source | 8 |
| Coordonnées invalides ou absentes | 1 |
| Durées absentes ou invalides | 0 |

## Décisions et changements préparés

Le script manuel \`catalog_remaining_eight_source_updates.sql\` met à jour six fiches, avec des garde-fous par pays, ville, identifiant, nom, statut, date de vérification, type/portée et ancienne URL.

| Fiche | Nouvelle source / décision | Effet attendu sur le filtre |
|---|---|---|
| Activité TZ 1 — Journée plage à Paje | High Commission de Tanzanie: la page nomme Paje parmi les plages connues du sud-est de Zanzibar. | Candidat officiel item-specific; ne valide pas les conditions pratiques. |
| Activité TZ 2 — Découverte du patrimoine de Stone Town | UNESCO Urban Heritage Atlas, page consacrée spécifiquement à Stone Town. | Candidat officiel item-specific; documente le tissu patrimonial, pas une offre de visite organisée. |
| Activité TZ 7 — Visite à pied du patrimoine de Stone Town | Même Atlas UNESCO, qui décrit notamment le réseau de rues historiques. | Candidat officiel item-specific; ne confirme ni guide ni disponibilité d'une visite. |
| Activité TZ 8 — Plantation d'épices | Conserver Sea Star Fish comme source OPERATOR_PRIMARY. | Échec du filtre institutionnel maintenu; coordonnées absentes et non inventées. |
| Activité TZ 10 — Safari Blue | Conserver Safari Blue comme source OPERATOR_PRIMARY. | Échec du filtre institutionnel maintenu; preuve de l'offre de l'opérateur seulement. |
| Attraction TZ 14 — Nungwi Beach | High Commission de Tanzanie: la page nomme Nungwi parmi les plages connues de Zanzibar. | Candidat officiel item-specific; ne valide pas les conditions pratiques. |
| Attraction TZ 15 — Paje Beach | Même page de la High Commission, qui nomme Paje. | Candidat officiel item-specific; ne valide pas les conditions pratiques. |
| Attraction TZ 16 — Banc de sable dit Nakupenda | Reclasser la page Sea Star Fish de GENERIC à OPERATOR_PRIMARY. | Classification plus exacte, mais échec du filtre institutionnel maintenu. |

### Sources documentaires

- Tanzania High Commission in the United Kingdom, *Zanzibar Tropical Paradise in Africa*: https://www.uk.tzembassy.go.tz/news/view/zanzibar-tropical-paradise-in-africa
- UNESCO World Heritage Centre, *Urban Heritage Atlas: Stone Town of Zanzibar*: https://whc.unesco.org/en/urban-heritage-atlas/stone-town
- Sea Star Fish, excursion Nakupenda (source opérateur): https://seastarfish.co.tz/nakupenda
- Sea Star Fish, Spice Tour (source opérateur conservée): https://seastarfish.co.tz/spice-tour
- Safari Blue, Original Experience (source opérateur conservée): https://safariblue.net/tours/original-experience/

## Résultat attendu après exécution du script

Sous réserve que les six gardes correspondent exactement aux lignes de la base:

| Contrôle | Résultat attendu |
|---|---:|
| Fiches actives | 27 |
| Éligibles aux recommandations | 0 |
| Non vérifiées | 27 |
| Échecs du filtre de source | 3 |
| Coordonnées invalides ou absentes | 1 |
| Durées absentes ou invalides | 0 |

Les trois échecs de source attendus sont les deux activités dont la preuve reste opérateur (Spice Tour et Safari Blue) et l'excursion Nakupenda documentée par son prestataire. Ces sources ne sont pas assimilées à des preuves institutionnelles indépendantes.

## Garde-fous

- Aucun statut \`UNVERIFIED\` n'est modifié.
- Aucun \`last_verified_at\` n'est renseigné.
- Aucune coordonnée, durée, estimation de coût ou condition opérationnelle n'est modifiée.
- La coordonnée de la plantation d'épices reste inconnue; ne pas la remplacer par le point de Stone Town, de Sea Star Fish ou d'une autre ferme sans preuve géographique directe.
- Le reclassement de Nakupenda décrit correctement une source opérateur; il ne confirme pas le toponyme officiel du banc de sable.
- Le script est une opération manuelle pgAdmin, pas une migration Flyway. Chaque UPDATE doit toucher exactement une ligne; sinon toute la transaction est annulée.
- Les résultats attendus doivent être confirmés en relançant \`reports/catalog_recommendation_eligibility_audit.sql\` après l'application du script.
