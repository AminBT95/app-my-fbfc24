# Build APK via GitHub Actions

## Étapes

1. Crée un nouveau repository GitHub.
2. Upload tous les fichiers de ce dossier dans le repository.
3. Va dans l’onglet **Actions**.
4. Clique sur **Build Flutter APK**.
5. Clique sur **Run workflow**.
6. Quand le build est terminé, ouvre le run.
7. Télécharge l’artifact **fc24-coach-ai-release-apk**.
8. Dedans tu trouveras : `app-release.apk`.

## Important

- Le workflow utilise Flutter stable `3.24.5`.
- Le fichier APK généré est en release.
- Si GitHub affiche une erreur Gradle/SDK, relance le workflow une deuxième fois.
