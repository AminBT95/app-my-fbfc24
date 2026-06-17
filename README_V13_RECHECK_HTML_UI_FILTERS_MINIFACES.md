# FC24 Coach AI Flutter PRO v13

Corrections ajoutées après recheck de `FC24_Coach_AI_Modes_Avances(1).html` :

## Comparateur
- Ajout de tous les modes clés manquants inspirés de l'HTML :
  - épaule contre épaule
  - shield / dos au but
  - dribble aile
  - dribble axe / petits espaces
  - appel profondeur vs CB
  - tacle debout
  - interception passe au sol
  - cutback défense
  - crossing / cutback offensif
  - finition pression
  - frappe de loin
  - ST vs GK 1v1
  - GK shot stop
  - GK sweeper
- Ajout d'une carte `Situation tactique` avec les poids de calcul visibles.
- Ajout d'un hero `VS` plus premium avec minifaces, pourcentage et score.

## UI
- Nouvelle carte comparateur inspirée des maquettes mobile football : hero bleu, joueurs face-à-face, scores et progression.
- PlayerTile modernisé avec avatar, badges rapides et score rond OVR.
- Détail joueur enrichi avec profil coach, top stats, WR, SM/WF, POT, miniface auto.

## Filtres joueurs
- Recherche riche dans le picker + base joueurs :
  - équipe
  - poste
  - pied
  - AcceleRATE
  - body type
  - PlayStyle / trait
  - OVR range
  - minimum PAC/SHO/PAS/DRI/DEF/PHY dans la base joueurs
  - minimum PAC/PHY dans le picker
  - cacher Female & Soccer Aid par défaut avec option pour afficher.

## Minifaces
- `PlayerAvatar` génère automatiquement une miniface EEP quand `image` est vide :
  `https://eep-fifa.de/Minifaces/p{playerid}.png`
- Donc les minifaces sont utilisées partout où `PlayerAvatar` est utilisé : listes, détails, comparateur, équipes.

## Note
Les PlayStyles/traits restent limités par la qualité du JSON source. L'app affiche les traits disponibles + l'outil de détection heuristique existant.
