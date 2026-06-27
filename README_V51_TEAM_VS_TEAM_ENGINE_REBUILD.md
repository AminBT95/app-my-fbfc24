# V51 — Team vs Team Engine Rebuild

Objectif : corriger définitivement le terrain Team vs Team qui empilait les joueurs et restaurer une logique de comparaison utile.

## Ajouts / fixes

- Nouveau moteur terrain Team vs Team V51.
- Placement des joueurs par ligne : GK / DEF / MID / ATT.
- Séparation claire Équipe A vs Équipe B sur le terrain.
- Lignes de duels dessinées entre joueurs réellement proches.
- Comparaison disponible par :
  - joueur en face,
  - joueur le plus proche,
  - même rôle / même poste,
  - tous les duels.
- Remplaçants réintégrés sous le terrain pour les deux équipes.
- Clic sur joueur terrain = détail + comparaison rapide.
- Clic sur remplaçant = détail ou duel avec joueur sélectionné.
- Matrice des duels sous le terrain avec modal complet.
- Terrain plus haut, lisible, moins compressé.

## Pourquoi cette version

Les versions précédentes avaient ajouté beaucoup d’onglets et de rapports, mais le terrain Team vs Team était devenu moins fiable. Cette version reconstruit la logique terrain autour d’un moteur simple et stable : positions normalisées, lignes par rôle, adversaire en face/proche et banc séparé.
