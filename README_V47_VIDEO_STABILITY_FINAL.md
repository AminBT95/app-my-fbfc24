# FC24 Coach AI Pro v47 — Video Stability & Missing UX Fix

Corrections basées sur la vidéo utilisateur et l'audit des manques restants :

## Player Detail / Player Hub
- Refonte du scroll Player Detail : onglets dans un bottom sheet stable, sans gros scroll parent + TabBar imbriquée instable.
- Lazy loading conservé pour éviter de calculer tous les onglets dès l'ouverture.
- PlayStyles réels + PlayStyles déduits affichés dans l'onglet PlayStyles.
- Traits DB séparés des PlayStyles : tout trait décodé non reconnu comme PlayStyle FC24 apparaît dans l'onglet Traits.
- Support plus large des champs import : playstyles, playStyles, playstylePlus, traits, trait1Decoded, trait2Decoded, specialities, etc.
- Similar / Counters / Duels restent accessibles par onglet avec modals au clic.

## Favoris / Compare
- Favoris corrigés avec clé stable : id + teamId + team + name + pos pour éviter les collisions de joueurs ID 0.
- Correction du bug qui pouvait empêcher le bouton Actions de compiler correctement.
- Boutons Edit CRUD / Comparer / Favori conservés dans le hub joueur.

## Team / Team vs Team / Traits
- Traits équipe en onglets : forts, faibles, égaux, lecture coach.
- Team vs Team garde l'onglet traits fort/faible/égal et les détails au clic.

## VIP / UX
- Stabilisation de la version VIP : accès rapide, heatmaps, rapports, historique/favoris, workflow coach.
- Objectif v47 : corriger les bugs critiques avant d'ajouter de nouvelles couches.
