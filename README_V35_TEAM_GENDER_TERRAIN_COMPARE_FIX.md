# V35 - Team Gender + Terrain Compare Fix

Corrections principales :
- Ajout `gender` dans Player et filtrage strict des joueuses quand `Afficher Female` est OFF.
- Ajout `teamId` dans Player pour éviter le mélange PSG/PSG féminin et autres clubs qui partagent le même nom.
- Team autocomplete affiche l'ID quand deux équipes ont le même nom.
- Team vs Team utilise maintenant les équipes qui ont des joueurs visibles correspondant au `teamId`.
- Team squad priorise les joueurs par `teamId`, puis fallback par nom uniquement si pas d'ID.
- Ajout d'une section `Comparer depuis le terrain` : choisir joueur équipe 1 vs joueur équipe 2, puis mode auto ou manuel.
- Modal duel enrichie avec comparaisons offensives vs défensives : dribble vs tacle, agilité vs jockey, sprint vs profondeur, centre/cutback vs interception, finition vs bloc, physique, aérien.
