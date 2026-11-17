# Audit final d'éligibilité du catalogue — 27 fiches

Date: 2026-11-17

## Résultat de l'audit pgAdmin

| Contrôle | Résultat |
|---|---:|
| Fiches actives | 27 |
| Éligibles aux recommandations | 0 |
| Non vérifiées | 27 |
| Sources ne passant pas le filtre strict | 9 |
| Coordonnées invalides ou absentes | 1 |
| Durées absentes ou invalides | 0 |

Les 27 fiches ont une durée positive. Une seule fiche a des coordonnées absentes: activité TZ/Zanzibar ID 8, « Visite guidée d’une plantation d’épices à Zanzibar ».

## Décision sur les 9 sources en échec

| Fiche | Classification actuelle | Décision |
|---|---|---|
| Activité TZ 2 — Découverte du patrimoine de Stone Town | DESTINATION_CONTEXT_ONLY | Conserver comme contexte: les consignes visiteurs UNESCO portent sur le site, pas sur une offre d'activité organisée actuellement disponible. |
| Activité TZ 10 — Safari Blue | OPERATOR_PRIMARY_CANDIDATE | Conserver comme preuve de l'offre de l'opérateur seulement; ne pas assimiler à une validation institutionnelle. |
| Activité TZ 1 — Journée plage à Paje | DESTINATION_CONTEXT_ONLY | Conserver le rapport touristique national comme contexte; il ne documente pas les conditions de visite de cette plage. |
| Activité TZ 8 — Plantation d'épices | OPERATOR_PRIMARY_CANDIDATE | Conserver comme preuve de l'offre de Sea Star Fish uniquement. Coordonnées de la ferme non établies par la page consultée. |
| Activité TZ 7 — Visite à pied de Stone Town | DESTINATION_CONTEXT_ONLY | Le guide CHAN 2024 ne prouve pas une visite pédestre actuellement proposée. |
| Attraction TZ 16 — Banc de sable dit Nakupenda | SECONDARY_REFERENCE_ONLY | Ne pas transformer le nom commercial de l'excursion en toponyme officiel sans source géographique/institutionnelle. |
| Attraction TZ 14 — Nungwi Beach | DESTINATION_CONTEXT_ONLY | Le rapport touristique national constitue un contexte, pas une fiche officielle dédiée aux conditions de cette plage. |
| Attraction TZ 15 — Paje Beach | DESTINATION_CONTEXT_ONLY | Même limite que pour Nungwi. |
| Attraction TZ 13 — Prison Island (Changuu) | SOURCE_REQUIRES_REVIEW | Remplacer la circulaire événementielle par le document gouvernemental BIG-Z ESMF, qui identifie explicitement Changuu Island. |

## Correction SQL préparée

Le script manuel `catalog_prison_island_source_update.sql` remplace uniquement la source de Prison Island par le document officiel du Ministry of Finance Zanzibar, annexe E « Historical Sites ».

Cette source confirme l'identification et le contexte historique de Changuu Island ainsi que son exploitation comme centre touristique. Elle ne prouve pas les conditions actuelles de visite, horaires, tarifs, départs de bateaux, disponibilité, sécurité ou durée.

Le script:
- est transactionnel et protégé par des conditions strictes sur l'enregistrement existant;
- met à jour uniquement les métadonnées de source et les notes;
- ne change ni `data_status`, ni `last_verified_at`, ni les coordonnées, ni la durée, ni les coûts;
- interrompt et annule la transaction si exactement une ligne ne correspond pas.

## Garde-fous

- Les 27 fiches restent `UNVERIFIED`; aucune promotion automatique.
- Les sources opérateur ne satisfont pas le filtre institutionnel des recommandations.
- La coordonnée de l'activité « plantation d'épices » reste inconnue: ne pas copier la coordonnée de Stone Town ou celle d'un autre opérateur.
- Nakupenda reste décrit comme une excursion vers un banc de sable, pas comme un toponyme officiel confirmé.
- Horaires, accès du jour, disponibilité, prix et conditions de sécurité ne sont pas couverts par cet audit.

## Sources examinées

- Stone Town Conservation and Development Authority (autorité officielle de conservation): https://utaliismz.go.tz/administration/instituions/stone-town-conservation-and-development-authority
- Zanzibar Ministry of Finance, BIG-Z ESMF, Annex E, entrée Changuu Island: https://mofzanzibar.go.tz/wp-content/uploads/2025/12/UPDATED-ESMF-BIG-Z-AFTER-RESTRUCTURING_FINAL-CLEARED-VERSION-BY-THE-WB_DISCLOSED-CLEAN-VERSION-26.11.2025.pdf
- Safari Blue Original Experience (source opérateur): https://safariblue.net/tours/original-experience/
- Sea Star Fish Spice Tour (source opérateur): https://seastarfish.co.tz/spice-tour
- UNESCO, General Guidelines for Stone Town Heritage Site: https://whc.unesco.org/document/218167
- Bank of Tanzania, Tourism Sector Survey: https://www.bot.go.tz/Publications/Other/Tanzania%20Tourism%20Sector%20Survey%20Report/en/2025082910055206.pdf
- Zanzibar Ministry of Tourism and Heritage, Coastal Tourism: https://www.zanzibardiaspora.go.tz/zanzibar/coastal-tourism
- Sea Star Fish Nakupenda trip (source opérateur): https://seastarfish.co.tz/nakupenda
