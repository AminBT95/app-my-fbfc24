# V15 — UI / Minifaces / IA Simulator rework

Corrections appliquées :
- Thème UI plus doux et premium, proche des inspirations sport app : fond clair, cards blanches, accent violet/corail, moins de rose agressif.
- PlayerAvatar corrigé : fallback lisible + URL EEP automatique `https://eep-fifa.de/Minifaces/p{id}.png` + headers image.
- GitHub build : ajout automatique de la permission Android INTERNET dans le Manifest après `flutter create` pour permettre le chargement réseau des minifaces en APK release.
- IA Simulator Pro retravaillé : terrain tactique avec flèches/zones, sélection scénario, guide complet, déclencheur/action/risque, duel moteur et remplaçants.
- Scénarios IA ajoutés depuis l’HTML/plugin : jockey, deuxième ballon, overlap latéral, ailier inversé, en plus du pressing, cutback, bloc bas, transitions, pivot, contrôle orienté.
- Soccer Aid / Female masqués par défaut dans IA Simulator team selector.
- Player detail : header visuel amélioré + miniface lisible + stats catégorisées conservées.

Note : si certaines minifaces restent blanches, c’est que l’image n’existe pas sur EEP pour cet ID ou que le serveur bloque temporairement la requête. Le fallback affiche maintenant les initiales/ID au lieu d’un cercle vide.
