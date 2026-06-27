# V52 — Team Autocomplete + ID Fix

Objectif: éviter les conflits entre équipes homme/femme qui partagent le même nom.

Ajouts:
- Autocomplete équipe global réutilisable.
- Affichage systématique: `Nom équipe • ID xxx • H/F`.
- Résolution sélection par `teamId` avant le nom.
- Nouvelle équipe dans Transfert joueur passée en autocomplete.
- Sélections Team vs Team / XI / Tactical Lab utilisent l'ID quand disponible.
- Fallback par nom uniquement si aucun ID n'est trouvé.

Notes:
- Les équipes femmes restent séparées si présentes, mais l'app privilégie les équipes hommes par défaut via `gender == 0`.
- En cas de doublon PSG homme/femme, l'ID affiché permet de sélectionner la bonne équipe.
