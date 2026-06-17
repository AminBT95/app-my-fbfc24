import '../models/player.dart';
import '../models/duel.dart';

class AdvancedMode {
  final String key;
  final String label;
  final String duelKey;
  final List<String> focus;
  final String advice;
  const AdvancedMode(this.key, this.label, this.duelKey, this.focus, this.advice);
}

class MatchupMode {
  final String key;
  final String label;
  final String duelKey;
  final List<String> focus;
  final String advice;
  const MatchupMode(this.key, this.label, this.duelKey, this.focus, this.advice);
}

class StatDiff {
  final String key;
  final String label;
  final int a;
  final int b;
  int get diff => a - b;
  const StatDiff(this.key, this.label, this.a, this.b);
}

class ProfileBonus {
  final String label;
  final int value;
  final String why;
  const ProfileBonus(this.label, this.value, this.why);
}

class DuelEngine {
  static const statLabels = <String, String>{
    'pac':'Pace','sho':'Shooting','pas':'Passing','dri':'Dribbling','def':'Defending','phy':'Physical',
    'acc':'Acceleration','sprint':'Sprint Speed','str':'Strength','agg':'Aggression','bal':'Balance','agi':'Agility','react':'Reactions',
    'ball':'Ball Control','drib':'Dribbling','defaw':'Def. Awareness','tackle':'Standing Tackle','inter':'Interceptions',
    'finish':'Finishing','shot':'Shot Power','comp':'Composure','stam':'Stamina','jump':'Jumping','head':'Heading',
    'cross':'Crossing','shortp':'Short Passing','longp':'Long Passing','vision':'Vision',
    'gkdiv':'GK Diving','gkhan':'GK Handling','gkkick':'GK Kicking','gkpos':'GK Positioning','gkref':'GK Reflexes',
  };

  static final modes = <String, DuelMode>{
    'physical': DuelMode('physical','Duel physique / épaule','physical', {'str':.34,'agg':.18,'bal':.15,'sprint':.10,'react':.10,'stam':.08,'jump':.05}, 'Force, poids, taille, agressivité et Bruiser+.'),
    'speed_short': DuelMode('speed_short','Vitesse courte 0-10m','speed_short', {'acc':.42,'sprint':.20,'agi':.14,'react':.12,'bal':.07,'stam':.05}, 'Explosive et Quick Step+ dominent.'),
    'speed_long': DuelMode('speed_long','Course longue 25m+','speed_long', {'sprint':.42,'acc':.22,'stam':.14,'str':.08,'react':.08,'agi':.06}, 'Lengthy et Rapid+ dominent.'),
    'dribble': DuelMode('dribble','Dribble 1v1','dribble', {'agi':.24,'drib':.22,'acc':.18,'bal':.14,'ball':.12,'react':.10}, 'Agility, balance, Technical+, body type Lean/Unique.'),
    'dribble_wing': DuelMode('dribble_wing','Ailier vs latéral','dribble', {'acc':.22,'agi':.20,'drib':.20,'ball':.14,'cross':.10,'bal':.08,'sprint':.06}, 'Couloir : explosivité, dribble, centre, Jockey/Anticipate en face.'),
    'dribble_central': DuelMode('dribble_central','Dribble axe / petit espace','dribble', {'agi':.25,'bal':.22,'drib':.20,'ball':.15,'acc':.10,'comp':.08}, 'Axe : petits appuis, balance, contrôle orienté, Technical+.'),
    'defense': DuelMode('defense','Tacle / récupération','defense', {'tackle':.28,'defaw':.24,'inter':.16,'react':.12,'str':.10,'agg':.10}, 'Anticipate+, awareness, tackle.'),
    'interception': DuelMode('interception','Passe vs interception','defense', {'inter':.32,'defaw':.24,'react':.16,'acc':.10,'vision':.08,'stam':.06,'shortp':.04}, 'Interceptions et lecture des lignes.'),
    'pressing': DuelMode('pressing','Pressing / contre-pressing','press', {'stam':.22,'agg':.20,'acc':.18,'react':.14,'defaw':.10,'str':.08,'agi':.08}, 'Relentless+, agressivité, accélération.'),
    'aerial': DuelMode('aerial','Duel aérien / centre','aerial', {'head':.28,'jump':.24,'str':.18,'react':.10,'agg':.08,'defaw':.06,'finish':.06}, 'Taille, jumping, heading, Aerial+.'),
    'finish': DuelMode('finish','Finition sous pression','finish', {'finish':.28,'comp':.22,'shot':.18,'react':.12,'ball':.08,'str':.06,'bal':.06}, 'Composure, finishing, Finesse+/Power Shot+.'),
    'keeper_1v1': DuelMode('keeper_1v1','ST vs GK / face-à-face','finish_gk', {'finish':.24,'comp':.18,'shot':.14,'react':.10,'acc':.08,'gkref':.12,'gkpos':.10,'gkdiv':.04}, 'Face-à-face : finition/calme contre réflexes/placement gardien.'),
    'shield': DuelMode('shield','Pivot dos au but','shield', {'str':.26,'bal':.22,'ball':.18,'comp':.12,'react':.10,'agg':.07,'drib':.05}, 'Press Proven+, strength, balance.'),
    'pass_break': DuelMode('pass_break','Casser ligne par passe','pass', {'vision':.26,'shortp':.22,'longp':.20,'comp':.12,'react':.08,'ball':.08,'drib':.04}, 'Incisive Pass+, vision, composure.'),
    'crossing': DuelMode('crossing','Centre / cutback','pass', {'cross':.30,'vision':.16,'acc':.12,'drib':.12,'ball':.10,'stam':.08,'shortp':.07,'comp':.05}, 'Whipped Pass+, crossing, dribble.'),
    'long_shot': DuelMode('long_shot','Frappe de loin sous pression','finish', {'shot':.30,'comp':.18,'finish':.12,'ball':.12,'react':.10,'vision':.08,'str':.06,'bal':.04}, 'Shot Power, composure, Finesse+/Power Shot+ contre Block+.'),
  };

  static final advancedModes = <String, AdvancedMode>{
    'none': AdvancedMode('none','Mode avancé désactivé','physical',[], 'Choisis un mode avancé.'),
    'press_high': AdvancedMode('press_high','Pressing haut / récupération rapide','pressing',['Stamina','Aggression','Acceleration','Reactions','Intercept+','Relentless+'], 'Teste qui gagne quand tu presses fort juste après perte du ballon.'),
    'pass_vs_intercept': AdvancedMode('pass_vs_intercept','Passe qui casse ligne vs interception','interception',['Vision','Short Passing','Long Passing','Interceptions','Def. Awareness'], 'Très utile CAM/CM contre CDM/CB dans bloc bas.'),
    'build_up': AdvancedMode('build_up','Sortie de balle sous pression','pass_break',['Ball Control','Short Passing','Composure','Press Proven+'], 'Qui garde le ballon propre quand l’adversaire vient presser.'),
    'cutback': AdvancedMode('cutback','Cutback / centre en retrait','crossing',['Crossing','Vision','Short Passing','Acceleration','Whipped Pass+'], 'Pour ailier/latéral qui arrive dans la surface et cherche la passe en retrait.'),
    'counter': AdvancedMode('counter','Contre-attaque profondeur','speed_long',['Sprint Speed','Acceleration','Stamina','Rapid+','Lengthy'], 'Mesure la course longue dans le dos.'),
    'hold_up': AdvancedMode('hold_up','Pivot / dos au but','shield',['Strength','Balance','Ball Control','Composure','Press Proven+'], 'Pour ST/CF qui protège puis remise.'),
    'first_touch': AdvancedMode('first_touch','Contrôle orienté + demi-tour','dribble_central',['First Touch+','Ball Control','Agility','Balance'], 'Pour recevoir entre les lignes et se retourner.'),
    'jockey': AdvancedMode('jockey','Jockey défensif / contenir','defense',['Def. Awareness','Agility','Balance','Standing Tackle','Jockey+'], 'Pour latéral ou CB qui doit contenir sans sortir de la ligne.'),
    'second_ball': AdvancedMode('second_ball','Deuxième ballon / duel milieu','pressing',['Reactions','Aggression','Stamina','Interceptions','Strength'], 'Après dégagement, duel aérien ou ballon repoussé.'),
    'inside_forward': AdvancedMode('inside_forward','Ailier inversé intérieur','dribble_central',['Dribbling','Agility','Balance','Finishing','Finesse+'], 'Ailier qui rentre entre latéral et CB.'),
    'long_shot': AdvancedMode('long_shot','Frappe de loin sous pression','long_shot',['Shot Power','Composure','Ball Control','Block+'], 'Qui peut tirer avant que le défenseur ferme l’angle.'),
  };

  static final matchups = <String, MatchupMode>{
    'auto': MatchupMode('auto','Auto-détection poste vs poste','physical',[], 'L’app choisit automatiquement le duel selon les postes.'),
    'st_cb': MatchupMode('st_cb','ST vs CB — appel profondeur','speed_long',['Sprint Speed','Acceleration','Strength','Finishing','Def. Awareness'], 'Le ST cherche l’espace entre CB et latéral. Le CB gagne par placement, anticipation et force.'),
    'st_gk': MatchupMode('st_gk','ST vs GK — 1 contre 1','keeper_1v1',['Finishing','Composure','Shot Power','GK Reflexes','GK Positioning'], 'Face-à-face : finition + calme contre réflexes + placement.'),
    'rw_lb': MatchupMode('rw_lb','RW vs LB — couloir','dribble_wing',['Acceleration','Agility','Dribbling','Crossing','Jockey'], 'Ailier : crochet/centre. Latéral : contenir, fermer pied fort.'),
    'lw_rb': MatchupMode('lw_rb','LW vs RB — couloir','dribble_wing',['Acceleration','Agility','Dribbling','Crossing','Jockey'], 'Même logique : attention au crochet intérieur et cutback.'),
    'wing_cb': MatchupMode('wing_cb','Ailier vs CB — intérieur','dribble_central',['Agility','Balance','Dribbling','Strength','Def. Awareness'], 'Si le CB est lourd, attaque petits espaces. Si Lengthy rapide, évite la longue course.'),
    'cam_cdm': MatchupMode('cam_cdm','CAM vs CDM — entre les lignes','pass_break',['Vision','Short Passing','Ball Control','Interceptions','Aggression'], 'Le CAM casse la ligne vite. Le CDM ferme l’angle et intercepte.'),
    'cm_cm': MatchupMode('cm_cm','CM vs CM — tempo milieu','pressing',['Stamina','Aggression','Short Passing','Reactions'], 'Duel de tempo, pressing, orientation du corps et récupération.'),
    'box_header': MatchupMode('box_header','Centre surface / tête','aerial',['Heading','Jumping','Strength','Height','Aerial+'], 'Taille + jump + heading décident souvent l’animation.'),
  };

  static DuelMode mode(String key) => modes[key] ?? modes['physical']!;

  static DuelResult compare(Player a, Player b, String modeKey) {
    final m = mode(modeKey);
    final ca = _core(a, m), cb = _core(b, m);
    final ba = _bonus(a, m.profile), bb = _bonus(b, m.profile);
    final sa = (ca + ba).round(), sb = (cb + bb).round();
    final total = (sa + sb).clamp(1, 9999);
    return DuelResult(
      scoreA: sa, scoreB: sb, coreA: ca.round(), coreB: cb.round(), bonusA: ba.round(), bonusB: bb.round(),
      percentA: sa / total, winner: sa >= sb ? a.name : b.name,
      reasons: _reasons(a, b, m),
    );
  }

  static double _core(Player p, DuelMode m) => m.weights.entries.fold(0, (sum, e) => sum + (p.s[e.key] ?? 0) * e.value);

  static double _bonus(Player p, String profile) => profileBonuses(p, profile).fold(0.0, (s,b)=>s+b.value);

  static List<ProfileBonus> profileBonuses(Player p, String profile) {
    final rows = <ProfileBonus>[];
    void add(String label, int value, String why){ if(value != 0) rows.add(ProfileBonus(label, value, why)); }
    final body = p.bodyType.toLowerCase();
    final accel = p.accelerate.toLowerCase();
    final plays = p.playStyles.join(' ').toLowerCase();
    if (['physical','shield'].contains(profile)) { add('Poids', p.weight>=85?7:p.weight>=78?4:0, 'plus stable au contact'); add('Taille', p.height>=188?5:p.height>=183?3:0, 'meilleure portée/corps'); add('Body Type', (body.contains('stocky')||body.contains('unique'))?6:body.contains('high')?4:0, 'animations contact/protection'); add('Bruiser+', plays.contains('bruiser')?8:0, 'impact duel physique'); add('Press Proven+', plays.contains('press proven')?5:0, 'protection sous pression'); }
    if (profile=='speed_short') { add('AcceleRATE', accel.contains('explosive')?8:0, 'départ court'); add('Body Lean', body.contains('lean')?5:0, 'petits appuis'); add('Quick Step+', plays.contains('quick step')?10:0, 'boost accélération'); add('Poids lourd', p.weight>88?-3:0, 'moins vif'); }
    if (profile=='speed_long') { add('Lengthy', accel.contains('lengthy')?8:0, 'course longue'); add('Rapid+', plays.contains('rapid')?9:0, 'vitesse en conduite'); add('Taille', p.height>=185?3:0, 'grande foulée'); }
    if (profile=='dribble') { add('Body Lean', body.contains('lean')?8:0, 'agilité'); add('Unique', body.contains('unique')?6:0, 'animations spéciales'); add('Explosive', accel.contains('explosive')?5:0, 'crochet départ'); add('Technical+', plays.contains('technical')?9:0, 'dribble collé'); add('Trickster+', plays.contains('trickster')?7:0, 'gestes et sorties'); add('First Touch+', plays.contains('first touch')?5:0, 'contrôle orienté'); }
    if (profile=='defense') { add('Anticipate+', plays.contains('anticipate')?9:0, 'meilleures interceptions/tacles debout'); add('Block+', plays.contains('block')?7:0, 'ferme les tirs'); add('Jockey+', plays.contains('jockey')?6:0, 'contenu défensif'); add('Taille', p.height>=185?3:0, 'présence défensive'); }
    if (profile=='press') { add('Relentless+', plays.contains('relentless')?9:0, 'répète les courses'); add('Intercept+', plays.contains('intercept')?7:0, 'coupe les lignes'); add('Stamina 88+', (p.s['stam']??0)>=88?5:0, 'pression durable'); }
    if (profile=='aerial') { add('Taille', p.height>=190?8:p.height>=185?5:0, 'dominance aérienne'); add('Aerial+', plays.contains('aerial')?10:0, 'duels aériens'); add('Power Header+', plays.contains('power header')?9:0, 'têtes dangereuses'); }
    if (profile=='finish' || profile=='finish_gk') { add('Finesse+', plays.contains('finesse')?8:0, 'frappe enroulée'); add('Power Shot+', plays.contains('power shot')?8:0, 'frappe puissante'); add('Unique', body.contains('unique')?4:0, 'animations finition'); }
    if (profile=='pass') { add('Incisive Pass+', plays.contains('incisive')?9:0, 'passe cassant les lignes'); add('Long Ball Pass+', plays.contains('long ball')?8:0, 'renversement/profondeur'); add('Whipped Pass+', plays.contains('whipped')?6:0, 'centres tendus'); add('Tiki Taka+', plays.contains('tiki')?7:0, 'passes rapides'); }
    return rows;
  }

  static List<String> _reasons(Player a, Player b, DuelMode m) {
    final keys = m.weights.keys.toList();
    keys.sort((x,y)=>(((a.s[y]??0)-(b.s[y]??0)).abs()).compareTo(((a.s[x]??0)-(b.s[x]??0)).abs()));
    return keys.take(5).map((k)=>'${statLabels[k] ?? k}: ${a.s[k]??0} vs ${b.s[k]??0}').toList();
  }

  static List<StatDiff> statDiffs(Player a, Player b, String modeKey) {
    final m = mode(modeKey);
    final keys = <String>{...m.weights.keys,'pac','sho','pas','dri','def','phy','str','acc','sprint','bal','agi','react','stam','comp'};
    final list = keys.map((k)=>StatDiff(k, statLabels[k] ?? k, a.s[k] ?? 0, b.s[k] ?? 0)).toList();
    list.sort((x,y)=>y.diff.abs().compareTo(x.diff.abs()));
    return list;
  }

  static String tacticalDiagnosis(Player a, Player b, DuelResult r, String modeKey) {
    final m = mode(modeKey);
    final winner = r.scoreA >= r.scoreB ? a : b;
    final loser = r.scoreA >= r.scoreB ? b : a;
    final gap = (r.scoreA - r.scoreB).abs();
    final intensity = gap < 5 ? 'très serré' : gap < 12 ? 'avantage clair' : 'gros avantage';
    return '${m.label} : duel $intensity. Avantage ${winner.name}. Avec ${winner.name}, cherche cette situation plus souvent. Contre lui, évite le duel direct avec ${loser.name} : force-le vers son pied faible, double-le ou change le type de duel.';
  }

  static String autoModeForPositions(Player a, Player b) {
    final ap = a.pos.toUpperCase(), bp = b.pos.toUpperCase();
    if (ap.contains('ST') && bp.contains('GK')) return 'keeper_1v1';
    if (ap.contains('ST') && bp.contains('CB')) return 'speed_long';
    if ((ap.contains('RW') || ap.contains('LW')) && (bp.contains('LB') || bp.contains('RB'))) return 'dribble_wing';
    if ((ap.contains('RW') || ap.contains('LW')) && bp.contains('CB')) return 'dribble_central';
    if (ap.contains('CAM') && (bp.contains('CDM') || bp.contains('CM'))) return 'pass_break';
    if (ap.contains('CM') && bp.contains('CM')) return 'pressing';
    if (bp.contains('GK')) return 'finish';
    return 'physical';
  }
}
