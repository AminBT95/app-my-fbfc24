# V16.1 Build Fix

Correction du build APK release :
- Fix erreur Dart dans `TacticBoardStudio._setTargets()`.
- Les ternaires `?.02`, `?.06`, `?.08` ont été corrigés en vraie syntaxe Dart `? .02 : ...`.
- Aucun changement fonctionnel, seulement correction compilation.

Relancer :
```bash
flutter clean
flutter pub get
flutter build apk --release
```
