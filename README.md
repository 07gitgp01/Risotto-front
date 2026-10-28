# risotto-front

Application mobile Flutter (Android et iOS) de **Risotto**, réseautage professionnel. L'API est dans [`risotto-back`](https://github.com/07gitgp01/Risotto-back).

Conventions de travail et charte graphique : [CLAUDE.md](CLAUDE.md).

## Prérequis

- Flutter 3.38 (canal stable)
- Android Studio avec un émulateur Android, ou Xcode avec un simulateur iOS (macOS)
- L'API lancée en local (voir le README de `risotto-back`)

## Lancer l'application

```bash
flutter pub get
flutter run                                                         # émulateur Android : API sur http://10.0.2.2:3000/api
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api    # simulateur iOS (valeur par défaut sur iOS)
```

L'URL de l'API se passe uniquement par `--dart-define=API_BASE_URL=...`. Aucun secret n'est stocké dans l'application.

En debug, le HTTP en clair est autorisé uniquement vers `10.0.2.2`, `localhost` et `127.0.0.1` (Android : `android/app/src/debug/res/xml/network_security_config.xml` ; iOS : `NSAllowsLocalNetworking`). Un téléphone physique sur le réseau local ne peut donc pas joindre l'API en HTTP ; utiliser un émulateur ou un simulateur.

## Authentification

- Écrans : connexion, création de compte, mot de passe oublié (code à 6 chiffres reçu par email), nouveau mot de passe.
- Les tokens sont stockés uniquement dans le stockage sécurisé du système (Keystore Android, Keychain iOS) et effacés à la déconnexion.
- Le token d'accès (15 min) est renouvelé automatiquement ; si la session est révoquée côté serveur, l'application revient à l'écran de connexion.
- En local, les emails de réinitialisation arrivent dans Mailpit : http://localhost:8025.

## Notifications push (optionnel)

Sans configuration Firebase, l'app fonctionne normalement : notifications in-app en temps réel, push désactivé.

Pour activer le push :

1. Dans le projet Firebase (voir le README de `risotto-back`), télécharger `google-services.json` dans `android/app/` et `GoogleService-Info.plist` dans `ios/Runner/` (les deux sont ignorés par Git).
2. iOS : activer les capacités *Push Notifications* et *Background Modes > Remote notifications* dans Xcode, et déposer une clé APNs dans la console Firebase.
3. Lancer avec `flutter run --dart-define=FCM_ENABLED=true`.

## Hors ligne

- La session et le dernier état connu des écrans principaux (tableau de bord, profil, conversations et première page de chaque historique, contacts, relations, notifications) sont gardés sur l'appareil.
- Sans réseau, l'app les affiche avec un bandeau « Hors ligne » ; les actions (envoyer un message, accepter une demande…) affichent une erreur au lieu d'être mises en file d'attente.
- Ce cache est stocké dans le dossier privé de l'app, exclu des sauvegardes Android, et effacé à la déconnexion. Il contient des messages en clair : c'est l'appareil qui le protège (verrouillage de l'écran).

## Qualité

```bash
dart format lib test
flutter analyze
flutter test
```

La CI GitHub Actions lance le formatage, l'analyse et les tests, puis compile un APK Android et l'application iOS sans signature.

## Organisation du code

```
lib/
  core/        config, réseau (dio), thème Risotto, routeur (go_router)
  features/    une fonctionnalité par dossier : data / application / presentation
test/          tests unitaires et de widgets, même arborescence que lib/
```
