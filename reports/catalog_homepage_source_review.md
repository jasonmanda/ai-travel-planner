# Revue des sources du catalogue — faux positifs de pages d'accueil

## Portée

Cette correction traite un faux positif du filtre des sources et une référence
plus précise pour Table Mountain. Elle ne valide aucune fiche du catalogue et
ne modifie aucune donnée automatiquement.

## Faux positif détecté : pages d'accueil avec script d'index

Deux fiches Jozani étaient classées comme candidates institutionnelles parce que
leur URL se terminait par `/index.php` :

- activité TZ id 9 — Excursion dans la forêt de Jozani ;
- attraction TZ id 12 — Jozani Forest.

Une URL non racine n'est pas nécessairement une page dédiée. Le classificateur
Java rejette désormais les chemins finaux `index.php`, `index.html`,
`index.htm`, `default.aspx`, `default.html` et `home`, en plus des racines
de site déjà rejetées. Les deux blocs de classification du rapport SQL
reproduisent la même règle.

Conséquence attendue : les deux références Jozani sont classées
`SOURCE_REQUIRES_REVIEW` jusqu'à ce qu'une page officielle consacrée au parc
ou à la visite soit trouvée. Cette règle ne prétend pas analyser sémantiquement
le contenu de toutes les URL.

## Table Mountain — source dédiée trouvée

Pour l'attraction Table Mountain (ZA, attraction id 6), SANParks publie une page
spécifique à Table Mountain :

https://www.sanparks.org/parks/table-mountain/what-to-do/attractions/table-mountain

Cette page décrit explicitement la montagne, les promenades et randonnées, les
possibilités d'atteindre le sommet et le téléphérique. Elle est plus pertinente
que la page générale du parc national.

Le script manuel `catalog_table_mountain_source_update.sql` remplace uniquement
le nom et l'URL de la source, avec garde sur l'identifiant, le nom, l'ancienne
URL, le type, la portée et le statut. Il ne modifie ni `data_status`, ni
`last_verified_at`, ni les coordonnées, durées ou prix.

**Le statut reste UNVERIFIED.** Une page source plus pertinente n'est pas une
vérification factuelle des champs de la fiche.

## Autres cas examinés — pas de promotion automatique

- Safari Blue : la page de l'opérateur décrit précisément son propre circuit
  commercial. C'est une source primaire de fournisseur pour ce produit, mais
  pas une source institutionnelle. Le modèle actuel ne distingue pas encore
  proprement une source primaire d'opérateur d'une source officielle. La fiche
  reste donc à examiner ; ne pas la requalifier artificiellement en OFFICIAL.
- Spice Farm : des fermes nommées publient des descriptions de visites. La fiche
  actuelle est générique et ne désigne pas un opérateur précis. La remplacer
  nécessite une décision de produit sur le nom de l'expérience et une
  vérification de ses coordonnées ; aucune coordonnée ne doit être inventée.
- Monuments de Stone Town : l'Atlas du patrimoine urbain de l'UNESCO décrit
  plusieurs monuments individuellement, ce qui étaye leur contexte historique.
  Cela ne confirme pas les horaires, l'accès public, les conditions de visite
  ou l'état d'ouverture actuel. Les références générales restent en revue.
- Nakupenda : une page d'opérateur secondaire n'est pas une source
  institutionnelle ; elle ne doit pas être requalifiée en OFFICIAL.
- Les références générales Banque de Tanzanie, guide CHAN et circulaire
  EAPCE25 ne deviennent pas des preuves touristiques spécifiques par la seule
  présence de noms de lieux.

## Tests et exécution manuelle

Le test ajouté vérifie que les URL d'accueil scriptées ne sont pas classées
comme candidates. Exécuter localement :

```bash
mvn -Dtest=CatalogSourceQualityTest,CatalogSourceTransparencyTest test
```

Après validation de la PR, exécuter le script SQL Table Mountain dans pgAdmin,
puis relancer `reports/catalog_recommendation_eligibility_audit.sql`.

Aucune fiche n'est promue à `VERIFIED` par cette PR ou par le script SQL.
