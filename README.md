# AI Travel Planner — Backend MVP

API de démarrage : demandes de voyage, catalogue de destinations et premier moteur de recommandation déterministe.

## Stack
- Java 21 / Spring Boot 4.0.0
- Spring MVC, Spring Data JPA, Validation, Actuator
- PostgreSQL 16 + PostGIS 3.4
- Flyway / Maven

> Cette version est un socle backend. Les trois destinations et leurs budgets journaliers sont des données de démonstration, pas des prix vérifiés. Le calcul ne constitue pas encore une recommandation IA. Spring AI/OpenAI, les formalités officielles, les activités détaillées, les itinéraires et les réservations ne sont pas encore intégrés.

## Démarrer
Prérequis : JDK 21+, Maven 3.9+, Docker.

```bash
docker compose up -d
mvn spring-boot:run
```

API : http://localhost:8080 — santé : http://localhost:8080/actuator/health. Flyway crée le schéma et insère Zanzibar, Marrakech et Le Cap.

Base locale : `travel_planner`, utilisateur `travel_user`, mot de passe `travel_password` (développement uniquement).

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

Le MVP utilise PostgreSQL 16 standard. Les coordonnées sont stockées dans `cities.latitude` et `cities.longitude`. PostGIS n'est pas requis à ce stade. Les migrations Flyway V1 et V2 ne créent donc aucune extension PostgreSQL.

Si une ancienne tentative Flyway a laissé une migration en échec, vérifiez `flyway_schema_history` avant de relancer. Ne supprimez pas le volume ni les données. Si V1 ou V2 a déjà été appliquée avec succès sur une base existante, ne modifiez pas ces migrations versionnées : créez plutôt une nouvelle migration corrective.

## Recommendation Engine V2

The deterministic recommendation engine currently ranks destinations with these weights:

- Interests/tags: 45%
- Budget fit: 40%
- Travel style inferred from catalog tags: 10%
- Preferred city/country: 5%

A neutral score is used when a criterion is not supplied or cannot safely be compared. Budget estimates are calculated as `estimated_daily_budget × duration × (adults + children)`. Each city stores the currency of its estimate in `estimated_daily_budget_currency`; V3 initializes existing demo estimates to XOF. If the requested budget uses another currency, the engine does not compare the amounts and returns `CURRENCY_NOT_COMPARABLE` rather than pretending an exchange conversion occurred.

The response includes `scoreBreakdown`, `matchedInterests`, `estimateBasis`, `estimateLimitations`, coordinates, and `notEvaluatedCriteria`. Nationality/entry formalities, seasonality, departure transport cost, and destination scope are not scored yet because the current catalog has no verified data for them. This is intentional: no visa, flight-price, or seasonal claim is invented.

### Flyway migration V3

`V3__add_estimate_currency.sql` adds `estimated_daily_budget_currency` with default `XOF`. Keep `ddl-auto: validate`; let Flyway apply the migration. Do not edit migrations already applied to a shared or production database.

### Test recommendation generation

Create a trip with `POST /api/v1/trips`, copy the returned `id`, then call:

```bash
curl -X POST http://localhost:8080/api/v1/trips/REPLACE_WITH_TRIP_UUID/recommendations
```

The returned recommendations include a score breakdown and explicit warnings about criteria that are not evaluated. The engine is deterministic and does not call OpenAI yet.
