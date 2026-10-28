# Risotto – kit de marque (logo n°3 « La rencontre »)

Couleurs : Safran #E8A317 · Basilic #2F6B4F · Charbon #1F2421 (intersection) · Crème #FFF6E0 (fond)

## Contenu
- `svg/` : sources vectorielles (logo, icône d'app, favicon, calques Android).
- `png/`, `ios/`, `android/`, `web/` : exports prêts à l'emploi.
- `loader/risotto-loader.svg` : loader animé (web). `loader/risotto_loader.dart` : widget Flutter.

## Flutter (icône d'app) – pubspec.yaml du front
dev_dependencies:
  flutter_launcher_icons: ^0.14.0

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/brand/app-icon-1024.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#FFF6E0"
  adaptive_icon_foreground: "assets/brand/android-foreground-432.png"
  adaptive_icon_monochrome: "assets/brand/android-monochrome-432.png"

Puis : dart run flutter_launcher_icons

## Écran de démarrage
Utiliser `png/splash-logo-512.png` sur fond #FFF6E0 (package flutter_native_splash).

## Web
Placer web/favicon.ico, favicon.svg, favicon-16/32.png, apple-touch-icon-180.png, icon-192/512.png dans `web/`, puis dans index.html :
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="icon" href="favicon.ico" sizes="48x48">
<link rel="apple-touch-icon" href="apple-touch-icon-180.png">
