# Travel Catalog V2

Cette version ajoute un catalogue structuré au backend Spring Boot 4 sans dépendance PostGIS.

## Migration

Flyway applique `V4__create_travel_catalog.sql` après V1-V3. Ne modifiez pas les migrations déjà appliquées. Les tables créées sont :

- `attractions`
- `activities`
- `city_budget_components`
- `city_seasons`

La migration ajoute des catégories de budget par ville, sans inventer de montants. Quelques attractions et idées d'activités de démarrage sont insérées avec `data_status = UNVERIFIED`; elles ne constituent pas des informations pratiques vérifiées. Aucun tarif, horaire, coordonnées ou donnée saisonnière n'est inventé.

## Endpoints

- `GET /api/v1/destinations/{cityId}/catalog` : catalogue complet d'une ville.
- `GET /api/v1/destinations/{cityId}/catalog/attractions`
- `GET /api/v1/destinations/{cityId}/catalog/activities`
- `GET /api/v1/destinations/{cityId}/catalog/budget`
- `GET /api/v1/destinations/{cityId}/catalog/seasons`

Les listes peuvent être vides si aucune donnée n'a été renseignée. Une ville inconnue retourne HTTP 404.

## Exemple

```bash
curl http://localhost:8080/api/v1/destinations/1/catalog
```

## Politique de fiabilité

`dataStatus` permet de distinguer les données `UNVERIFIED`, `NOT_AVAILABLE` et les données qui seront ultérieurement `VERIFIED`. Une donnée ne doit passer à `VERIFIED` qu'après ajout d'une source fiable et d'une date de vérification. Les montants nuls signifient « non disponible », jamais zéro.

## Démarrage

Vérifier d'abord que la base utilisée par Spring Boot est la bonne, puis lancer :

```bash
mvn clean spring-boot:run
```

Flyway appliquera V4 automatiquement si V1-V3 sont déjà enregistrées avec succès. Garder `spring.jpa.hibernate.ddl-auto: validate`.
