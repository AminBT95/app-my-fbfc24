# V51.1 Build Fix

Correction build APK GitHub Actions.

## Fix principal
- Ajout de `shared_preferences` dans `pubspec.yaml` car `lib/main.dart` l'utilise pour la persistance locale.
- Version bump `1.0.51+51`.
- Nom artifact GitHub Actions mis à jour.
- Vérification que Pillow est installé avant génération icône.

Relancer : `flutter build apk --release` ou GitHub Actions.
