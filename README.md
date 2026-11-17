# AI Travel Planner — Backend MVP

API de démarrage : demandes de voyage, catalogue de destinations, moteur de recommandation déterministe et génération d'itinéraires.

## Stack
- Java 21 / Spring Boot 4.0.0
- Spring AI 2.0.2 / OpenAI Chat
- Spring MVC, Spring Data JPA, Validation, Actuator
- PostgreSQL 16 standard (sans PostGIS)
- Maven

Les destinations, budgets et éléments du catalogue ne sont pas tous vérifiés. Les estimations restent distinctes des prix confirmés. Les formalités, horaires, accès et disponibilités ne sont jamais déduits par le modèle IA.

## Démarrer
Prérequis : JDK 21+, Maven 3.9+, Docker.

```bash
docker compose up -d
mvn spring-boot:run
```

API : http://localhost:8080 — santé : http://localhost:8080/actuator/health.

Base locale : `travel_planner`, utilisateur `travel_user`, mot de passe `travel_password` (développement uniquement).

## Configuration IA (facultative)

L'intégration Spring AI/OpenAI est désactivée par défaut : l'application et le moteur déterministe restent utilisables sans clé API.

Pour activer le guide IA :

```bash
export APP_AI_ENABLED=true
export SPRING_AI_MODEL_CHAT=openai
export OPENAI_API_KEY="votre-cle-openai"
export OPENAI_MODEL="gpt-5-mini"
mvn spring-boot:run
```

Ne commitez jamais la clé API et ne la placez pas dans `application.yml`. En production, utilisez un gestionnaire de secrets. Les appels IA entraînent une consommation et une facturation OpenAI. Sans `SPRING_AI_MODEL_CHAT=openai`, l'auto-configuration du modèle reste désactivée.

## Endpoints
- `GET /api/v1/destinations`
- `POST /api/v1/trips`
- `GET /api/v1/trips/{id}`
- `POST /api/v1/trips/{id}/recommendations`
- `GET /api/v1/trips/{id}/recommendations`
- `POST /api/v1/trips/{tripId}/itinerary?destinationId={cityId}`
- `GET /api/v1/itineraries/{itineraryId}`
- `POST /api/v1/itineraries/{itineraryId}/ai-guide` (uniquement si `APP_AI_ENABLED=true` et `SPRING_AI_MODEL_CHAT=openai`)

### Guide IA d'un itinéraire

Le guide IA travaille exclusivement à partir d'un itinéraire déjà généré et des informations de son catalogue. Il produit une synthèse, une lecture par journée et des rappels de vérification. Les jours retournés sont filtrés côté serveur pour ne conserver que les numéros de journées existants.

Le guide ne choisit pas de nouveaux lieux, ne vérifie pas le web et ne certifie pas les informations. Les règles d'éligibilité du catalogue et le planificateur déterministe restent la source de vérité. En cas d'indisponibilité du fournisseur IA, l'itinéraire déterministe existant reste accessible via son endpoint habituel.

## Gestion du schéma SQL

Les évolutions de la base sont conservées sous forme de scripts SQL versionnés dans `src/main/resources/db/migration/` (V1, V2, etc.), mais **ils ne sont pas exécutés automatiquement**.

- Exécuter manuellement chaque nouveau script SQL, dans l'ordre, sur la base cible.
- Ne jamais réexécuter un script déjà appliqué.
- Ne jamais modifier un ancien script déjà appliqué à une base existante : créer un nouveau fichier SQL avec le prochain numéro de version.
- Avant une évolution, vérifier la structure et les données concernées, puis conserver le résultat de l'exécution.
- Hibernate est configuré avec `ddl-auto: validate` : il vérifie la correspondance entre les entités et le schéma, sans créer ni modifier les tables.

## Recommendation Engine V2

Le moteur déterministe classe les destinations avec des poids explicables : intérêts/tags (45 %), adéquation budgétaire (40 %), style de voyage (10 %) et destination préférée (5 %). Un score neutre est appliqué lorsqu'un critère ne peut pas être évalué de façon fiable.

Le budget estimé est calculé comme `estimated_daily_budget × duration × travellers`. Si la devise ou la vérification ne permet pas une comparaison fiable, le montant n'est pas utilisé pour le score. Les formalités d'entrée, la saisonnalité et le transport au départ ne sont pas évalués sans données vérifiées.

## Itinéraires et qualité des données

Le planificateur existant conserve les suggestions non planifiées, regroupe les éléments géographiquement et n'accepte que les fiches qui passent les contrôles de preuve du catalogue. Les tarifs, horaires, accès et disponibilités sont contrôlés séparément et ne sont pas garantis.

## Sécurité et configuration

Variables : `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `CORS_ALLOWED_ORIGINS`, `APP_AI_ENABLED`, `SPRING_AI_MODEL_CHAT`, `OPENAI_API_KEY`, `OPENAI_MODEL`. Les valeurs de base de données par défaut sont réservées au développement local.

Les endpoints d'administration du catalogue exigent HTTP Basic avec le rôle `ADMIN`. Configurez `APP_ADMIN_USERNAME` et `APP_ADMIN_PASSWORD` avant de démarrer l'application.
