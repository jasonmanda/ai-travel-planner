# Travel Catalog

Le backend expose un catalogue structuré par destination sans dépendance PostGIS.

## Scripts SQL

Les fichiers `V1__...`, `V2__...`, etc. sont des scripts SQL versionnés et exécutés manuellement. Ils ne sont pas appliqués automatiquement au démarrage de l'application.

- `V4__create_travel_catalog.sql` crée les tables `attractions`, `activities`, `city_budget_components` et `city_seasons`.
- `V7__seed_zanzibar_geographic_sample.sql` ajoute trois points géographiques de référence dans Stone Town.
- `V8__enrich_zanzibar_travel_catalog.sql` enrichit Zanzibar avec des attractions patrimoniales, naturelles et balnéaires ainsi que des idées d'activités.

Ne réexécutez pas un script déjà appliqué et ne modifiez jamais un ancien script appliqué : ajoutez un nouveau fichier SQL avec le prochain numéro de version.

## Endpoints

- `GET /api/v1/destinations/{cityId}/catalog` : catalogue complet.
- `GET /api/v1/destinations/{cityId}/catalog/attractions`
- `GET /api/v1/destinations/{cityId}/catalog/activities`
- `GET /api/v1/destinations/{cityId}/catalog/budget`
- `GET /api/v1/destinations/{cityId}/catalog/seasons`

Exemple :

```bash
curl http://localhost:8080/api/v1/destinations/1/catalog
```

## Fiabilité et provenance

- Les nouvelles entrées V8 sont `UNVERIFIED`.
- Les sources référencées sont des points de départ documentaires, pas une validation des conditions pratiques.
- Les coordonnées, prix, durées, horaires, âges minimums et disponibilités restent nuls lorsqu'ils ne sont pas confirmés.
- Ne passer une entrée à `VERIFIED` qu'après contrôle d'une source adaptée et enregistrement de `last_verified_at`.
- Une valeur de coût nulle signifie « inconnue », jamais « gratuite ».
- Les lieux sans coordonnées restent non géolocalisés : le planificateur ne doit pas inventer leur position.

Sources de référence utilisées pour l'enrichissement :
- UNESCO, Stone Town Urban Heritage Atlas : https://whc.unesco.org/en/urban-heritage-atlas/stone-town
- Portail officiel Visit Zanzibar : https://visitzanzibar.go.tz/

## Démarrage et validation

```bash
mvn clean test
mvn spring-boot:run
```

Hibernate conserve `spring.jpa.hibernate.ddl-auto: validate` : il valide le schéma existant, mais ne crée ni ne modifie les tables. Appliquer les scripts SQL nécessaires manuellement avant de démarrer l'application.
