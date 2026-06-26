# FC24 Coach AI Flutter PRO — V30 Master Edition

Cette version regroupe le travail V22 + une couche V30 orientée produit : UX simplifiée, comparateur multi-modes, poste vs poste, design system dark premium, modules coach et base tactique.

## Inclus dans V30

- Navigation simplifiée Home / Compare / Players / Teams / Coach.
- Drawer avancé pour modules pro : Team Analyzer, Team vs Team, Matchup Finder, Tactical Lab, Formation Builder, IA Simulator, Tactic Board Studio, Carnet entraîneur.
- Comparator Pro avec 60+ modes de comparaison.
- Comparateur poste vs poste : RB vs LW, LB vs RW, CB vs ST, ST vs GK, CAM vs CDM, etc.
- Résumé global des victoires joueur A / joueur B / égalités.
- Détail par mode via sheet cliquable.
- Stats complémentaires : attacking positioning, marking, recovery, workrate, GK stats.
- Team Analyzer et Team vs Team enrichis avec lecture coach.
- UI dark premium bleu/teal avec contrastes renforcés.
- Minifaces EEP via URL playerid.
- Workflow GitHub Actions corrigé avec Pillow + permission Internet.

## Important

V30 est une version fonctionnelle avancée. Certains modules très lourds comme export MP4/GIF, vrai moteur complet de simulation physique, historique cloud, calendriers avancés ou IA générative locale nécessiteraient une phase backend/native séparée.

## Build

```bash
flutter clean
flutter pub get
flutter build apk --release
```
