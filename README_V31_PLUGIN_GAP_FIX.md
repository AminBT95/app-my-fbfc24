# FC24 Coach AI Pro — v31 Plugin Gap Fix

Cette version applique les demandes des 3 screens + audit plugin WordPress v1839/v1834.

## 1) Player picker / choix joueur
- Recherche visible par défaut uniquement.
- Filtres cachés dans un panneau repliable `Filtres (x actifs)`.
- Passage en bottom sheet large et responsive au lieu d'un petit dialog serré.
- Nouveaux filtres ajoutés : équipe, poste, pied, AcceleRATE, body type, PlayStyle/Trait, Work Rate, OVR, taille, poids, PAC, DRI, PHY, DEF, vrais noms, Female, Soccer Aid.
- Bouton reset filtres.

## 2) Comparateur Pro+
- Sections lourdes repliées par défaut : réglages matchup, joueurs, détail duel, stats complètes, tous les modes.
- Ajout d'une matrice spéciale `Attaque vs défenseur` : dribble vs tacle, agilité vs placement, contrôle vs interceptions, accélération vs réaction, centre vs défense, finition vs bloc.
- Le mode poste vs poste reste auto-détecté et les modes adaptés sont disponibles sans forcer un long scroll.

## 3) Team vs Team Coach AI Pro
- Ajout terrain tactique dans Team vs Team.
- Ajout zones coach : attaquer côté faible, presser relance, risque contre.
- Ajout duels proches joueur vs joueur avec ouverture du rapport duel détaillé.
- Ajout chips de plan tactique : cible faible, danger adverse, plan selon scénario.
- Conservation des cartes déjà présentes : phases, plan coach, weak links, XI comparés.

## Notes
Le plugin WordPress contient encore beaucoup de modules très avancés côté admin/widgets. Cette v31 rapproche l'app mobile sur les points demandés : UX filtre, scroll comparateur, poste vs poste attack/defense, terrain Team vs Team, weak links, pressing et plans tactiques.
