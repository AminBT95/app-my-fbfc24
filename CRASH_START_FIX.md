# Fix crash au démarrage

Cause probable :
- Les dropdowns essayaient de charger beaucoup de joueurs ou une valeur absente de la liste.
- Flutter peut crasher au lancement avec l’assertion DropdownButton : value not found.

Corrections :
- PlayerPicker sécurisé.
- Recherche complète via popup au lieu de très grands dropdowns.
- DetectorScreen sécurisé.
- Erreur de chargement affichée à l’écran si asset/problème JSON.
- Parser Player compatible avec joueurs custom sauvegardés.
