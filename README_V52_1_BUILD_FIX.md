# V52.1 Build Fix

Fix compilation v52:
- Ajout du champ `gender` dans `TeamInfo`.
- `TeamAutocomplete` peut afficher H/F sans casser le build.
- Version bump `1.0.53+53`.

Note: si les données teams ne contiennent pas `gender`, l'app met H par défaut et continue d'utiliser `teamId` pour éviter les conflits PSG homme/femme.
