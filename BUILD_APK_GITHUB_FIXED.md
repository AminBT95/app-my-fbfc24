# Build APK corrigé via GitHub Actions

Ce ZIP corrige l’erreur :

`Your app is using an unsupported Gradle project`

## Pourquoi ça marche maintenant ?

Le workflow ne dépend plus du dossier `android/` dans le ZIP.

À chaque build GitHub, il fait :

1. `flutter create --platforms=android`
2. Copie ton dossier `lib/`
3. Copie `assets/`
4. Copie `pubspec.yaml`
5. Lance `flutter build apk --release`

Donc même si le ZIP ne contient pas `android/`, GitHub génère un projet Android propre automatiquement.

## Étapes

1. Crée un repository GitHub.
2. Upload tout le contenu de ce ZIP.
3. Va dans **Actions**.
4. Lance **Build Flutter APK**.
5. Télécharge l’artifact **fc24-coach-ai-release-apk**.
6. APK : `app-release.apk`.

## Important

Ne mets pas le ZIP directement dans GitHub. Il faut dézipper puis uploader les fichiers.
