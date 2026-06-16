import '../models/player.dart';
import '../models/duel.dart';

class DuelEngine {
  static final modes = <String, DuelMode>{
    'physical': DuelMode('physical','Duel physique / épaule','physical', {'str':.34,'agg':.18,'bal':.15,'sprint':.10,'react':.10,'stam':.08,'jump':.05}, 'Force, poids, taille, agressivité et Bruiser+.') ,
    'speed_short': DuelMode('speed_short','Vitesse courte 0-10m','speed_short', {'acc':.42,'sprint':.20,'agi':.14,'react':.12,'bal':.07,'stam':.05}, 'Explosive et Quick Step+ dominent.') ,
    'speed_long': DuelMode('speed_long','Course longue 25m+','speed_long', {'sprint':.42,'acc':.22,'stam':.14,'str':.08,'react':.08,'agi':.06}, 'Lengthy et Rapid+ dominent.') ,
    'dribble': DuelMode('dribble','Dribble 1v1','dribble', {'agi':.24,'drib':.22,'acc':.18,'bal':.14,'ball':.12,'react':.10}, 'Agility, balance, Technical+, body type Lean/Unique.') ,
    'defense': DuelMode('defense','Tacle / récupération','defense', {'tackle':.28,'defaw':.24,'inter':.16,'react':.12,'str':.10,'agg':.10}, 'Anticipate+, awareness, tackle.') ,
    'interception': DuelMode('interception','Passe vs interception','defense', {'inter':.32,'defaw':.24,'react':.16,'acc':.10,'vision':.08,'stam':.06,'shortp':.04}, 'Interceptions et lecture des lignes.') ,
    'pressing': DuelMode('pressing','Pressing / contre-pressing','press', {'stam':.22,'agg':.20,'acc':.18,'react':.14,'defaw':.10,'str':.08,'agi':.08}, 'Relentless+, agressivité, accélération.') ,
    'aerial': DuelMode('aerial','Duel aérien / centre','aerial', {'head':.28,'jump':.24,'str':.18,'react':.10,'agg':.08,'defaw':.06,'finish':.06}, 'Taille, jumping, heading, Aerial+.') ,
    'finish': DuelMode('finish','Finition sous pression','finish', {'finish':.28,'comp':.22,'shot':.18,'react':.12,'ball':.08,'str':.06,'bal':.06}, 'Composure, finishing, Finesse+/Power Shot+.') ,
    'shield': DuelMode('shield','Pivot dos au but','shield', {'str':.26,'bal':.22,'ball':.18,'comp':.12,'react':.10,'agg':.07,'drib':.05}, 'Press Proven+, strength, balance.') ,
    'pass_break': DuelMode('pass_break','Casser ligne par passe','pass', {'vision':.26,'shortp':.22,'longp':.20,'comp':.12,'react':.08,'ball':.08,'drib':.04}, 'Incisive Pass+, vision, composure.') ,
    'crossing': DuelMode('crossing','Centre / cutback','pass', {'cross':.30,'vision':.16,'acc':.12,'drib':.12,'ball':.10,'stam':.08,'shortp':.07,'comp':.05}, 'Whipped Pass+, crossing, dribble.') ,
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

  static double _bonus(Player p, String profile) {
    double b = 0;
    final body = p.bodyType.toLowerCase();
    final accel = p.accelerate.toLowerCase();
    final plays = p.playStyles.join(' ').toLowerCase();
    if (['physical','shield'].contains(profile)) { if (p.weight >= 85) b += 7; if (p.height >= 188) b += 5; if (body.contains('stocky') || body.contains('unique')) b += 6; if (plays.contains('bruiser')) b += 8; if (plays.contains('press proven')) b += 5; }
    if (profile == 'speed_short') { if (accel.contains('explosive')) b += 8; if (body.contains('lean')) b += 5; if (plays.contains('quick step')) b += 10; if (p.weight > 88) b -= 3; }
    if (profile == 'speed_long') { if (accel.contains('lengthy')) b += 8; if (plays.contains('rapid')) b += 9; if (p.height >= 185) b += 3; }
    if (profile == 'dribble') { if (body.contains('lean')) b += 8; if (body.contains('unique')) b += 6; if (accel.contains('explosive')) b += 5; if (plays.contains('technical')) b += 9; if (plays.contains('trickster')) b += 7; }
    if (profile == 'defense') { if (plays.contains('anticipate')) b += 9; if (plays.contains('block')) b += 7; if (p.height >= 185) b += 3; }
    if (profile == 'press') { if (plays.contains('relentless')) b += 9; if (plays.contains('intercept')) b += 7; if ((p.s['stam'] ?? 0) >= 88) b += 5; }
    if (profile == 'aerial') { if (p.height >= 190) b += 8; if (plays.contains('aerial')) b += 10; if (plays.contains('power header')) b += 9; }
    if (profile == 'finish') { if (plays.contains('finesse')) b += 8; if (plays.contains('power shot')) b += 8; if (body.contains('unique')) b += 4; }
    if (profile == 'pass') { if (plays.contains('incisive')) b += 9; if (plays.contains('long ball')) b += 8; if (plays.contains('whipped')) b += 6; if (plays.contains('tiki')) b += 7; }
    return b;
  }

  static List<String> _reasons(Player a, Player b, DuelMode m) {
    final keys = m.weights.keys.toList();
    keys.sort((x,y)=>(((a.s[y]??0)-(b.s[y]??0)).abs()).compareTo(((a.s[x]??0)-(b.s[x]??0)).abs()));
    return keys.take(4).map((k)=>'$k: ${a.s[k]??0} vs ${b.s[k]??0}').toList();
  }

  static String autoModeForPositions(Player a, Player b) {
    final ap = a.pos.toUpperCase(), bp = b.pos.toUpperCase();
    if (ap.contains('ST') && bp.contains('CB')) return 'speed_long';
    if ((ap.contains('RW') || ap.contains('LW')) && (bp.contains('LB') || bp.contains('RB') || bp.contains('CB'))) return 'dribble';
    if (ap.contains('CAM') && (bp.contains('CDM') || bp.contains('CM'))) return 'pass_break';
    if (ap.contains('CM') && bp.contains('CM')) return 'pressing';
    if (bp.contains('GK')) return 'finish';
    return 'physical';
  }
}
