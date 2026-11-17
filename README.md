# AI Travel Planner — Backend MVP

API de démarrage : demandes de voyage, catalogue de destinations et premier moteur de recommandation déterministe.

## Stack
- Java 21 / Spring Boot 4.0.0
- Spring MVC, Spring Data JPA, Validation, Actuator
- PostgreSQL 16 standard (sans PostGIS)
- Maven

> Cette version est un socle backend. Les trois destinations et leurs budgets journaliers sont des données de démonstration, pas des prix vérifiés. Le calcul ne constitue pas encore une recommandation IA. Spring AI/OpenAI, les formalités officielles, les activités détaillées, les itinéraires et les réservations ne sont pas encore intégrés.

## Démarrer
Prérequis : JDK 21+, Maven 3.9+, Docker.

```bash
docker compose up -d
mvn spring-boot:run
```

API : http://localhost:8080 — santé : http://localhost:8080/actuator/health.

Base locale : `travel_planner`, utilisateur `travel_user`, mot de passe `travel_password` (développement uniquement).

## Gestion du schéma SQL

Les évolutions de la base sont conservées sous forme de scripts SQL versionnés dans `src/main/resources/db/migration/` (V1, V2, etc.), mais **ils ne sont pas exécutés automatiquement**.

- Exécuter manuellement chaque nouveau script SQL, dans l'ordre, sur la base cible.
- Ne jamais réexécuter un script déjà appliqué.
- Ne jamais modifier un ancien script déjà appliqué à une base existante : créer un nouveau fichier SQL avec le prochain numéro de version.
- Avant une évolution, vérifier la structure et les données concernées, puis conserver le résultat de l'exécution.
- Hibernate est configuré avec `ddl-auto: validate` : il vérifie la correspondance entre les entités et le schéma, sans créer ni modifier les tables.

Pour appliquer manuellement un script depuis un terminal avec PostgreSQL :

```bash
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f src/main/resources/db/migration/V18__add_price_verification_transparency.sql
```

Adapter le nom du fichier à la migration à appliquer. Si la variable `DB_URL` n'est pas définie, utiliser explicitement les paramètres de connexion de votre environnement.

## Endpoints
- `GET /api/v1/destinations`
- `POST /api/v1/trips`
- `GET /api/v1/trips/{id}`
- `POST /api/v1/trips/{id}/recommendations`
- `GET /api/v1/trips/{id}/recommendations`

### Exemple de création
```json
{
  "departureCity": "Dakar, Sénégal",
  "nationality": "Sénégalaise",
  "adults": 2, "children": 1,
  "budget": 1500000, "currency": "XOF",
  "duration": 7, "travelPeriod": "Dates flexibles",
  "travelStyle": "En famille",
  "destinationScope": "Afrique et monde",
  "interests": ["Plage", "Culture", "Gastronomie"]
}
```

La réponse POST contient l'UUID `id`; utilisez-le pour appeler le endpoint recommendations.

## Configuration
Variables : `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `CORS_ALLOWED_ORIGINS`. Les valeurs par défaut sont prévues uniquement pour le développement local.

## Architecture
`destination/` catalogue pays-villes; `trip/` demandes; `recommendation/` scoring; `config/` CORS; `common/` gestion des erreurs.

## Limites connues et suite
- Le budget calculé = budget journalier catalogue × durée × voyageurs; vols, visas, assurances et coûts réels d'hébergement ne sont pas inclus.
- Le score est explicable mais très simple; il devra évoluer et être testé.
- Les formalités d'entrée doivent être alimentées par des sources officielles et datées.
- Ajouter ensuite activités/attractions, itinéraire, tests d'intégration PostgreSQL, sécurité, puis Spring AI compatible avec Boot 4.

## Base de données MVP (sans PostGIS)

Le MVP utilise PostgreSQL 16 standard. Les coordonnées sont stockées dans `cities.latitude` et `cities.longitude`. PostGIS n'est pas requis.

Les scripts SQL versionnés sont appliqués manuellement. Si un script a échoué, examiner l'erreur et l'état réel du schéma avant toute nouvelle tentative. Ne supprimez pas le volume ni les données. Si un script a déjà été appliqué avec succès, ne le modifiez pas : ajoutez un nouveau script correctif.

## Recommendation Engine V2

The deterministic recommendation engine currently ranks destinations with these weights:

- Interests/tags: 45%
- Budget fit: 40%
- Travel style inferred from catalog tags: 10%
- Preferred city/country: 5%

A neutral score is used when a criterion is not supplied or cannot safely be compared. Budget estimates are calculated as `estimated_daily_budget × duration × (adults + children)`. Each city stores the currency of its estimate in `estimated_daily_budget_currency`; V3 initializes existing demo estimates to XOF. If the requested budget uses another currency, the engine does not compare the amounts and returns `CURRENCY_NOT_COMPARABLE` rather than pretending an exchange conversion occurred.

The response includes `scoreBreakdown`, `matchedInterests`, `estimateBasis`, `estimateLimitations`, coordinates, and `notEvaluatedCriteria`. Nationality/entry formalities, seasonality, departure transport cost, and destination scope are not scored yet because the current catalog has no verified data for them. This is intentional: no visa, flight-price, or seasonal claim is invented.

### SQL script V3

`V3__add_estimate_currency.sql` adds `estimated_daily_budget_currency` with default `XOF`. Apply it manually once to each database that needs this schema change. Keep `ddl-auto: validate`; Hibernate must not alter the schema.

### Test recommendation generation

Create a trip with `POST /api/v1/trips`, copy the returned `id`, then call:

```bash
curl -X POST http://localhost:8080/api/v1/trips/REPLACE_WITH_TRIP_UUID/recommendations
```

The returned recommendations include a score breakdown and explicit warnings about criteria that are not evaluated. The engine is deterministic and does not call OpenAI yet.


## Vérification administrative des budgets journaliers (V21)

Le endpoint suivant permet à un administrateur de vérifier le budget journalier d'une ville :

`POST /api/v1/admin/catalog/cities/{id}/budget-verifications`

Il exige une authentification HTTP Basic avec le rôle `ADMIN`. Configurez `APP_ADMIN_USERNAME` et `APP_ADMIN_PASSWORD` avant de démarrer l'application.

Exemple de corps JSON :

```json
{
  "dailyBudget": 52000.00,
  "currency": "XOF",
  "sourceName": "Office national du tourisme",
  "sourceUrl": "https://example.org/city-budget-source",
  "verificationNotes": "Budget journalier contrôlé pour un voyageur, hors transport international."
}
```

La requête enregistre un instantané dans `city_budget_verification_history`, puis met à jour la ville en `VERIFIED` dans la même transaction. L'historique est append-only : une correction doit créer un nouvel événement, jamais modifier ou supprimer l'ancien.

La migration `V21__add_city_budget_verification_history.sql` doit être appliquée manuellement après V20. Elle ne valide aucune ville existante.


## Instantané des budgets dans les recommandations (V22)

Chaque recommandation conserve désormais le montant total estimé, la devise, le statut de confiance, la source, l'URL, la date de vérification et les notes tels qu'ils existaient au moment de sa génération. Une vérification ultérieure du budget d'une ville ne réécrit donc pas l'historique des recommandations déjà enregistrées.

Les anciennes recommandations ne sont pas rétroactivement qualifiées : leurs champs d'instantané restent NULL lorsque l'état historique ne peut pas être établi de façon fiable.

Appliquer manuellement `V22__snapshot_recommendation_budget_metadata.sql` après V21.
