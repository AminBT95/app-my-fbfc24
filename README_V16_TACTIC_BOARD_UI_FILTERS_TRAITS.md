# FC24 Coach AI Flutter PRO v16

## Ajouts principaux

- Nouvelle rubrique **Tactic Board Animation Studio** dans le drawer.
- Contenu repris du HTML Tactic Board : presets 3v2, 4v3, 5v4, rondo, contre-attaque, sortie de balle, timeline, keyframes, groupes simultanés, outils passe/tir/dribble/appel/pressing/zone/duel.
- UI/UX retravaillée : thème plus football premium, moins rose, plus bleu/vert/navy, cards plus propres, terrain animé.
- IA Simulator : autocomplete équipe, filtrage homme par défaut, Female/Soccer Aid exclus par défaut pour éviter le mélange.
- Minifaces : amélioration du rendu avec `BoxFit.contain`, headers Referer/User-Agent et permission Internet dans le workflow.
- Traits/PlayStyles : nettoyage des valeurs numériques erronées, normalisation des noms, suppression des icontrait raw, inférence PlayStyles depuis stats quand les données n’existent pas.
- Workrates : lecture améliorée des champs `attWR/attWr` et `defWR/defWr`.

## Notes

Les vrais PlayStyles officiels dépendent de la donnée source. Cette version nettoie les erreurs visibles et infère les PlayStyles utiles à partir des stats quand la DB n’a pas la colonne officielle complète.
