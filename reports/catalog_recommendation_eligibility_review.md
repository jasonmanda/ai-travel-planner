# Audit opérationnel et filtre d'éligibilité du catalogue

## Constat corrigé

Avant cette évolution, `ItineraryService` chargeait les entrées actives dont le statut était différent de `REJECTED`. Les fiches `UNVERIFIED` et `PARTIALLY_VERIFIED` pouvaient donc être placées dans un itinéraire, même si la réponse API signalait leurs limites.

Le générateur applique maintenant un filtre d'éligibilité avant le scoring et la planification.

## Règles d'éligibilité

Une attraction ou activité doit satisfaire **toutes** les conditions suivantes :

1. `data_status = VERIFIED` (statut dérivé de preuves de vérification des valeurs essentielles, pas de la seule présence d'une URL).
2. Source classée `ITEM_SPECIFIC_PRIMARY_CANDIDATE` : source institutionnelle/officielle, portée `ITEM_SPECIFIC`, URL exploitable et chemin non identifié comme simple page d'accueil ou répertoire générique.
3. Latitude et longitude présentes, finies et dans les plages géographiques valides.
4. Durée strictement positive.
5. Nom et catégorie renseignés.

Un candidat qui échoue à une seule condition est exclu du moteur de planification. La qualité documentaire et la correspondance aux préférences ne peuvent pas compenser une preuve insuffisante.

## Ce que ce filtre ne prétend pas garantir

Le filtre n'est pas un moteur de disponibilité en temps réel. Le schéma actuel ne modélise pas les horaires d'ouverture, les conditions d'accès, les fermetures temporaires ni la disponibilité des opérateurs. Les prix restent indisponibles ou estimatifs tant qu'une vérification de prix indépendante ne les confirme pas. Les champs de compatibilité familiale et d'âge minimum restent à contrôler pour les activités lorsqu'ils sont nuls.

Ces limites sont désormais exposées dans l'audit SQL. Une fiche éligible signifie seulement qu'elle possède les éléments de base requis pour être planifiée; elle ne garantit pas qu'une visite sera possible à une date donnée.

## Traçabilité

La table `itineraries` conserve le nombre de candidats après dédoublonnage, le nombre admis et le nombre exclus. La réponse de l'itinéraire expose ces compteurs dans `recommendationEligibility`.

La migration `V27__persist_recommendation_eligibility_counts.sql` ajoute ces colonnes avec des valeurs par défaut à zéro pour les itinéraires existants. Elle ne modifie aucune fiche du catalogue ni aucun historique de vérification.

## Audit manuel

Exécuter `reports/catalog_recommendation_eligibility_audit.sql` dans pgAdmin. Le script contient uniquement des requêtes `SELECT` et n'est pas une migration Flyway.

Le premier résultat détaille chaque fiche active, la qualité de sa source, les données de planification présentes, les motifs d'exclusion et les champs opérationnels non modélisés. Le second donne les compteurs globaux.

## Conséquence attendue

Le nombre de suggestions générées peut diminuer, voire être nul pour une destination tant que les fiches n'ont pas été vérifiées. C'est intentionnel : le moteur préfère produire un programme incomplet ou demander un enrichissement du catalogue plutôt que présenter une donnée non étayée comme une recommandation fiable.
