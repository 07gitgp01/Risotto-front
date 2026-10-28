# CLAUDE.md — risotto-front

Application mobile Flutter (Android + iOS) de **Risotto**, réseautage professionnel. API : `risotto-back` (NestJS).
Langue des échanges : français. Code, commits, noms techniques : anglais.

## Décisions techniques
- Flutter stable (3.38+), Dart 3. Cibles : Android et iOS uniquement.
- État : Riverpod (`flutter_riverpod`, providers écrits à la main, pas de codegen).
- Navigation : go_router, redirection selon l'état d'authentification.
- HTTP : dio avec intercepteur (ajout du bearer, refresh automatique sur 401 avec verrou unique).
- Stockage des tokens : flutter_secure_storage uniquement (jamais SharedPreferences).
- Temps réel : socket_io_client vers `/ws`.
- QR : `qr_flutter` (affichage), `mobile_scanner` (scan).
- Configuration : `--dart-define=API_BASE_URL=...` (défaut émulateur Android : `http://10.0.2.2:3000/api`).
- Structure feature-first : `lib/core` (config, réseau, thème, routeur, stockage), `lib/features/<feature>/{data,application,presentation}`.

## Charte graphique « Risotto » (`lib/core/theme/`)
| Rôle | Nom | Hex |
|---|---|---|
| Principale | Safran | `#E8A317` |
| Fond | Crème | `#FFF6E0` |
| Secondaire | Vert basilic | `#2F6B4F` |
| Texte | Charbon | `#1F2421` |
| Alertes | Tomate | `#D6452F` |
- Boutons safran avec **texte charbon** (lisibilité, contraste ≥ 4.5:1). Jamais de texte blanc sur safran.
- Toujours passer par `Theme.of(context)` / `RisottoColors`, jamais de couleur en dur dans les widgets.
- Accessibilité : `Semantics` sur les éléments interactifs sans texte, cibles tactiles ≥ 48 dp, support du text scaling.

## Sécurité
- Tokens uniquement dans flutter_secure_storage ; purge complète à la déconnexion ou si le refresh échoue.
- Jamais de secret dans le code : les URLs passent par `--dart-define`.
- Aucune donnée sensible dans les logs (pas d'impression des tokens ni des réponses d'auth).
- HTTP en clair autorisé uniquement en debug pour l'émulateur (network security config Android / ATS iOS limités au local).

## Git
- Branche de travail : `develop`. Jamais de push sur `main`, jamais de `--force`.
- Commits petits, Conventional Commits, push à la fin de chaque jalon.

## Tests
- `flutter analyze` sans erreur ni warning, tests unitaires (repositories, notifiers) et tests de widgets (écrans).
- Les appels réseau sont simulés via des fakes de repository injectés par `ProviderScope(overrides: ...)`.
- On ne passe pas au jalon suivant tant que `flutter analyze && flutter test` ne passent pas.

## Commandes locales
```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api   # émulateur Android
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api  # simulateur iOS
```

## Jalons
- [ ] 1. Fondations (structure, CI, configuration, thème Risotto)
- [ ] 2. Authentification (écrans inscription, connexion, mot de passe oublié, refresh, déconnexion)
- [ ] 3. Profil (création, édition, photo, visibilité)
- [ ] 4. Contacts et partage (carte de contact, QR code personnel, scan)
- [ ] 5. Mise en relation (recherche, demande, acceptation/refus, blocage)
- [ ] 6. Messagerie (WebSocket, historique paginé, accusés de lecture)
- [ ] 7. Notifications (temps réel, push FCM, préférences)
- [ ] 8. Tableau de bord (demandes en attente, non lus, activité récente)
- [ ] 9. Finalisation (sécurité, performances, accessibilité, hors ligne)
