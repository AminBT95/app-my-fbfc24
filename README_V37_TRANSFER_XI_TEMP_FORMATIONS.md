# FC24 Coach AI Pro v37 — Transfer + XI + Formations provisoires

## Ajouté
- Nouvelle rubrique **Transfert joueur** dans le drawer.
- Changement d’équipe d’un joueur avec mise à jour `team` + `teamId`.
- Sécurité XI : le joueur transféré est retiré du XI de son ancienne équipe s’il était titulaire.
- Option pour ajouter le joueur transféré directement au XI de la nouvelle équipe.
- Si le XI dépasse 11 joueurs, l’app sort automatiquement le joueur le moins fort du même groupe/poste.
- Nouvelle rubrique **Gérer XI départ**.
- Gestion des 11 titulaires par équipe avec remplaçants/réserve.
- Team vs Team : choix d’une formation provisoire pour chaque équipe.
- Sauvegarde/rechargement des formations provisoires par équipe.
- Comparaison terrain basée sur la formation provisoire sans modifier la DB.

## Notes
- Le changement de formation provisoire dans Team vs Team ne touche pas la DB équipe.
- Le XI départ sauvegardé, lui, devient la base utilisée pour les comparaisons terrain.
