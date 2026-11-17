# Revue complémentaire des coordonnées et durées — lot catalogue

Date de revue : 17 novembre 2026. Référence de départ : après fusion de la PR #50 et application du script Stone Town dans la base.

## État du lot

Sur les 27 fiches initiales :
- 15 fiches restaient sans paire de coordonnées après la correction Stone Town ;
- 26 fiches restent sans durée renseignée ;
- Lion's Head conserve sa durée existante de 75 minutes, interprétée comme durée de montée (pas aller-retour) ;
- les fiches restent `UNVERIFIED`.

Cette PR propose quatre compléments de coordonnées pour trois lieux distincts (Jardin Majorelle dans les deux tables, Prison Island et Lion's Head). Après application, 11 fiches du lot initial devraient encore être sans paire de coordonnées. Les durées restent inchangées : aucune durée additionnelle n'est ajoutée.

## Coordonnées proposées

| Fiche | Latitude | Longitude | Interprétation et source |
|---|---:|---:|---|
| ACTIVITY MA id=3 — activité liée au Jardin Majorelle (identification par ID, ville et pays) | 31.64137 | -8.00292 | Point représentatif du jardin, issu de la géométrie OpenStreetMap way 41922120. [OpenStreetMap](https://www.openstreetmap.org/way/41922120) ; coordonnées affichées par [Mapcarta](https://mapcarta.com/fr/27412860) à partir d'OSM. |
| ATTRACTION MA id=3 — Jardin Majorelle | 31.64137 | -8.00292 | Même lieu et même point représentatif ; même référence géographique. |
| ATTRACTION TZ id=13 — Prison Island (Changuu) | -6.120402 | 39.168599 | Coordonnées de Changuu (Prison) figurant dans un document budgétaire de la Chambre des représentants de Zanzibar. [Document gouvernemental](https://www.zanzibarassembly.go.tz/public/storage/documents/Budgets/all/1735288194.pdf) |
| ACTIVITY ZA id=5 — activité Lion's Head (identification par ID, ville et pays) | -33.9696 | 18.3969 | Coordonnée du mont Lion's Head dans la fiche South African History Online. C'est un point de référence du relief, pas le départ du sentier. [South African History Online](https://sahistory.org.za/place/lions-head-mt) |

Les coordonnées ne sont renseignées que si la paire latitude/longitude est entièrement NULL et si l'identité du pays, de la ville, de l'ID et du nom correspond exactement. Le script s'interrompt et annule la transaction si une des quatre mises à jour ne touche pas exactement une ligne.

## Durées : aucune nouvelle valeur ajoutée

Les 26 durées manquantes ne sont pas remplies dans cette PR. Les sources consultées ne justifient pas une durée générique fiable pour les fiches concernées :

- Jardin Majorelle : le site officiel décrit le jardin et ses installations, sans prescrire de durée de visite : https://www.jardinmajorelle.com/lejardin/
- Souks et médina de Marrakech : Visit Morocco décrit les souks/quartiers, sans durée d'itinéraire : https://www.visitmorocco.com/fr/voyage/marrakech/shopping
- Stone Town : les références UNESCO décrivent le bien patrimonial, sans durée standard de promenade : https://whc.unesco.org/en/list/173/
- Jozani : la source officielle du parc ne fixe pas une durée universelle pour une excursion : https://www.jozanichwakabaynationalpark.go.tz/
- Safari Blue, plantation d'épices, Prison Island et Nakupenda : les durées varient selon l'opérateur, le programme, le transport et les conditions du jour.
- V&A Waterfront : la page officielle décrit les informations visiteurs, pas une durée type : https://www.waterfront.co.za/visitor-information
- Table Mountain : SANParks publie des durées pour des itinéraires précis, pas une durée globale de visite : https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails

Lion's Head reste à 75 minutes : SANParks indique 1 à 1,5 heure de montée. Cette valeur ne doit pas être interprétée comme une durée aller-retour.

## Garanties

- Aucun passage automatique à `VERIFIED`.
- Aucun changement de `data_status`, `last_verified_at`, des sources ou de l'historique de vérification.
- Aucune durée estimée inventée.
- Le script SQL est manuel, à exécuter dans pgAdmin ; ce n'est pas une migration Flyway.
- La PR ne modifie pas les données de la base tant que le script n'a pas été exécuté.

## Exécution

Exécuter `reports/catalog_remaining_coordinates_manual.sql` dans pgAdmin, puis vérifier les quatre lignes retournées par la requête de contrôle incluse à la fin du script. Les statuts doivent rester `UNVERIFIED`.
