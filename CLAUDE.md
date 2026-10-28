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
- Teinte dérivée `tomatoDeep` `#B23A26` (= `colorScheme.error`) pour le texte d'erreur et les boutons d'erreur : la tomate n'atteint que 4,1:1 sur crème. La tomate reste pour icônes, bordures, fonds. Le safran ne sert jamais de couleur de texte sur crème (2:1).
- Les contrastes sont vérifiés par `test/core/theme/risotto_theme_test.dart` (WCAG AA 4.5:1).
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
dart format lib test                # la CI échoue si le code n'est pas formaté
flutter analyze
flutter test
flutter run                         # émulateur Android, API par défaut http://10.0.2.2:3000/api
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api  # simulateur iOS (défaut sur iOS)
flutter build apk --debug
```
- Identifiants d'application : `com.risotto.risotto` (Android et iOS).
- Riverpod 3 : `Provider` / `FutureProvider` / `Notifier` ; tests via `ProviderScope(overrides: [...overrideWithValue(fake)])`.
- Auth : `AuthController` (`AuthUnknown` → `Authenticated` / `Unauthenticated`) ; la session (tokens + user) est un seul JSON dans flutter_secure_storage (`SessionStorage`). Au démarrage, une session stockée ouvre l'accueil même hors ligne.
- `AuthInterceptor` : bearer automatique, refresh unique partagé sur 401 puis rejeu de la requête ; refresh refusé ⇒ purge + `onSessionExpired()`. Les appels publics passent `extra: {skipAuthKey: true}`.
- Redirections : `appRedirect(auth, profileStatus, location)` pur dans `core/router/app_router.dart` ; sans profil ⇒ `/profile/setup` ; statut `unknown` (chargement, hors ligne) ⇒ jamais bloquant. Routes publiques dans `AppRoutes.publicRoutes`.
- Profil : `myProfileProvider` (AsyncNotifier, `null` = à créer, rechargé à chaque changement d'auth) ; photos téléchargées via dio authentifié (`profilePhotoProvider`, clé = URL versionnée) puis `MemoryImage`. Sélection d'image derrière `PhotoPicker` (fake en test).
- Erreurs API : `ApiException` (`guardApi`) avec message français générique ; chaque écran précise le message selon `kind`.
- Contacts : QR affiché par `qr_flutter` (modules charbon sur fond blanc, contraste maximal), scan par `mobile_scanner` derrière `qrScannerBuilderProvider` (remplacé en test par des boutons `scan:<payload>`), partage vCard via `CardSharer` (share_plus).
- Relations : `ConnectionActions` (`connectionActionsProvider`) fait chaque action puis invalide toutes les listes concernées ; `ConnectionButton` affiche l'action selon `MemberConnection` (nom choisi pour éviter le conflit avec `ConnectionState` de Flutter).
- Temps réel : `realtimeClientProvider` (Socket.IO sur `<hôte API>/ws`, jeton relu à chaque reconnexion, refresh via un appel HTTP si le serveur refuse le jeton) et `realtimeEventsProvider` (flux d'évènements). Toujours remplacé par `FakeRealtimeClient` en test.
- Messagerie : envoi HTTP, réception WebSocket ; `chatProvider(conversationId)` dédoublonne par id (réponse HTTP + évènement socket).
- Notifications : `notificationsProvider` (liste tenue à jour par `notification:new`), bandeau in-app global via `scaffoldMessengerKey` (app.dart). Push derrière `PushService` (`DisabledPushService` sauf `--dart-define=FCM_ENABLED=true`) ; `PushRegistration` ne doit pas dépendre de l'état d'auth (cycle Riverpod) : enregistrement déclenché par app.dart à la connexion, désenregistrement par `AuthController.logout()` avant la révocation.
- Firebase : `google-services.json` / `GoogleService-Info.plist` jamais commités ; le plugin Gradle google-services n'est appliqué que si le fichier existe.
- Accueil = tableau de bord (`dashboardProvider`) : rechargé sur évènements temps réel (anti-rebond 300 ms) et après chaque action de relation via `networkRevisionProvider` (ne pas `watch` les listes de relations depuis le tableau de bord : erreur Riverpod « markNeedsBuild during build »).
- Hors ligne : `OfflineInterceptor` (dio) mémorise les GET des écrans principaux par utilisateur (`ResponseCache`, fichier privé) et les rejoue en cas d'erreur réseau ; `offlineProvider` pilote le bandeau global (app.dart). Cache vidé par `AuthController` à la déconnexion. Pas de file d'attente d'envoi.
- Accessibilité : bulles de chat lues en une phrase (`Semantics(excludeSemantics)`), tests de grandes polices (`textScaleFactorTestValue = 2`) et des guidelines Flutter sur les écrans principaux.
- Android : `allowBackup=false` + `data_extraction_rules.xml` (jetons et cache jamais sauvegardés ni transférés).
- Tests de widgets : `pumpRisottoApp(tester, auth:, storage:, profiles:, photoPicker:, contacts:, cardSharer:, scannerPayloads:, connections:, messaging:, realtime:, notifications:, push:, dashboard:, responseCache:)`, `enterField`, `tapText` (font défiler la liste de la page, vers le bas uniquement : remplir les champs dans l'ordre de l'écran) dans `test/helpers/`.
- Faux HTTP pour tester les repositories : `test/helpers/fake_http_adapter.dart`.

## Jalons
- [x] 1. Fondations (structure, CI, configuration, thème Risotto)
- [x] 2. Authentification (écrans inscription, connexion, mot de passe oublié, refresh, déconnexion)
- [x] 3. Profil (création, édition, photo, visibilité)
- [x] 4. Contacts et partage (carte de contact, QR code personnel, scan)
- [x] 5. Mise en relation (recherche, demande, acceptation/refus, blocage)
- [x] 6. Messagerie (WebSocket, historique paginé, accusés de lecture)
- [x] 7. Notifications (temps réel, push FCM, préférences)
- [x] 8. Tableau de bord (demandes en attente, non lus, activité récente)
- [x] 9. Finalisation (sécurité, performances, accessibilité, hors ligne)
