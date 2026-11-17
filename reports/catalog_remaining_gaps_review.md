# Revue groupée des coordonnées et durées — catalogue (27 fiches)

Date de recherche : 17 novembre 2026. Branche de travail : `feat/catalog-batch-coordinate-duration-review`. Base : `main` après PR #51 (`af906bd4bc40b5edbb263eed662206c764aecaad`).

## Résultat de la revue

Le lot de référence comporte 27 fiches (activités et attractions) à Marrakech, Zanzibar et au Cap. Après les corrections précédentes, 11 fiches restaient sans paire de coordonnées et 26 sans durée.

Ce lot propose :
- **10 paires de coordonnées** supplémentaires, utilisées comme points cartographiques de référence ;
- **4 durées d'activité estimées**, dérivées de programmes publiés par des opérateurs locaux ;
- **1 point volontairement non renseigné** : l'activité générique « ferme d'épices » n'identifie pas une ferme précise parmi plusieurs établissements de Zanzibar ;
- aucune promotion automatique vers `VERIFIED`.

Les valeurs numériques de durée sont des estimations propres aux itinéraires cités, pas des durées universelles. Les coordonnées peuvent être des centres de lieux, des points de référence ou des points de départ ; elles ne représentent pas nécessairement un tracé de visite.

## Coordonnées proposées

| Fiche | Latitude | Longitude | Référence et réserve |
|---|---:|---:|---|
| ACTIVITY MA id=4 — Découverte des souks et de la médina | 31.62890 | -7.98806 | Centre cartographique des Souks de Marrakech, OSM way 1222593640. Point d'ancrage, pas un itinéraire. [Mapcarta/OSM](https://mapcarta.com/W1222593640) |
| ATTRACTION MA id=4 — Jemaa el-Fna | 31.62582 | -7.98924 | Géométrie de la place, OSM way 1132585098. [Mapcarta/OSM](https://mapcarta.com/27389480) |
| ACTIVITY TZ id=1 — Journée plage à Paje | -6.267261 | 39.536082 | Point GPS publié pour Paje Beach ; ne délimite pas toute la plage. [Avygeo](https://www.avygeo.com/fr/guide/lieux-interet/78766-plage-de-paje) |
| ACTIVITY TZ id=7 — promenade guidée de Stone Town | -6.163 | 39.189 | Point géographique UNESCO du bien Stone Town ; ancre urbaine, pas le départ d'un circuit. [UNESCO](https://whc.unesco.org/en/list/173/maps/) |
| ACTIVITY TZ id=10 — excursion Safari Blue | -6.31772 | 39.27737 | Point cartographique nommé Safari Blue dans la zone de Fumba, utilisé comme ancre de départ ; l'excursion se déroule en mer. [Mapcarta/OSM](https://mapcarta.com/N6540223812) |
| ATTRACTION TZ id=15 — Paje Beach | -6.267261 | 39.536082 | Même point GPS de référence que l'activité Paje. [Avygeo](https://www.avygeo.com/fr/guide/lieux-interet/78766-plage-de-paje) |
| ATTRACTION TZ id=16 — Nakupenda Sandbank | -6.23330 | 39.15000 | Position publiée 6°13.998′ S, 39°9.000′ E ; banc de sable soumis aux marées, point susceptible de ne pas correspondre à une terre émergée en permanence. [Beach Matters](https://beach-matters.com/beaches/nakupenda/) |
| ACTIVITY ZA id=6 — découverte du V&A Waterfront | -33.90602 | 18.42392 | Centre de référence du Victoria & Alfred Waterfront, OSM way 689159965. [Mapcarta/OSM](https://mapcarta.com/W689159965) |
| ATTRACTION ZA id=5 — V&A Waterfront | -33.90602 | 18.42392 | Même point cartographique de référence. [Mapcarta/OSM](https://mapcarta.com/W689159965) |
| ATTRACTION ZA id=6 — Table Mountain | -33.96216 | 18.41352 | Point de référence du relief Table Mountain, pas la station du téléphérique ni un départ de sentier. [Mapcarta](https://mapcarta.com/19067054) |

### Coordonnée laissée vide volontairement

- ACTIVITY TZ id=8 — visite guidée d'une ferme d'épices : le nom ne désigne pas un établissement unique. Les fermes de Kizimbani et des environs sont distinctes. Une coordonnée arbitraire ferait croire à tort que le produit mène à une ferme précise. La durée peut être estimée à partir d'un programme d'opérateur, mais le point restera NULL jusqu'à ce que le catalogue identifie la ferme.

## Durées proposées

| Fiche | Minutes | Base de l'estimation | Limite |
|---|---:|---|---|
| ACTIVITY MA id=4 — souks et médina | 180 | Visite guidée locale annoncée à environ 3 h. [Visit Marrakech Medina](https://www.visit-marrakech-medina.com/en/walking-tours-in-marrakech-explore-the-medina-on-foot) | Programme guidé cité, pas durée obligatoire pour une visite libre. |
| ACTIVITY TZ id=7 — Stone Town walking tour | 180 | AfriGo annonce une demi-journée d'environ 3 h. [AfriGo](https://afrigo.co.tz/tours/stone-town-tour) | Dépend des arrêts et du rythme du groupe. |
| ACTIVITY TZ id=8 — Spice Farm Tour | 210 | Milieu de la plage opérateur de 3 à 4 h (210 min). [AfriGo](https://afrigo.co.tz/tours/spice-farm-tour) | Le transfert et le déjeuner dépendent de la formule réservée ; durée indicative d'une excursion opérateur. |
| ACTIVITY TZ id=10 — Safari Blue | 510 | Milieu de la plage opérateur de 8 à 9 h (510 min). [AfriGo](https://afrigo.co.tz/tours/safari-blue) | Excursion d'une journée ; départ, transferts et conditions maritimes font varier le total. |

Aucune durée supplémentaire n'est écrite pour les autres fiches : les sources trouvées ne justifient pas une valeur numérique suffisamment précise et applicable à la fiche. En particulier, une durée d'ouverture, une durée d'un tour guidé facultatif ou un horaire de téléphérique ne sont pas assimilés à la durée de visite d'une attraction entière.

Lion's Head conserve sa valeur existante de 75 minutes, interprétée comme une durée de montée, et non comme un aller-retour.

## Effet attendu après exécution

Sur le périmètre des 27 fiches, sous réserve que la base corresponde toujours à l'extrait de référence :
- paires de coordonnées manquantes : **11 → 1** ;
- durées manquantes : **26 → 22** ;
- fiches restant `UNVERIFIED` : **aucune promotion** ; le script ne touche ni `data_status` ni `last_verified_at`.

L'unique coordonnée qui restera NULL dans ce lot est celle de l'activité générique de ferme d'épices. Les 22 durées manquantes sont laissées telles quelles faute de preuve suffisante.

## Fichiers et exécution

- `reports/catalog_remaining_gaps_audit.sql` : audit SELECT-only du périmètre des 27 fiches et résumé des écarts.
- `reports/catalog_remaining_gaps_manual.sql` : transaction manuelle contrôlée ; 10 corrections de coordonnées et 4 estimations de durée ; ce n'est pas une migration Flyway.

Exécuter d'abord l'audit pour comparer les valeurs de la base avec le périmètre attendu, puis exécuter le script de correction une seule fois. Le script de correction est protégé par des gardes sur les champs NULL : une seconde exécution échoue explicitement au premier enregistrement déjà corrigé au lieu de réécrire silencieusement les données.

Après exécution, vérifier les 11 lignes retournées par le SELECT final et relancer l'audit. Les fiches restent `UNVERIFIED` ; aucune n'est éligible à la recommandation tant que le contrôle métier complet n'a pas été réalisé.

## Garanties

- Aucun changement de source principale `source_name/source_url/source_type/source_scope`.
- Aucune modification des coûts, devises, heures d'ouverture, accès, disponibilité ou historique de vérification.
- Les liens des sources de coordonnées et de durée sont conservés dans `verification_notes`.
- Pas de données inventées pour la ferme d'épices générique ni pour les durées insuffisamment documentées.
- Pas de modification de code applicatif ou de migration de schéma.
