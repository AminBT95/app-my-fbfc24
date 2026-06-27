# FC24 Coach AI Pro v50 — Exports Reports Final

## Ajouts principaux

- Export PDF réel via `pdf` + `printing`.
- Export GIF réel du Tactical Lab via génération image par image.
- Export vidéo storyboard : GIF animé + JSON de timeline importable.
- Heatmaps plus précises basées sur positions, poste et OVR.
- Reports Studio avec rapports sauvegardés/importables.
- Import/export JSON des rapports.
- Backup DB complet incluant players, teams, ideas, history, favorites et reports.
- Boutons PDF/GIF ajoutés dans Tactical Lab Pro.

## Note vidéo

La génération MP4 native n'est pas incluse car elle nécessite FFmpeg ou un encodeur vidéo Android lourd. Cette version exporte un vrai GIF animé et un storyboard JSON importable pour garder le build plus stable.

## À tester

1. `flutter pub get`
2. `flutter build apk --release`
3. Ouvrir Reports PDF / Export.
4. Générer PDF joueur, PDF Team vs Team, PDF Tactical Lab.
5. Générer GIF Tactical Lab.
6. Exporter/importer rapports sauvegardés.
