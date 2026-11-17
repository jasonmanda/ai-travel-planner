# Revue des coordonnées et durées — lot catalogue 27 fiches

Date de recherche : 17 novembre 2026.

## Périmètre observé

L'extrait PostgreSQL fourni couvre 27 fiches actives :
- 17 fiches sans paire de coordonnées ;
- 10 fiches avec une paire de coordonnées ;
- 26 fiches sans durée renseignée ;
- 1 durée renseignée : Lion's Head, 75 minutes.

Toutes les fiches sont encore `UNVERIFIED`. Cette revue ne modifie aucun statut de vérification.

## Correction géographique justifiée

### Stone Town — activité et attraction

L'UNESCO publie les coordonnées géographiques du bien « Stone Town of Zanzibar » sur sa page cartographique :
- latitude : S 6° 9' 47.016" ;
- longitude : E 39° 11' 21.012".

Conversion décimale arrondie à trois décimales : **-6.163, 39.189**.

Cette coordonnée est un point de référence du bien patrimonial, pas une adresse ni un point de départ de visite. Elle peut être utilisée pour :
- ACTIVITY id=2 — « Découverte du patrimoine de Stone Town » ;
- ATTRACTION id=2 — « Stone Town ».

Le script SQL associé remplit uniquement les deux paires actuellement NULL, sous contrôle de l'ID, du nom, de la ville et du pays. Il échoue si exactement une ligne de chaque type n'est pas modifiée.

Source primaire :
- UNESCO World Heritage Centre — Stone Town of Zanzibar, Maps: https://whc.unesco.org/en/list/173/maps/

## Durées : aucune nouvelle valeur écrite

Les sources primaires consultées ne donnent pas une durée suffisamment spécifique pour remplir les autres 26 fiches sans transformer une hypothèse en fait :

- Jardin Majorelle : le site officiel décrit le jardin (9 000 m²) et les conditions de visite, mais ne prescrit pas de durée de visite. Source : https://www.jardinmajorelle.com/lejardin/
- Souks et médina de Marrakech : Visit Morocco décrit plusieurs souks et quartiers, sans durée d'itinéraire. Source : https://www.visitmorocco.com/fr/voyage/marrakech/shopping
- Stone Town : la documentation UNESCO décrit le bien patrimonial, sans durée standard de promenade.
- Jozani : le site du parc est une source d'information sur le parc, mais la page consultée ne justifie pas une durée universelle pour l'excursion.
- Safari Blue, plantation d'épices, Prison Island et Nakupenda : les durées dépendent de l'opérateur, du programme, du transport et des conditions du jour ; aucune durée générique n'est ajoutée.
- V&A Waterfront : la page officielle explique l'accès et les installations, pas une durée type de visite. Source : https://www.waterfront.co.za/visitor-information
- Table Mountain : SANParks documente des durées par itinéraire de randonnée, et non une durée globale de visite de l'attraction. Source : https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails

### Contrôle de cohérence d'une source écartée

La page Visit Morocco sur la médina de Marrakech expose des métadonnées géographiques avec latitude 31.633624 et longitude positive 7.984948. La longitude positive ne correspond pas à la position géographique de Marrakech à l'ouest du méridien de Greenwich. Cette valeur n'est donc pas utilisée pour renseigner le catalogue.
Source : https://www.visitmorocco.com/fr/medina-de-marrakech

### Lion's Head

La durée existante de 75 minutes reste inchangée. SANParks indique 1 à 1,5 heure de montée sur sa page de sentiers. Cela confirme la cohérence de la valeur existante comme estimation de montée, pas une durée aller-retour.
Source : https://www.sanparks.org/parks/table-mountain/what-to-do/activities/hikes-walks-trails

## Éléments volontairement non modifiés

Aucune coordonnée n'est ajoutée pour les souks, Jemaa el-Fna, Paje Beach, Prison Island, Lion's Head, V&A Waterfront ou Table Mountain dans ce lot : les sources primaires consultées ne fournissent pas un point suffisamment précis pour la fiche concernée.

Les coordonnées déjà renseignées dans les 10 autres lignes sont conservées sans changement. La revue ne modifie aucun nom, source, prix, durée, `data_status`, `last_verified_at` ou historique de vérification.

## Exécution manuelle

Exécuter `reports/catalog_stone_town_reference_coordinates.sql` manuellement dans pgAdmin. Ce fichier est un script de correction contrôlé, **pas une migration Flyway**.

Après exécution, relancer l'audit de recommandation. Les deux fiches Stone Town resteront `UNVERIFIED` et ne seront donc pas éligibles à la recommandation tant que la validation métier complète n'aura pas été réalisée.
