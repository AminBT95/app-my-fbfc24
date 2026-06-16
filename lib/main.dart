import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) => FlutterError.presentError(details);
  runZonedGuarded(() => runApp(const FC24CoachApp()), (error, stack) {
    debugPrint('FC24 Coach AI crash: $error');
  });
}

class FC24CoachApp extends StatelessWidget {
  const FC24CoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF06111F);
    const panel = Color(0xFF0B1728);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FC24 Coach AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E), brightness: Brightness.dark),
        cardTheme: CardTheme(
          color: panel,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFF263A55))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF09182A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF263A55))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF263A55))),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class Player {
  final String id, name, team, pos, pos2, body, accel, foot, attWr, defWr, image;
  final int ovr, pot, height, weight, skill, weakFoot;
  final List<String> playstyles;
  final Map<String, int> s;

  const Player({
    required this.id, required this.name, required this.team, required this.pos, required this.pos2,
    required this.image,
    required this.ovr, required this.pot, required this.height, required this.weight,
    required this.body, required this.accel, required this.foot, required this.attWr, required this.defWr,
    required this.skill, required this.weakFoot, required this.playstyles, required this.s,
  });

  static int n(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.round();
    final m = RegExp(r'-?\d+').firstMatch(v.toString());
    return m == null ? fallback : int.tryParse(m.group(0)!) ?? fallback;
  }

  static String str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final t = v.toString();
    return t == 'null' ? fallback : t;
  }

  static List<String> list(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v.map((e) => e.toString()).where((x) => x.trim().isNotEmpty && x != '0' && x != 'null').toSet().toList();
    }
    final t = v.toString();
    if (t.isEmpty || t == '0' || t == 'null') return [];
    return [t];
  }

  factory Player.fromJson(Map<String, dynamic> j) {
    final stats = <String, int>{
      'pac': n(j['PAC']), 'sho': n(j['SHO']), 'pas': n(j['PAS']), 'dri': n(j['DRI']), 'def': n(j['DEF']), 'phy': n(j['PHY']),
      'acc': n(j['acceleration']), 'sprint': n(j['sprintspeed']), 'str': n(j['strength']), 'agg': n(j['aggression']),
      'bal': n(j['balance']), 'agi': n(j['agility']), 'react': n(j['reactions']), 'ball': n(j['ballcontrol']), 'drib': n(j['dribbling']),
      'defaw': n(j['defaw']), 'tackle': n(j['standtackle']), 'slide': n(j['slidetackle']), 'inter': n(j['interceptions']),
      'finish': n(j['finishing']), 'shot': n(j['shotpower']), 'longshot': n(j['longshots']), 'comp': n(j['composure']), 'stam': n(j['stamina']),
      'jump': n(j['jumping']), 'head': n(j['heading']), 'cross': n(j['crossing']), 'shortp': n(j['shortpass']), 'longp': n(j['longpass']),
      'vision': n(j['vision']), 'curve': n(j['curve']), 'fk': n(j['fk']), 'posi': n(j['positioning']),
      'gkdiv': n(j['gkdiving']), 'gkhan': n(j['gkhandling']), 'gkkick': n(j['gkkicking']), 'gkpos': n(j['gkpositioning']), 'gkref': n(j['gkreflexes']),
    };
    final ps = <String>[
      ...list(j['playstyles']),
      ...list(j['trait1Decoded']),
      ...list(j['trait2Decoded']),
      ...list(j['icontrait1']),
      ...list(j['icontrait2']),
    ].where((x) => x.trim().isNotEmpty).toSet().toList();

    return Player(
      id: str(j['id']),
      name: str(j['name'], 'Player'),
      image: str(j['image']),
      team: str(j['team'], '—'),
      pos: str(j['pos'], 'N/A'),
      pos2: str(j['pos2']),
      ovr: n(j['ovr']),
      pot: n(j['pot']),
      height: n(j['height'], 180),
      weight: n(j['weight'], 75),
      body: decodeBody(str(j['bodytype'])),
      accel: guessAccel(stats, n(j['height'], 180), n(j['weight'], 75)),
      foot: str(j['foot']) == '2' ? 'Left' : 'Right',
      attWr: decodeWr(str(j['attWR'])),
      defWr: decodeWr(str(j['defWR'])),
      skill: n(j['skill']),
      weakFoot: n(j['weakfoot']),
      playstyles: ps,
      s: stats,
    );
  }

  static String decodeWr(String v) {
    if (v == '2') return 'High';
    if (v == '1') return 'Medium';
    if (v == '0') return 'Low';
    return v.isEmpty ? '—' : v;
  }

  static String decodeBody(String v) {
    const map = {
      '1': 'Lean', '2': 'Average', '3': 'Stocky', '4': 'High & Lean', '5': 'High & Average',
      '6': 'High & Stocky', '7': 'Unique', '8': 'Unique',
    };
    return map[v] ?? (v.isEmpty ? 'Average' : 'Body $v');
  }

  static String guessAccel(Map<String, int> s, int h, int w) {
    final acc = s['acc'] ?? 0, agi = s['agi'] ?? 0, str = s['str'] ?? 0;
    if (h >= 188 && str >= 75 && w >= 78) return 'Lengthy';
    if (acc >= 85 && agi >= 82 && h <= 183) return 'Explosive';
    if (acc >= 82 && agi >= 78) return 'Mostly Explosive';
    if (h >= 185 && str >= 72) return 'Controlled Lengthy';
    return 'Controlled';
  }
}




extension PlayerJsonExt on Player {
  Map<String, dynamic> toLocalJson() => {
    'id': id, 'name': name, 'team': team, 'pos': pos, 'pos2': pos2, 'image': image,
    'ovr': ovr, 'pot': pot, 'height': height, 'weight': weight, 'body': body, 'accel': accel,
    'foot': foot, 'attWr': attWr, 'defWr': defWr, 'skill': skill, 'weakFoot': weakFoot,
    'playstyles': playstyles, 'stats': s,
  };

  static Player fromLocalJson(Map<String, dynamic> j) {
    int n(dynamic v, [int f = 0]) => Player.n(v, f);
    String str(dynamic v, [String f = '']) => Player.str(v, f);
    final stats = <String, int>{};
    final rawStats = j['stats'];
    if (rawStats is Map) {
      rawStats.forEach((k, v) => stats[k.toString()] = n(v));
    }
    return Player(
      id: str(j['id'], 'local_${DateTime.now().millisecondsSinceEpoch}'),
      name: str(j['name'], 'Custom Player'),
      team: str(j['team'], 'Custom'),
      pos: str(j['pos'], 'ST'),
      pos2: str(j['pos2']),
      image: str(j['image']),
      ovr: n(j['ovr'], 80),
      pot: n(j['pot'], n(j['ovr'], 80)),
      height: n(j['height'], 180),
      weight: n(j['weight'], 75),
      body: str(j['body'], 'Average'),
      accel: str(j['accel'], 'Controlled'),
      foot: str(j['foot'], 'Right'),
      attWr: str(j['attWr'], 'Medium'),
      defWr: str(j['defWr'], 'Medium'),
      skill: n(j['skill'], 3),
      weakFoot: n(j['weakFoot'], 3),
      playstyles: Player.list(j['playstyles']),
      s: stats.isEmpty ? {'acc':75,'sprint':75,'str':75,'agg':70,'bal':75,'agi':75,'react':75,'ball':75,'drib':75,'defaw':60,'tackle':60,'inter':60,'finish':75,'shot':75,'comp':75,'stam':75,'jump':75,'head':70,'cross':70,'shortp':70,'longp':70,'vision':70} : stats,
    );
  }
}

extension TeamJsonExt on TeamInfo {
  Map<String, dynamic> toLocalJson() => {
    'id': id, 'name': name, 'manager': manager, 'overall': overall, 'attack': attack,
    'midfield': midfield, 'defense': defense, 'citylikeScore': citylikeScore,
    'weakTraits': weakTraits, 'equalTraits': equalTraits, 'strongTraits': strongTraits, 'xi': xi,
  };

  static TeamInfo fromLocalJson(Map<String, dynamic> j) => TeamInfo(
    id: Player.str(j['id'], 'local_team_${DateTime.now().millisecondsSinceEpoch}'),
    name: Player.str(j['name'], 'Custom Team'),
    manager: Player.str(j['manager'], '—'),
    overall: Player.n(j['overall'], 80),
    attack: Player.n(j['attack'], 80),
    midfield: Player.n(j['midfield'], 80),
    defense: Player.n(j['defense'], 80),
    citylikeScore: Player.n(j['citylikeScore']),
    weakTraits: Player.list(j['weakTraits']),
    equalTraits: Player.list(j['equalTraits']),
    strongTraits: Player.list(j['strongTraits']),
    xi: Player.list(j['xi']),
  );
}

class TacticalIdea {
  final String id, name, mode, description, json;
  const TacticalIdea({required this.id, required this.name, required this.mode, required this.description, required this.json});
  Map<String, dynamic> toJson() => {'id':id,'name':name,'mode':mode,'description':description,'json':json};
  static TacticalIdea fromJson(Map<String, dynamic> j) => TacticalIdea(
    id: Player.str(j['id'], 'idea_${DateTime.now().millisecondsSinceEpoch}'),
    name: Player.str(j['name'], 'Tactical idea'),
    mode: Player.str(j['mode'], 'custom'),
    description: Player.str(j['description']),
    json: Player.str(j['json'], '{}'),
  );
}


class LocalStore {
  static Future<Directory> _dir() async {
    final base = Directory('${Directory.systemTemp.path}/fc24_coach_ai_store');
    if (!base.existsSync()) base.createSync(recursive: true);
    return base;
  }

  static Future<File> _file(String name) async {
    final dir = await _dir();
    return File('${dir.path}/$name');
  }

  static Future<List<Player>> loadCustomPlayers() async {
    try {
      final f = await _file('players.json');
      if (!f.existsSync()) return [];
      final raw = jsonDecode(await f.readAsString()) as List;
      return raw.map((e)=>PlayerJsonExt.fromLocalJson(Map<String,dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  static Future<List<TeamInfo>> loadCustomTeams() async {
    try {
      final f = await _file('teams.json');
      if (!f.existsSync()) return [];
      final raw = jsonDecode(await f.readAsString()) as List;
      return raw.map((e)=>TeamJsonExt.fromLocalJson(Map<String,dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  static Future<List<TacticalIdea>> loadIdeas() async {
    try {
      final f = await _file('ideas.json');
      if (!f.existsSync()) return defaultIdeas();
      final raw = jsonDecode(await f.readAsString()) as List;
      return raw.map((e)=>TacticalIdea.fromJson(Map<String,dynamic>.from(e))).toList();
    } catch (_) { return defaultIdeas(); }
  }

  static List<TacticalIdea> defaultIdeas() => [
    const TacticalIdea(id:'idea_1', name:'ST attaque espace CB-LB', mode:'speed_long', description:'Course en profondeur avec ST Lengthy/Rapid+.', json:'{"type":"run","from":"ST","to":"space_cb_lb"}'),
    const TacticalIdea(id:'idea_2', name:'Cutback côté droit', mode:'cutback', description:'Ailier gagne la ligne puis passe en retrait.', json:'{"type":"cutback","side":"right"}'),
    const TacticalIdea(id:'idea_3', name:'Contre-pressing 5 secondes', mode:'pressing', description:'Relentless+ et Aggression pour récupérer vite.', json:'{"type":"press","duration":5}')
  ];

  static Future<void> saveCustomPlayers(List<Player> players) async {
    final custom = players.where((p)=>p.id.startsWith('custom_') || p.id.startsWith('local_')).map((p)=>p.toLocalJson()).toList();
    final f = await _file('players.json');
    await f.writeAsString(jsonEncode(custom));
  }

  static Future<void> saveCustomTeams(List<TeamInfo> teams) async {
    final custom = teams.where((t)=>t.id.startsWith('custom_') || t.id.startsWith('local_')).map((t)=>t.toLocalJson()).toList();
    final f = await _file('teams.json');
    await f.writeAsString(jsonEncode(custom));
  }

  static Future<void> saveIdeas(List<TacticalIdea> ideas) async {
    final f = await _file('ideas.json');
    await f.writeAsString(jsonEncode(ideas.map((e)=>e.toJson()).toList()));
  }

  static Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    final f = await _file('history.json');
    await f.writeAsString(jsonEncode(history));
  }

  static Future<List<Map<String, dynamic>>> loadHistory() async {
    try {
      final f = await _file('history.json');
      if (!f.existsSync()) return [];
      final raw = jsonDecode(await f.readAsString()) as List;
      return raw.map((e)=>Map<String,dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }
}

class PlayerAvatar extends StatelessWidget {
  final Player p;
  final double size;
  const PlayerAvatar({super.key, required this.p, this.size = 54});

  @override
  Widget build(BuildContext context) {
    final img = p.image.trim();
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF22C55E)]),
      ),
      child: Center(
        child: Text(
          p.name.isEmpty ? '?' : p.name.substring(0, 1).toUpperCase(),
          style: TextStyle(fontSize: size * .38, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
    if (img.isEmpty) return fallback;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: img.startsWith('http')
            ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
            : Image.asset(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
      ),
    );
  }
}

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  const StatBar({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 120, child: Text(label, overflow: TextOverflow.ellipsis)),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: value.clamp(0, 99) / 99, minHeight: 9))),
      const SizedBox(width: 10),
      SizedBox(width: 34, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
    ]),
  );
}

class ProBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  const ProBox({super.key, required this.title, required this.subtitle, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: const Color(0xFF86EFAC)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(color: Color(0xFFB7C9E8))),
          ])),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    ),
  );
}



class PlayStyleDetection {
  final String name;
  final int confidence;
  final String reason;
  const PlayStyleDetection(this.name, this.confidence, this.reason);
}

List<PlayStyleDetection> detectFc24PlayStyles(Player p) {
  final s = p.s;
  int v(String k) => s[k] ?? 0;
  final out = <PlayStyleDetection>[];

  void add(String name, int score, String reason) {
    if (score >= 74 && !out.any((x)=>x.name == name)) {
      out.add(PlayStyleDetection(name, score.clamp(0, 99), reason));
    }
  }

  // Heuristic formulas based on FC24 style categories.
  // IMPORTANT: this detects PlayStyles from attributes. It does NOT touch legacy traits.
  add('Rapid+', ((v('sprint')*.45 + v('acc')*.25 + v('stam')*.15 + p.ovr*.15).round()), 'Sprint Speed + Acceleration + Stamina.');
  add('Quick Step+', ((v('acc')*.48 + v('agi')*.24 + v('bal')*.13 + p.ovr*.15).round()), 'Acceleration + Agility + Balance.');
  add('Technical+', ((v('drib')*.34 + v('ball')*.28 + v('agi')*.18 + v('bal')*.10 + p.ovr*.10).round()), 'Dribbling + Ball Control + Agility.');
  add('Trickster+', ((v('drib')*.28 + v('agi')*.22 + v('ball')*.18 + p.skill*8 + p.ovr*.08).round()), 'Skill Moves + Dribbling + Agility.');
  add('First Touch+', ((v('ball')*.36 + v('react')*.24 + v('comp')*.20 + v('drib')*.10 + p.ovr*.10).round()), 'Ball Control + Reactions + Composure.');
  add('Press Proven+', ((v('ball')*.24 + v('bal')*.24 + v('str')*.18 + v('comp')*.18 + p.ovr*.16).round()), 'Balance + Ball Control + Strength under pressure.');
  add('Bruiser+', ((v('str')*.38 + v('agg')*.28 + v('bal')*.14 + p.weight*.06 + p.ovr*.14).round()), 'Strength + Aggression + Weight.');
  add('Aerial+', ((v('jump')*.30 + v('head')*.30 + v('str')*.14 + p.height*.08 + p.ovr*.08).round()), 'Jumping + Heading + Height.');
  add('Power Header+', ((v('head')*.40 + v('jump')*.22 + v('str')*.14 + p.height*.08 + p.ovr*.16).round()), 'Heading Accuracy + Jumping.');
  add('Anticipate+', ((v('tackle')*.34 + v('defaw')*.26 + v('inter')*.18 + v('react')*.12 + p.ovr*.10).round()), 'Standing Tackle + Defensive Awareness.');
  add('Block+', ((v('defaw')*.30 + v('inter')*.20 + v('str')*.16 + v('react')*.14 + p.height*.06 + p.ovr*.14).round()), 'Defensive Awareness + Interceptions + Size.');
  add('Jockey+', ((v('defaw')*.24 + v('agi')*.22 + v('bal')*.18 + v('tackle')*.16 + v('react')*.12 + p.ovr*.08).round()), 'Def Awareness + Agility + Balance.');
  add('Slide Tackle+', ((v('slide')*.42 + v('tackle')*.22 + v('agg')*.14 + v('defaw')*.14 + p.ovr*.08).round()), 'Slide Tackle + Standing Tackle.');
  add('Intercept+', ((v('inter')*.42 + v('defaw')*.24 + v('react')*.18 + v('stam')*.08 + p.ovr*.08).round()), 'Interceptions + Awareness + Reactions.');
  add('Relentless+', ((v('stam')*.45 + v('agg')*.22 + v('acc')*.12 + v('react')*.09 + p.ovr*.12).round()), 'Stamina + Aggression + Activity.');
  add('Finesse+', ((v('finish')*.26 + v('curve')*.24 + v('comp')*.18 + v('shot')*.12 + p.weakFoot*4 + p.ovr*.10).round()), 'Finishing + Curve + Composure.');
  add('Power Shot+', ((v('shot')*.38 + v('longshot')*.22 + v('finish')*.16 + v('comp')*.12 + p.ovr*.12).round()), 'Shot Power + Long Shots.');
  add('Dead Ball+', ((v('fk')*.40 + v('curve')*.24 + v('shot')*.10 + v('cross')*.10 + p.ovr*.16).round()), 'FK Accuracy + Curve.');
  add('Incisive Pass+', ((v('vision')*.34 + v('shortp')*.24 + v('longp')*.20 + v('comp')*.12 + p.ovr*.10).round()), 'Vision + Passing + Composure.');
  add('Long Ball Pass+', ((v('longp')*.40 + v('vision')*.22 + v('shortp')*.12 + v('comp')*.10 + p.ovr*.16).round()), 'Long Passing + Vision.');
  add('Whipped Pass+', ((v('cross')*.42 + v('curve')*.22 + v('vision')*.12 + v('acc')*.08 + p.ovr*.16).round()), 'Crossing + Curve.');
  add('Tiki Taka+', ((v('shortp')*.38 + v('vision')*.20 + v('ball')*.18 + v('comp')*.14 + p.ovr*.10).round()), 'Short Passing + Vision + Control.');

  out.sort((a,b)=>b.confidence.compareTo(a.confidence));
  return out.take(12).toList();
}

List<String> mergedPlayStyles(Player p) {
  final existing = p.playstyles.toSet();
  for (final d in detectFc24PlayStyles(p).where((x)=>x.confidence >= 82)) {
    existing.add(d.name);
  }
  return existing.toList();
}

class FormationPreset {
  final String name;
  final Map<String, Offset> spots;
  const FormationPreset(this.name, this.spots);
}

final formationPresets = <FormationPreset>[
  FormationPreset('4-3-3', {
    'GK': Offset(.08,.50),'LB': Offset(.24,.25),'CB1': Offset(.24,.42),'CB2': Offset(.24,.58),'RB': Offset(.24,.75),
    'CDM': Offset(.42,.50),'CM1': Offset(.52,.35),'CM2': Offset(.52,.65),'LW': Offset(.72,.25),'ST': Offset(.80,.50),'RW': Offset(.72,.75),
  }),
  FormationPreset('4-2-3-1', {
    'GK': Offset(.08,.50),'LB': Offset(.24,.25),'CB1': Offset(.24,.42),'CB2': Offset(.24,.58),'RB': Offset(.24,.75),
    'CDM1': Offset(.43,.42),'CDM2': Offset(.43,.58),'CAM': Offset(.58,.50),'LW': Offset(.67,.30),'ST': Offset(.80,.50),'RW': Offset(.67,.70),
  }),
  FormationPreset('5-3-2', {
    'GK': Offset(.08,.50),'LWB': Offset(.25,.18),'CB1': Offset(.24,.36),'CB2': Offset(.24,.50),'CB3': Offset(.24,.64),'RWB': Offset(.25,.82),
    'CM1': Offset(.50,.35),'CM2': Offset(.48,.50),'CM3': Offset(.50,.65),'ST1': Offset(.76,.42),'ST2': Offset(.76,.58),
  }),
];

class TeamInfo {
  final String id, name, manager;
  final int overall, attack, midfield, defense, citylikeScore;
  final List<String> weakTraits, equalTraits, strongTraits;
  final List<String> xi;

  const TeamInfo({
    required this.id,
    required this.name,
    required this.manager,
    required this.overall,
    required this.attack,
    required this.midfield,
    required this.defense,
    required this.citylikeScore,
    required this.weakTraits,
    required this.equalTraits,
    required this.strongTraits,
    required this.xi,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> j) {
    List<String> split(dynamic v) {
      final t = Player.str(v);
      if (t.isEmpty || t == '0') return [];
      return t.split(RegExp(r'[,|;/]')).map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
    }
    return TeamInfo(
      id: Player.str(j['teamid']),
      name: Player.str(j['teamname'], 'Team'),
      manager: Player.str(j['manager'], '—'),
      overall: Player.n(j['overall']),
      attack: Player.n(j['attack']),
      midfield: Player.n(j['midfield']),
      defense: Player.n(j['defense']),
      citylikeScore: Player.n(j['citylikeScore']),
      weakTraits: split(j['weakTraits']),
      equalTraits: split(j['equalTraits']),
      strongTraits: split(j['strongTraits']),
      xi: split(j['xi']),
    );
  }
}

class GameDb {
  final List<Player> players;
  final List<TeamInfo> teams;
  const GameDb(this.players, this.teams);

  int get teamCount => teams.length;

  static Future<GameDb> load() async {
    final raw = await rootBundle.loadString('assets/data/fc24-real-data.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final playerList = (decoded['players'] as List? ?? const []).cast<dynamic>();
    final players = <Player>[];
    for (final item in playerList) {
      try {
        players.add(Player.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    players.sort((a, b) => b.ovr.compareTo(a.ovr));

    final teamList = (decoded['teams'] as List? ?? const []).cast<dynamic>();
    final teams = <TeamInfo>[];
    for (final item in teamList) {
      try {
        teams.add(TeamInfo.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    teams.sort((a,b)=>b.overall.compareTo(a.overall));
    return GameDb(players, teams);
  }
}

class Mode {
  final String key, label, group, desc;
  final Map<String, double> w;
  const Mode(this.key, this.label, this.group, this.desc, this.w);
}

const modes = <Mode>[
  Mode('physical', 'Duel physique', 'Duel', 'Épaule contre épaule, contact, protection.', {'str':.34,'agg':.18,'bal':.15,'sprint':.10,'react':.10,'stam':.08,'jump':.05}),
  Mode('speed_short', 'Vitesse courte 0-10m', 'Vitesse', 'Démarrage explosif, sortie de dribble.', {'acc':.42,'sprint':.20,'agi':.14,'react':.12,'bal':.07,'stam':.05}),
  Mode('speed_long', 'Course longue', 'Vitesse', 'Appel profondeur, poursuite, contre-attaque.', {'sprint':.42,'acc':.22,'stam':.14,'str':.08,'react':.08,'agi':.06}),
  Mode('dribble', 'Dribble 1v1', 'Attaque', 'Ailier/CAM contre défenseur.', {'agi':.24,'drib':.22,'acc':.18,'bal':.14,'ball':.12,'react':.10}),
  Mode('defense', 'Tacle / récupération', 'Défense', 'Défenseur qui attaque le ballon.', {'tackle':.28,'defaw':.24,'inter':.16,'react':.12,'str':.10,'agg':.10}),
  Mode('interception', 'Passe vs interception', 'Lecture', 'Passeur contre joueur qui coupe la ligne.', {'vision':.22,'shortp':.18,'longp':.15,'comp':.10,'inter':.16,'defaw':.12,'react':.07}),
  Mode('pressing', 'Pressing 1v1', 'Pressing', 'Harceler le porteur, contre-pressing.', {'stam':.22,'agg':.20,'acc':.18,'react':.14,'defaw':.10,'str':.08,'agi':.08}),
  Mode('pass_break', 'Casser ligne par passe', 'Passe', 'Trouver une passe verticale contre bloc.', {'vision':.26,'shortp':.22,'longp':.20,'comp':.12,'react':.08,'ball':.08,'drib':.04}),
  Mode('aerial', 'Duel aérien', 'Aérien', 'Centre, corner, ballon long.', {'head':.28,'jump':.24,'str':.18,'react':.10,'agg':.08,'defaw':.06,'finish':.06}),
  Mode('finish', 'Finition sous pression', 'Tir', 'Tir, sang-froid, contact.', {'finish':.28,'comp':.22,'shot':.18,'react':.12,'ball':.08,'str':.06,'bal':.06}),
  Mode('cutback', 'Cutback attaque/défense', 'Zone', 'Passe en retrait ou couverture de cutback.', {'acc':.14,'drib':.14,'cross':.14,'vision':.12,'inter':.16,'defaw':.16,'react':.14}),
  Mode('jockey', 'Jockey défensif', 'Défense', 'Contenir sans se jeter.', {'defaw':.24,'agi':.20,'bal':.16,'tackle':.16,'react':.14,'acc':.10}),
];

String labelStat(String k) => {
  'acc':'Acceleration','sprint':'Sprint Speed','str':'Strength','agg':'Aggression','bal':'Balance','agi':'Agility','react':'Reactions',
  'ball':'Ball Control','drib':'Dribbling','defaw':'Def. Awareness','tackle':'Standing Tackle','slide':'Slide Tackle','inter':'Interceptions',
  'finish':'Finishing','shot':'Shot Power','longshot':'Long Shots','comp':'Composure','stam':'Stamina','jump':'Jumping','head':'Heading',
  'cross':'Crossing','shortp':'Short Passing','longp':'Long Passing','vision':'Vision','curve':'Curve'
}[k] ?? k;

class DuelScore {
  final int total, core, profile, play;
  final List<FactorRow> factors;
  final List<ImpactRow> profileRows, playRows;
  const DuelScore(this.total, this.core, this.profile, this.play, this.factors, this.profileRows, this.playRows);
}

class FactorRow {
  final String key;
  final int raw;
  final int points;
  final int weight;
  const FactorRow(this.key, this.raw, this.points, this.weight);
}

class ImpactRow {
  final String name, reason;
  final int points;
  final bool active;
  const ImpactRow(this.name, this.reason, this.points, this.active);
}

DuelScore score(Player p, Mode m) {
  double core = 0;
  final factors = <FactorRow>[];
  for (final e in m.w.entries) {
    final raw = p.s[e.key] ?? 0;
    final pts = (raw * e.value).round();
    core += raw * e.value;
    factors.add(FactorRow(e.key, raw, pts, (e.value*100).round()));
  }
  final pr = profileRows(p, m);
  final pl = playRows(p, m);
  final profile = pr.fold<int>(0, (a, b) => a + b.points);
  final play = pl.where((x) => x.active).fold<int>(0, (a, b) => a + b.points);
  final total = (core + profile + play).round();
  return DuelScore(total, core.round(), profile, play, factors, pr, pl);
}

List<ImpactRow> profileRows(Player p, Mode m) {
  final rows = <ImpactRow>[];
  void add(String n, int v, String r) => rows.add(ImpactRow(n, r, v, v != 0));
  final h=p.height,w=p.weight,body=p.body,accel=p.accel;
  if (['physical'].contains(m.key)) {
    add('Poids', w>=85?7:w>=78?4:0, 'stabilité dans le contact');
    add('Taille', h>=188?5:h>=183?3:0, 'portée et corps dans le duel');
    add('Body Type', body.contains('Stocky')||body=='Unique'?6:body.contains('High')?4:0, 'animations de contact/protection');
    add('AcceleRATE', accel.contains('Lengthy')?4:2, 'arrivée dans le duel');
  } else if (m.key == 'speed_short') {
    add('AcceleRATE', accel.contains('Explosive')?8:accel.contains('Lengthy')?-2:2, 'Explosive domine court');
    add('Body Type', body=='Lean'?5:body=='Unique'?4:0, 'fluidité du démarrage');
    add('Poids', w>88?-3:w<70?2:0, 'légèreté/explosivité');
  } else if (m.key == 'speed_long') {
    add('AcceleRATE', accel.contains('Lengthy')?8:accel.contains('Explosive')?3:4, 'Lengthy fort sur longue course');
    add('Taille', h>=185?3:0, 'grande foulée');
  } else if (m.key == 'dribble') {
    add('Body Type', body=='Lean'?8:body=='Unique'?6:body.contains('Stocky')?-3:0, 'animations de dribble');
    add('AcceleRATE', accel.contains('Explosive')?5:accel.contains('Lengthy')?-2:2, 'sortie de dribble');
    add('Poids', w<70?2:w>85?-2:0, 'capacité à tourner');
  } else if (m.key == 'aerial') {
    add('Taille', h>=190?8:h>=185?5:0, 'domination aérienne');
    add('Poids', w>=85?4:w>=78?2:0, 'stabilité dans les airs');
    add('Body Type', body.contains('High')||body=='Unique'?4:0, 'animations aériennes');
  } else {
    add('Body Type', body=='Unique'?2:body.contains('High')?1:0, 'animations situationnelles');
    add('AcceleRATE', accel.contains('Explosive')||accel.contains('Lengthy')?2:1, 'réaction mouvement');
  }
  return rows;
}

List<ImpactRow> playRows(Player p, Mode m) {
  final map = <String, Map<String, int>>{
    'physical': {'Bruiser+':8,'Press Proven+':5,'Aerial+':3,'Block+':2},
    'speed_short': {'Quick Step+':10,'Rapid+':4,'Technical+':2},
    'speed_long': {'Rapid+':9,'Quick Step+':4,'Relentless+':3},
    'dribble': {'Technical+':9,'Trickster+':7,'First Touch+':5,'Press Proven+':4,'Quick Step+':4},
    'defense': {'Anticipate+':9,'Block+':7,'Jockey+':6,'Slide Tackle+':5,'Bruiser+':3,'Intercept+':4},
    'interception': {'Intercept+':8,'Incisive Pass+':4,'Long Ball Pass+':3},
    'pressing': {'Relentless+':9,'Intercept+':7,'Bruiser+':4,'Anticipate+':4},
    'pass_break': {'Incisive Pass+':9,'Long Ball Pass+':8,'Tiki Taka+':7,'Whipped Pass+':6},
    'aerial': {'Aerial+':10,'Power Header+':9,'Bruiser+':4,'Anticipate+':3},
    'finish': {'Finesse+':8,'Power Shot+':8,'Aerial+':3,'First Touch+':3,'Technical+':2},
    'cutback': {'Whipped Pass+':6,'Intercept+':7,'Block+':5,'Technical+':4},
    'jockey': {'Jockey+':8,'Anticipate+':6,'Block+':4},
  };
  final active = map[m.key] ?? {};
  final all = mergedPlayStyles(p).isEmpty ? ['Aucun PlayStyle'] : mergedPlayStyles(p);
  return all.take(8).map((ps) {
    final val = active[ps] ?? 0;
    return ImpactRow(ps, val > 0 ? playReason(ps) : 'non actif dans ce mode', val, val > 0);
  }).toList();
}

String playReason(String ps) => {
  'Quick Step+':'boost démarrage',
  'Rapid+':'boost vitesse lancée',
  'Technical+':'animations dribble',
  'Trickster+':'feintes spéciales',
  'First Touch+':'contrôle orienté',
  'Press Proven+':'résiste pressing',
  'Bruiser+':'contact physique',
  'Aerial+':'duel aérien',
  'Power Header+':'tête puissante',
  'Anticipate+':'intervention défensive',
  'Block+':'blocage',
  'Jockey+':'contenu latéral',
  'Slide Tackle+':'tacle glissé',
  'Intercept+':'ligne de passe',
  'Relentless+':'endurance pressing',
  'Finesse+':'tir enroulé',
  'Power Shot+':'frappe puissante',
  'Incisive Pass+':'passe cassante',
  'Long Ball Pass+':'longue passe',
  'Whipped Pass+':'centre tendu',
  'Tiki Taka+':'passe courte'
}[ps] ?? 'impact situationnel';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  GameDb? db;
  Object? error;
  int tab = 0;
  late List<Player> customPlayers;
  late List<TeamInfo> customTeams;
  late List<TacticalIdea> tacticalIdeas;
  late List<Map<String, dynamic>> history;
  Player? a,b;
  Mode mode = modes[3];

  @override void initState() {
    super.initState();
    customPlayers = [];
    customTeams = [];
    tacticalIdeas = [];
    history = [];
    Future.delayed(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    try {
      final loaded = await GameDb.load();
      final savedPlayers = await LocalStore.loadCustomPlayers();
      final savedTeams = await LocalStore.loadCustomTeams();
      final savedIdeas = await LocalStore.loadIdeas();
      final savedHistory = await LocalStore.loadHistory();

      final mergedPlayers = List<Player>.from(loaded.players);
      final mergedTeams = List<TeamInfo>.from(loaded.teams);

      for (final p in savedPlayers) {
        if (!mergedPlayers.any((x)=>x.id == p.id)) mergedPlayers.insert(0, p);
      }
      for (final t in savedTeams) {
        if (!mergedTeams.any((x)=>x.id == t.id)) mergedTeams.insert(0, t);
      }

      setState(() {
        db = loaded;
        customPlayers = mergedPlayers;
        customTeams = mergedTeams;
        tacticalIdeas = savedIdeas;
        history = savedHistory;
        a = customPlayers.firstWhere((p)=>p.name.toLowerCase().contains('mbapp'), orElse: ()=>customPlayers.first);
        b = customPlayers.firstWhere((p)=>p.name.toLowerCase().contains('walker'), orElse: ()=>customPlayers.skip(1).first);
      });
    } catch (e) { setState(()=>error=e); }
  }

  void go(int i) {
    setState(()=>tab=i);
    Navigator.maybePop(context);
  }

  @override Widget build(BuildContext context) {
    final loaded = db;
    final pages = loaded == null ? <Widget>[] : [
      DashboardPage(db: GameDb(customPlayers, customTeams), onStart: ()=>setState(()=>tab=1)),
      ComparePage(players: customPlayers, a: a!, b: b!, mode: mode, onA:(p)=>setState(()=>a=p), onB:(p)=>setState(()=>b=p), onMode:(m)=>setState(()=>mode=m), onSaveHistory:(row) async { setState(()=>history.insert(0,row)); await LocalStore.saveHistory(history); }),
      DetectorPage(players: customPlayers, ref: a!, mode: mode),
      DatabasePage(players: customPlayers),
      TeamsPage(teams: customTeams, players: customPlayers, onEditTeam: (t)=>showTeamEditor(context, t)),
      PlayerCrudPage(players: customPlayers, onSave: (p){
        setState(() {
          final i = customPlayers.indexWhere((x)=>x.id==p.id);
          if (i >= 0) customPlayers[i] = p; else customPlayers.insert(0,p);
          a ??= p;
          LocalStore.saveCustomPlayers(customPlayers);
        });
      }),
      TeamCrudPage(teams: customTeams, onSave: (t){
        setState(() {
          final i = customTeams.indexWhere((x)=>x.id==t.id);
          if (i >= 0) customTeams[i]=t; else customTeams.insert(0,t);
          LocalStore.saveCustomTeams(customTeams);
        });
      }),
      TeamAnalyzerPage(teams: customTeams, players: customPlayers),
      TeamVsTeamPage(teams: customTeams, players: customPlayers),
      MatchupFinderPage(players: customPlayers),
      TacticalIdeasPage(players: customPlayers, ideas: tacticalIdeas, onSave: (ideas) async { setState(()=>tacticalIdeas = ideas); await LocalStore.saveIdeas(ideas); }),
      TacticalPage(a: a!, b: b!, mode: mode),
      FormationBuilderPage(players: customPlayers),
      HistoryPage(history: history),
      PlayStyleDetectorPage(players: customPlayers),
      CoachNotebookPage(),
      ExportImportPage(players: customPlayers, teams: customTeams, ideas: tacticalIdeas, onImport: (ps, ts, ideas) async {
        setState(() { customPlayers = ps; customTeams = ts; tacticalIdeas = ideas; });
        await LocalStore.saveCustomPlayers(customPlayers);
        await LocalStore.saveCustomTeams(customTeams);
        await LocalStore.saveIdeas(tacticalIdeas);
      }),
      ModesGuidePage(),
    ];

    return Scaffold(
      drawer: loaded == null ? null : AppDrawer(current: tab, onGo: go),
      appBar: AppBar(
        title: const Text('FC24 Coach AI Pro'),
        leading: loaded == null ? null : Builder(builder: (context)=>IconButton(icon: const Icon(Icons.menu_rounded), onPressed: ()=>Scaffold.of(context).openDrawer())),
        actions: [
          if (loaded != null) Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: Text('${customPlayers.length} joueurs', style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w900)))),
        ],
      ),
      body: SafeArea(
        child: loaded == null
          ? StartLoader(error: error, onRetry: _load)
          : AnimatedSwitcher(duration: const Duration(milliseconds: 260), child: pages[tab]),
      ),
      bottomNavigationBar: loaded == null ? null : NavigationBar(
        selectedIndex: tab == 11 ? 4 : (tab > 4 ? 3 : tab),
        onDestinationSelected: (i)=>setState(()=>tab = [0,1,2,3,11][i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.compare_arrows_rounded), label: 'Comparer'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Détecter'),
          NavigationDestination(icon: Icon(Icons.storage_rounded), label: 'Joueurs'),
          NavigationDestination(icon: Icon(Icons.sports_soccer_rounded), label: 'Terrain'),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final int current;
  final ValueChanged<int> onGo;
  const AppDrawer({super.key, required this.current, required this.onGo});
  @override Widget build(BuildContext context) {
    final items = [
      (0, Icons.dashboard_rounded, 'Dashboard'),
      (1, Icons.compare_arrows_rounded, 'Comparateur'),
      (2, Icons.search_rounded, 'Détection meilleurs'),
      (3, Icons.people_alt_rounded, 'Base joueurs'),
      (4, Icons.shield_rounded, 'Teams'),
      (5, Icons.person_add_alt_1_rounded, 'CRUD Players'),
      (6, Icons.add_business_rounded, 'CRUD Teams'),
      (7, Icons.analytics_rounded, 'Team Analyzer'),
      (8, Icons.compare_rounded, 'Team vs Team'),
      (9, Icons.hub_rounded, 'Matchup Finder'),
      (10, Icons.auto_awesome_motion_rounded, 'Banque tactique'),
      (11, Icons.sports_soccer_rounded, 'Tactical Lab'),
      (12, Icons.grid_on_rounded, 'Formation Builder'),
      (13, Icons.history_rounded, 'Historique'),
      (14, Icons.bolt_rounded, 'Détection PlayStyles'),
      (15, Icons.edit_note_rounded, 'Carnet entraîneur'),
      (16, Icons.import_export_rounded, 'Export / Import'),
      (17, Icons.menu_book_rounded, 'Guide modes'),
    ];
    return Drawer(
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors:[Color(0xFF123626), Color(0xFF0B1728)])),
          child: const Row(children: [
            Icon(Icons.sports_soccer, color: Color(0xFF86EFAC), size: 36),
            SizedBox(width: 10),
            Expanded(child: Text('FC24 Coach AI\nMobile Pro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
          ]),
        ),
        Expanded(child: ListView(children: items.map((it)=>ListTile(
          selected: current == it.$1,
          leading: Icon(it.$2),
          title: Text(it.$3),
          onTap: ()=>onGo(it.$1),
        )).toList())),
      ])),
    );
  }
}

class StartLoader extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const StartLoader({super.key, this.error, required this.onRetry});
  @override Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sports_soccer, size: 54, color: Color(0xFF22C55E)),
          const SizedBox(height: 16),
          Text(error == null ? 'Chargement base FC24...' : 'Erreur chargement DB', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (error == null) const LinearProgressIndicator() else Text('$error'),
          if (error != null) const SizedBox(height: 12),
          if (error != null) FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ]),
      )),
    ));
  }
}

class DashboardPage extends StatelessWidget {
  final GameDb db;
  final VoidCallback onStart;
  const DashboardPage({super.key, required this.db, required this.onStart});
  @override Widget build(BuildContext context) {
    final top = db.players.take(5).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [Color(0xFF0B1728), Color(0xFF123626)]),
          border: Border.all(color: const Color(0xFF263A55)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Coach AI Pro', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Comparaison joueur vs joueur, modes tactiques, détection des meilleurs profils, DB complète plugin.'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow), label: const Text('Lancer comparaison')),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Kpi('Joueurs', '${db.players.length}', Icons.people_alt_rounded)),
        const SizedBox(width: 10),
        Expanded(child: Kpi('Équipes', '${db.teamCount}', Icons.shield_rounded)),
      ]),
      const SizedBox(height: 14),
      Text('Top joueurs DB', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      ...top.map((p)=>PlayerTile(p: p)),
    ]);
  }
}

class Kpi extends StatelessWidget {
  final String label,value; final IconData icon;
  const Kpi(this.label,this.value,this.icon,{super.key});
  @override Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [Icon(icon, color: const Color(0xFF38BDF8)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label), Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF86EFAC)))])]),
  ));
}

class ComparePage extends StatelessWidget {
  final List<Player> players; final Player a,b; final Mode mode;
  final ValueChanged<Player> onA,onB; final ValueChanged<Mode> onMode; final ValueChanged<Map<String,dynamic>> onSaveHistory;
  const ComparePage({super.key, required this.players, required this.a, required this.b, required this.mode, required this.onA, required this.onB, required this.onMode, required this.onSaveHistory});
  @override Widget build(BuildContext context) {
    final sa=score(a,mode), sb=score(b,mode), win=sa.total>=sb.total?a:b;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Comparateur', 'Gagnant prévu : ${win.name}'),
      PlayerPicker(title:'Joueur A', players:players, value:a, onChanged:onA),
      PlayerPicker(title:'Joueur B', players:players, value:b, onChanged:onB),
      ModePicker(mode: mode, onChanged: onMode),
      ScoreSummary(a:a,b:b,sa:sa,sb:sb),
      FilledButton.icon(onPressed: () => onSaveHistory({'date': DateTime.now().toIso8601String(), 'a': a.name, 'b': b.name, 'mode': mode.label, 'scoreA': sa.total, 'scoreB': sb.total, 'winner': win.name}), icon: const Icon(Icons.save), label: const Text('Sauvegarder dans historique')),
      const SizedBox(height: 10),
      DetailCard(a:a,b:b,sa:sa,sb:sb,mode:mode),
    ]);
  }
}

class Header extends StatelessWidget {
  final String title, sub;
  const Header(this.title,this.sub,{super.key});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 4), Text(sub, style: const TextStyle(color: Color(0xFFB7C9E8))),
    ]),
  );
}

class PlayerPicker extends StatelessWidget {
  final String title; final List<Player> players; final Player value; final ValueChanged<Player> onChanged;
  const PlayerPicker({super.key, required this.title, required this.players, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))), FilledButton.tonalIcon(onPressed: () async { final p=await showPlayerSearch(context, players, value); if(p!=null) onChanged(p); }, icon: const Icon(Icons.search), label: const Text('Chercher'))]),
      const SizedBox(height: 8),
      Row(children: [
        PlayerAvatar(p: value, size: 62),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text('${value.team} • ${value.pos}${value.pos2.isNotEmpty ? " / ${value.pos2}" : ""} • OVR ${value.ovr}'),
        ])),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        Chip(label: Text('${value.height}cm')),
        Chip(label: Text('${value.weight}kg')),
        Chip(label: Text(value.body)),
        Chip(label: Text(value.accel)),
        Chip(label: Text('SM ${value.skill}')),
        Chip(label: Text('WF ${value.weakFoot}')),
      ]),
    ]),
  ));
}

Future<Player?> showPlayerSearch(BuildContext context, List<Player> players, Player current) {
  return showDialog<Player>(context: context, builder: (_) => PlayerSearchDialog(players: players, current: current));
}

class PlayerSearchDialog extends StatefulWidget {
  final List<Player> players; final Player current;
  const PlayerSearchDialog({super.key, required this.players, required this.current});
  @override State<PlayerSearchDialog> createState()=>_PlayerSearchDialogState();
}
class _PlayerSearchDialogState extends State<PlayerSearchDialog> {
  String q=''; String team='all'; String pos='all';
  @override Widget build(BuildContext context) {
    final teams=['all', ...widget.players.map((p)=>p.team).where((t)=>t!='—').toSet().take(150)];
    final query=q.toLowerCase().trim();
    final res=widget.players.where((p)=>
      (team=='all'||p.team==team) &&
      (pos=='all'||p.pos.toUpperCase().contains(pos)) &&
      (query.isEmpty || ('${p.name} ${p.team} ${p.pos} ${p.ovr}').toLowerCase().contains(query))
    ).take(150).toList();
    return AlertDialog(
      title: const Text('Choisir joueur'),
      content: SizedBox(width: double.maxFinite, height: 560, child: Column(children: [
        TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Nom, équipe, poste...'), onChanged:(v)=>setState(()=>q=v)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: team, isExpanded: true, items: teams.map((t)=>DropdownMenuItem(value:t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>team=v!), decoration: const InputDecoration(labelText:'Équipe'))),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(value: pos, items: ['all','ST','LW','RW','CAM','CM','CDM','LB','RB','CB','GK'].map((t)=>DropdownMenuItem(value:t, child: Text(t))).toList(), onChanged:(v)=>setState(()=>pos=v!), decoration: const InputDecoration(labelText:'Poste'))),
        ]),
        const SizedBox(height: 8),
        Expanded(child: ListView.builder(itemCount: res.length, itemBuilder: (_,i)=>PlayerTile(p:res[i], onTap:()=>Navigator.pop(context,res[i])))),
      ])),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Fermer'))],
    );
  }
}

class ModePicker extends StatelessWidget {
  final Mode mode; final ValueChanged<Mode> onChanged;
  const ModePicker({super.key, required this.mode, required this.onChanged});
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: DropdownButtonFormField<String>(
    value: mode.key, isExpanded: true,
    decoration: const InputDecoration(labelText:'Mode / situation'),
    items: modes.map((m)=>DropdownMenuItem(value:m.key, child: Text('${m.group} — ${m.label}', overflow: TextOverflow.ellipsis))).toList(),
    onChanged: (v)=>onChanged(modes.firstWhere((m)=>m.key==v)),
  )));
}

class ScoreSummary extends StatelessWidget {
  final Player a,b; final DuelScore sa,sb;
  const ScoreSummary({super.key, required this.a, required this.b, required this.sa, required this.sb});
  @override Widget build(BuildContext context) {
    final total=max(1,sa.total+sb.total), pa=(sa.total/total*100).round(), pb=100-pa;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('${a.name} vs ${b.name}', style: const TextStyle(fontWeight: FontWeight.w900))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors:[Color(0xFF22C55E), Color(0xFF38BDF8)])), child: Text('${sa.total} - ${sb.total}', style: const TextStyle(color: Color(0xFF052E16), fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: pa/100, minHeight: 12, backgroundColor: const Color(0xFF263A55))),
      const SizedBox(height: 8),
      Text('${a.name}: $pa% • ${b.name}: $pb%'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: MiniScore('Stats', sa.core, '${a.name}')),
        const SizedBox(width: 8), Expanded(child: MiniScore('Profil', sa.profile, 'Body/Accel')),
        const SizedBox(width: 8), Expanded(child: MiniScore('PlayStyles', sa.play, 'actifs')),
      ]),
    ])));
  }
}
class MiniScore extends StatelessWidget {
  final String a,b; final int v;
  const MiniScore(this.a,this.v,this.b,{super.key});
  @override Widget build(BuildContext context)=>Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF101F35), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF263A55))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(a, style: const TextStyle(color: Color(0xFFB7C9E8))), Text('$v', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(b, maxLines:1, overflow:TextOverflow.ellipsis)]));
}

class DetailCard extends StatelessWidget {
  final Player a,b; final DuelScore sa,sb; final Mode mode;
  const DetailCard({super.key, required this.a, required this.b, required this.sa, required this.sb, required this.mode});
  @override Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Détail pondéré', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      ...List.generate(sa.factors.length, (i) {
        final fa=sa.factors[i], fb=sb.factors[i], diff=fa.points-fb.points;
        return ListTile(
          dense: true, contentPadding: EdgeInsets.zero,
          title: Text(labelStat(fa.key)),
          subtitle: Text('poids ${fa.weight}%'),
          trailing: Text('${fa.raw}→${fa.points}  |  ${fb.raw}→${fb.points}   ${diff>0?'+':''}$diff', style: TextStyle(fontWeight: FontWeight.w900, color: diff>=0?const Color(0xFF86EFAC):const Color(0xFFFB7185))),
        );
      }),
      const Divider(),
      Text('Profil caché / animations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      Wrap(spacing: 8, runSpacing: 8, children: [...sa.profileRows.map((r)=>Chip(label: Text('${a.name}: ${r.name} ${r.points>0?"+":""}${r.points}'))), ...sb.profileRows.map((r)=>Chip(label: Text('${b.name}: ${r.name} ${r.points>0?"+":""}${r.points}')))]),
      const Divider(),
      Text('PlayStyles utilisés / inutiles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: PlayBox(name:a.name, rows:sa.playRows)),
        const SizedBox(width: 8),
        Expanded(child: PlayBox(name:b.name, rows:sb.playRows)),
      ]),
    ])));
  }
}
class PlayBox extends StatelessWidget {
  final String name; final List<ImpactRow> rows;
  const PlayBox({super.key, required this.name, required this.rows});
  @override Widget build(BuildContext context)=>Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF101F35), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF263A55))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
    ...rows.map((r)=>Padding(padding: const EdgeInsets.only(top:6), child: Text('${r.name} ${r.active ? "+${r.points}" : "inutile"}\n${r.reason}', style: TextStyle(color: r.active ? const Color(0xFF86EFAC) : const Color(0xFFB7C9E8), fontSize: 12))))
  ]));
}

class DetectorPage extends StatefulWidget {
  final List<Player> players; final Player ref; final Mode mode;
  const DetectorPage({super.key, required this.players, required this.ref, required this.mode});
  @override State<DetectorPage> createState()=>_DetectorPageState();
}
class _DetectorPageState extends State<DetectorPage> {
  late Player ref; late Mode mode; String pos='all'; String team='all'; int minGap=1;
  @override void initState(){super.initState(); ref=widget.ref; mode=widget.mode;}
  @override Widget build(BuildContext context) {
    final teams=['all', ...widget.players.map((p)=>p.team).where((t)=>t!='—').toSet().take(200)];
    final refScore=score(ref,mode).total;
    final rows=widget.players.where((p)=>p.id!=ref.id && (team=='all'||p.team==team) && (pos=='all'||p.pos.toUpperCase().contains(pos)))
      .map((p)=>(p:p, sc:score(p,mode).total)).where((x)=>x.sc-refScore>=minGap).toList()..sort((a,b)=>b.sc.compareTo(a.sc));
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Détection meilleurs joueurs', 'Trouve les profils plus forts selon mode/poste'),
      PlayerPicker(title:'Référence', players: widget.players, value: ref, onChanged:(p)=>setState(()=>ref=p)),
      ModePicker(mode: mode, onChanged:(m)=>setState(()=>mode=m)),
      Row(children:[
        Expanded(child: DropdownButtonFormField<String>(value: pos, items: ['all','ST','LW','RW','CAM','CM','CDM','LB','RB','CB','GK'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>pos=v!), decoration: const InputDecoration(labelText:'Poste'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value: team, isExpanded:true, items: teams.map((x)=>DropdownMenuItem(value:x, child: Text(x, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>team=v!), decoration: const InputDecoration(labelText:'Équipe'))),
      ]),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('${rows.length} joueurs > ${ref.name} • score référence $refScore'))),
      ...rows.take(80).map((x)=>Card(child: ListTile(title: Text(x.p.name), subtitle: Text('${x.p.team} • ${x.p.pos} • ${x.p.body} • ${x.p.accel}'), trailing: Text('${x.sc}  +${x.sc-refScore}', style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w900))))),
    ]);
  }
}

class DatabasePage extends StatefulWidget {
  final List<Player> players;
  const DatabasePage({super.key, required this.players});
  @override State<DatabasePage> createState()=>_DatabasePageState();
}
class _DatabasePageState extends State<DatabasePage> {
  String q='', pos='all', team='all';
  @override Widget build(BuildContext context) {
    final teams=['all', ...widget.players.map((p)=>p.team).where((t)=>t!='—').toSet().take(200)];
    final query=q.toLowerCase().trim();
    final rows=widget.players.where((p)=>(team=='all'||p.team==team)&&(pos=='all'||p.pos.toUpperCase().contains(pos))&&(query.isEmpty||('${p.name} ${p.team} ${p.pos}').toLowerCase().contains(query))).take(250).toList();
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Base joueurs', '${widget.players.length} joueurs depuis le plugin'),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Recherche joueur...'), onChanged:(v)=>setState(()=>q=v)),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child: DropdownButtonFormField<String>(value: pos, items: ['all','ST','LW','RW','CAM','CM','CDM','LB','RB','CB','GK'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>pos=v!), decoration: const InputDecoration(labelText:'Poste'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value: team, isExpanded:true, items: teams.map((x)=>DropdownMenuItem(value:x, child: Text(x, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>team=v!), decoration: const InputDecoration(labelText:'Équipe'))),
      ]),
      const SizedBox(height: 8),
      ...rows.map((p)=>PlayerTile(p:p, onTap:()=>showPlayerDetails(context,p))),
    ]);
  }
}


void showPlayerDetails(BuildContext context, Player p) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF06111F),
    builder: (_) {
      final stats = ['acc','sprint','str','agg','bal','agi','react','ball','drib','defaw','tackle','inter','finish','shot','comp','stam','jump','head','cross','shortp','longp','vision'];
      return DraggableScrollableSheet(
        initialChildSize: .88,
        maxChildSize: .95,
        minChildSize: .45,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              PlayerAvatar(p: p, size: 84),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text('${p.team} • ${p.pos} • OVR ${p.ovr} • POT ${p.pot}'),
              ])),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(label: Text('${p.height}cm')),
              Chip(label: Text('${p.weight}kg')),
              Chip(label: Text(p.body)),
              Chip(label: Text(p.accel)),
              Chip(label: Text('Foot ${p.foot}')),
              Chip(label: Text('SM ${p.skill}')),
              Chip(label: Text('WF ${p.weakFoot}')),
              Chip(label: Text('WR ${p.attWr}/${p.defWr}')),
            ]),
            const Divider(),
            Text('PlayStyles', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.playstyles.isEmpty
                  ? [const Chip(label: Text('Aucun'))]
                  : p.playstyles.map((x) => Chip(label: Text(x))).toList(),
            ),
            const Divider(),
            Text('Stats détaillées', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            ...stats.map((k) => StatBar(label: labelStat(k), value: p.s[k] ?? 0)),
          ],
        ),
      );
    },
  );
}


class PlayerTile extends StatelessWidget {
  final Player p; final VoidCallback? onTap;
  const PlayerTile({super.key, required this.p, this.onTap});
  @override Widget build(BuildContext context)=>Card(child: ListTile(
    onTap:onTap,
    leading: PlayerAvatar(p: p),
    title: Text(p.name, maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(fontWeight:FontWeight.w900)),
    subtitle: Text('${p.team} • ${p.pos} • ${p.height}cm ${p.weight}kg\n${p.body} • ${p.accel}', maxLines:2, overflow:TextOverflow.ellipsis),
    trailing: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
      Text('OVR ${p.ovr}', style: const TextStyle(fontWeight:FontWeight.w900, color: Color(0xFF86EFAC))),
      Text(p.playstyles.take(1).join(), style: const TextStyle(fontSize:10), overflow:TextOverflow.ellipsis),
    ]),
  ));
}


class TeamAnalyzerPage extends StatefulWidget {
  final List<TeamInfo> teams;
  final List<Player> players;
  const TeamAnalyzerPage({super.key, required this.teams, required this.players});
  @override State<TeamAnalyzerPage> createState()=>_TeamAnalyzerPageState();
}
class _TeamAnalyzerPageState extends State<TeamAnalyzerPage> {
  TeamInfo? team;
  @override Widget build(BuildContext context) {
    team ??= widget.teams.isNotEmpty ? widget.teams.first : null;
    final t = team;
    if (t == null) return const Center(child: Text('Aucune équipe'));
    final squad = widget.players.where((p)=>p.team == t.name).toList()..sort((a,b)=>b.ovr.compareTo(a.ovr));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Team Analyzer', 'Forces, faiblesses et joueurs clés'),
      DropdownButtonFormField<String>(
        value: t.id,
        isExpanded: true,
        items: widget.teams.take(300).map((x)=>DropdownMenuItem(value:x.id, child: Text(x.name, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (id)=>setState(()=>team = widget.teams.firstWhere((x)=>x.id == id)),
        decoration: const InputDecoration(labelText:'Équipe'),
      ),
      const SizedBox(height: 12),
      TeamCard(team: t, players: widget.players, onEdit: (){}),
      ProBox(title:'Joueurs clés', subtitle:'Top OVR de l’équipe', icon: Icons.stars_rounded, child: Column(children: squad.take(12).map((p)=>PlayerTile(p:p, onTap:()=>showPlayerDetails(context,p))).toList())),
    ]);
  }
}

class MatchupFinderPage extends StatefulWidget {
  final List<Player> players;
  const MatchupFinderPage({super.key, required this.players});
  @override State<MatchupFinderPage> createState()=>_MatchupFinderPageState();
}
class _MatchupFinderPageState extends State<MatchupFinderPage> {
  String mode='speed_long'; String pos='ST';
  @override Widget build(BuildContext context) {
    final m = modes.firstWhere((x)=>x.key==mode);
    final rows = widget.players.where((p)=>pos=='all'||p.pos.toUpperCase().contains(pos)).map((p)=>(p:p, sc:score(p,m).total)).toList()..sort((a,b)=>b.sc.compareTo(a.sc));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Matchup Finder', 'Classe les meilleurs profils par situation'),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(value: mode, isExpanded: true, items: modes.map((x)=>DropdownMenuItem(value:x.key, child: Text(x.label, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>mode=v!), decoration: const InputDecoration(labelText:'Mode'))),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField<String>(value: pos, items: ['all','ST','LW','RW','CAM','CM','CDM','LB','RB','CB','GK'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>pos=v!), decoration: const InputDecoration(labelText:'Poste'))),
      ]),
      const SizedBox(height: 12),
      ...rows.take(80).map((x)=>Card(child: ListTile(leading: PlayerAvatar(p:x.p), title: Text(x.p.name), subtitle: Text('${x.p.team} • ${x.p.pos} • ${x.p.accel}'), trailing: Text('${x.sc}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF86EFAC)))))),
    ]);
  }
}


class TeamVsTeamPage extends StatefulWidget {
  final List<TeamInfo> teams;
  final List<Player> players;
  const TeamVsTeamPage({super.key, required this.teams, required this.players});
  @override State<TeamVsTeamPage> createState()=>_TeamVsTeamPageState();
}
class _TeamVsTeamPageState extends State<TeamVsTeamPage> {
  TeamInfo? a,b;
  @override Widget build(BuildContext context) {
    a ??= widget.teams.isNotEmpty ? widget.teams.first : null;
    b ??= widget.teams.length > 1 ? widget.teams[1] : a;
    final ta=a, tb=b;
    if(ta==null || tb==null) return const Center(child: Text('Aucune équipe'));
    final modesLine = [
      ('Attack', ta.attack, tb.defense),
      ('Midfield', ta.midfield, tb.midfield),
      ('Defense', ta.defense, tb.attack),
      ('Overall', ta.overall, tb.overall),
    ];
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Team vs Team', 'Compare deux équipes comme dans le plugin'),
      Row(children:[
        Expanded(child: DropdownButtonFormField<String>(value:ta.id, isExpanded:true, items:widget.teams.take(400).map((t)=>DropdownMenuItem(value:t.id, child:Text(t.name, overflow:TextOverflow.ellipsis))).toList(), onChanged:(id)=>setState(()=>a=widget.teams.firstWhere((t)=>t.id==id)), decoration: const InputDecoration(labelText:'Équipe A'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value:tb.id, isExpanded:true, items:widget.teams.take(400).map((t)=>DropdownMenuItem(value:t.id, child:Text(t.name, overflow:TextOverflow.ellipsis))).toList(), onChanged:(id)=>setState(()=>b=widget.teams.firstWhere((t)=>t.id==id)), decoration: const InputDecoration(labelText:'Équipe B'))),
      ]),
      const SizedBox(height:12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('${ta.name} vs ${tb.name}', style: const TextStyle(fontSize:22, fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        ...modesLine.map((x){
          final diff=x.$2-x.$3;
          return ListTile(dense:true, contentPadding:EdgeInsets.zero, title:Text(x.$1), subtitle:LinearProgressIndicator(value:(x.$2/(x.$2+x.$3).clamp(1,999))), trailing:Text('${x.$2} - ${x.$3}  ${diff>0?"+":""}$diff', style:TextStyle(fontWeight:FontWeight.w900, color:diff>=0?const Color(0xFF86EFAC):const Color(0xFFFB7185))));
        }),
      ]))),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Expanded(child: TeamMiniAnalysis(team:ta, players:widget.players)),
        const SizedBox(width:8),
        Expanded(child: TeamMiniAnalysis(team:tb, players:widget.players)),
      ]),
    ]);
  }
}
class TeamMiniAnalysis extends StatelessWidget {
  final TeamInfo team; final List<Player> players;
  const TeamMiniAnalysis({super.key, required this.team, required this.players});
  @override Widget build(BuildContext context) {
    final squad=players.where((p)=>p.team==team.name).take(5).toList();
    return ProBox(title:team.name, subtitle:'OVR ${team.overall} • ${team.manager}', icon:Icons.shield, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Wrap(spacing:6, runSpacing:6, children:[...team.strongTraits.take(3).map((x)=>Chip(label:Text('Strong $x'))), ...team.weakTraits.take(2).map((x)=>Chip(label:Text('Weak $x')))]),
      ...squad.map((p)=>ListTile(dense:true, contentPadding:EdgeInsets.zero, leading:PlayerAvatar(p:p, size:36), title:Text(p.name, maxLines:1), trailing:Text('${p.ovr}'))),
    ]));
  }
}

class TacticalIdeasPage extends StatefulWidget {
  final List<Player> players;
  final List<TacticalIdea> ideas;
  final ValueChanged<List<TacticalIdea>> onSave;
  const TacticalIdeasPage({super.key, required this.players, required this.ideas, required this.onSave});
  @override State<TacticalIdeasPage> createState()=>_TacticalIdeasPageState();
}
class _TacticalIdeasPageState extends State<TacticalIdeasPage> {
  late List<TacticalIdea> ideas;
  final name=TextEditingController(), desc=TextEditingController(), raw=TextEditingController();
  String mode='speed_long';
  @override void initState(){super.initState(); ideas=List<TacticalIdea>.from(widget.ideas);}
  void saveIdea(){
    final idea=TacticalIdea(id:'idea_${DateTime.now().millisecondsSinceEpoch}', name:name.text.trim().isEmpty?'Nouvelle tactique':name.text.trim(), mode:mode, description:desc.text.trim(), json:raw.text.trim().isEmpty?'{}':raw.text.trim());
    setState(()=>ideas.insert(0,idea));
    widget.onSave(ideas);
    name.clear(); desc.clear(); raw.clear();
  }
  @override Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Banque tactique', 'Créer, stocker et exporter des idées tactiques'),
      ProBox(title:'Nouvelle idée', subtitle:'Sauvegarde locale durant la session', icon:Icons.add, child:Column(children:[
        TextField(controller:name, decoration: const InputDecoration(labelText:'Nom')),
        const SizedBox(height:8),
        DropdownButtonFormField<String>(value:mode, items:modes.map((m)=>DropdownMenuItem(value:m.key, child:Text(m.label))).toList(), onChanged:(v)=>setState(()=>mode=v!), decoration: const InputDecoration(labelText:'Mode lié')),
        const SizedBox(height:8),
        TextField(controller:desc, decoration: const InputDecoration(labelText:'Description')),
        const SizedBox(height:8),
        TextField(controller:raw, minLines:2, maxLines:5, decoration: const InputDecoration(labelText:'JSON animation / notes')),
        const SizedBox(height:10),
        FilledButton.icon(onPressed:saveIdea, icon: const Icon(Icons.save), label: const Text('Sauvegarder idée')),
      ])),
      ...ideas.map((i)=>ProBox(title:i.name, subtitle:i.mode, icon:Icons.auto_awesome_motion_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(i.description.isEmpty?'—':i.description),
        const SizedBox(height:8),
        Text(i.json, style: const TextStyle(color:Color(0xFFB7C9E8), fontSize:12)),
      ]))),
    ]);
  }
}


class FormationBuilderPage extends StatefulWidget {
  final List<Player> players;
  const FormationBuilderPage({super.key, required this.players});
  @override State<FormationBuilderPage> createState()=>_FormationBuilderPageState();
}
class _FormationBuilderPageState extends State<FormationBuilderPage> {
  FormationPreset preset = formationPresets.first;
  late Map<String, Offset> spots;
  String selectedTeam = 'all';

  @override void initState() {
    super.initState();
    spots = Map<String, Offset>.from(preset.spots);
  }

  @override Widget build(BuildContext context) {
    final teams = ['all', ...widget.players.map((p)=>p.team).where((t)=>t!='—').toSet().take(200)];
    final list = widget.players.where((p)=>selectedTeam=='all'||p.team==selectedTeam).take(16).toList();
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Formation Builder', 'Drag & drop joueurs/postes sur le terrain'),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(value:preset.name, items: formationPresets.map((f)=>DropdownMenuItem(value:f.name, child:Text(f.name))).toList(), onChanged:(v){setState((){preset=formationPresets.firstWhere((f)=>f.name==v); spots=Map<String,Offset>.from(preset.spots);});}, decoration: const InputDecoration(labelText:'Formation'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value:selectedTeam, isExpanded:true, items:teams.map((t)=>DropdownMenuItem(value:t, child:Text(t, overflow:TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>selectedTeam=v!), decoration: const InputDecoration(labelText:'Équipe'))),
      ]),
      const SizedBox(height:12),
      AspectRatio(aspectRatio:1.55, child: LayoutBuilder(builder:(context,c){
        return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: const Color(0xFF146C43), border: Border.all(color: Colors.white54)), child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: PitchLinesPainter())),
          ...spots.entries.map((e){
            final p = list.isNotEmpty ? list[spots.keys.toList().indexOf(e.key) % list.length] : null;
            return Positioned(
              left: e.value.dx*c.maxWidth-28, top: e.value.dy*c.maxHeight-28,
              child: Draggable<String>(
                data:e.key,
                feedback: Material(color:Colors.transparent, child: _formationDot(e.key, p, true)),
                childWhenDragging: Opacity(opacity:.35, child:_formationDot(e.key,p,false)),
                child: DragTarget<String>(
                  onAccept:(from){setState((){final a=spots[from]!; spots[from]=spots[e.key]!; spots[e.key]=a;});},
                  builder:(_,__,___)=>_formationDot(e.key,p,false),
                ),
              ),
            );
          }),
        ]));
      })),
      const SizedBox(height:12),
      ProBox(title:'Export formation JSON', subtitle:'Copie simple de la structure', icon:Icons.code, child: SelectableText(jsonEncode(spots.map((k,v)=>MapEntry(k, {'x':v.dx,'y':v.dy}))))),
    ]);
  }
  Widget _formationDot(String pos, Player? p, bool big) => Container(width: big?70:58, height: big?70:58, decoration: BoxDecoration(shape:BoxShape.circle, gradient: const LinearGradient(colors:[Color(0xFF38BDF8),Color(0xFF22C55E)]), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.25), blurRadius:12)]), child: Center(child: Text(pos, textAlign:TextAlign.center, style: const TextStyle(fontWeight:FontWeight.w900, color:Colors.white, fontSize:11))));
}

class PitchLinesPainter extends CustomPainter {
  @override void paint(Canvas c, Size s) {
    final line=Paint()..color=Colors.white70..style=PaintingStyle.stroke..strokeWidth=2;
    c.drawRect(Rect.fromLTWH(18,18,s.width-36,s.height-36), line);
    c.drawLine(Offset(s.width/2,18), Offset(s.width/2,s.height-18), line);
    c.drawCircle(Offset(s.width/2,s.height/2), 42, line);
    c.drawRect(Rect.fromLTWH(18,s.height*.30,s.width*.16,s.height*.40), line);
    c.drawRect(Rect.fromLTWH(s.width-s.width*.16-18,s.height*.30,s.width*.16,s.height*.40), line);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class HistoryPage extends StatelessWidget {
  final List<Map<String,dynamic>> history;
  const HistoryPage({super.key, required this.history});
  @override Widget build(BuildContext context)=>ListView(padding: const EdgeInsets.all(14), children:[
    Header('Historique analyses', '${history.length} comparaisons sauvegardées'),
    if(history.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun historique. Sauvegarde une comparaison depuis la page Comparateur.'))),
    ...history.map((h)=>Card(child: ListTile(
      leading: const Icon(Icons.history),
      title: Text('${h['a']} vs ${h['b']}'),
      subtitle: Text('${h['mode']} • gagnant: ${h['winner']}'),
      trailing: Text('${h['scoreA']} - ${h['scoreB']}', style: const TextStyle(fontWeight:FontWeight.w900, color:Color(0xFF86EFAC))),
    ))),
  ]);
}


class PlayStyleDetectorPage extends StatefulWidget {
  final List<Player> players;
  const PlayStyleDetectorPage({super.key, required this.players});
  @override State<PlayStyleDetectorPage> createState()=>_PlayStyleDetectorPageState();
}
class _PlayStyleDetectorPageState extends State<PlayStyleDetectorPage> {
  Player? player;
  String q='';
  @override Widget build(BuildContext context) {
    player ??= widget.players.first;
    final p=player!;
    final detected=detectFc24PlayStyles(p);
    final query=q.toLowerCase().trim();
    final results=widget.players.where((x)=>query.isEmpty || ('${x.name} ${x.team} ${x.pos}').toLowerCase().contains(query)).take(80).toList();
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Détection PlayStyles FC24', 'Heuristique basée sur les attributs, sans modifier les traits legacy'),
      ProBox(title:'Joueur analysé', subtitle:'Choisis un joueur pour voir les PlayStyles probables', icon:Icons.person_search_rounded, child:Column(children:[
        TextField(decoration: const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'Rechercher joueur...'), onChanged:(v)=>setState(()=>q=v)),
        const SizedBox(height:8),
        SizedBox(height:180, child: ListView(children:results.map((x)=>PlayerTile(p:x, onTap:()=>setState(()=>player=x))).toList())),
      ])),
      ProBox(title:p.name, subtitle:'${p.team} • ${p.pos} • OVR ${p.ovr}', icon:Icons.bolt_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Wrap(spacing:8, runSpacing:8, children:[
          Chip(label:Text(p.body)), Chip(label:Text(p.accel)), Chip(label:Text('${p.height}cm')), Chip(label:Text('${p.weight}kg')),
        ]),
        const Divider(),
        Text('PlayStyles existants dans DB', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900)),
        Wrap(spacing:8, runSpacing:8, children:p.playstyles.isEmpty?[const Chip(label:Text('Aucun'))]:p.playstyles.map((x)=>Chip(label:Text(x))).toList()),
        const Divider(),
        Text('Détection FC24 ajoutée', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900)),
        ...detected.map((d)=>ListTile(
          contentPadding:EdgeInsets.zero,
          title:Text(d.name),
          subtitle:Text(d.reason),
          trailing:Text('${d.confidence}%', style:TextStyle(fontWeight:FontWeight.w900, color:d.confidence>=85?const Color(0xFF86EFAC):const Color(0xFFFACC15))),
        )),
        const SizedBox(height:8),
        const Text('Note : formule heuristique. Elle détecte les PlayStyles FC24 à partir des stats. Les traits legacy ne sont pas modifiés.', style: TextStyle(color:Color(0xFFB7C9E8))),
      ])),
      ProBox(title:'Formule utilisée', subtitle:'Exemple de logique', icon:Icons.functions_rounded, child: const Text('Exemple Rapid+ = Sprint Speed 45% + Acceleration 25% + Stamina 15% + OVR 15%. Seuil conseillé : 82%+ pour PlayStyle probable.')),
    ]);
  }
}

class CoachNotebookPage extends StatefulWidget {
  const CoachNotebookPage({super.key});
  @override State<CoachNotebookPage> createState()=>_CoachNotebookPageState();
}
class _CoachNotebookPageState extends State<CoachNotebookPage> {
  final title=TextEditingController(), content=TextEditingController();
  String category='Idée tactique';
  final notes=<Map<String,String>>[
    {'category':'Idée tactique','title':'ST attaque espace CB-LB','content':'Chercher passe en profondeur quand le CB sort sur le CAM.'},
    {'category':'Observation joueur','title':'RW explosif vs LB lourd','content':'Utiliser dribble court + crochet intérieur.'},
    {'category':'Plan match','title':'Contre 5-3-2','content':'Attirer côté puis switch rapide vers l’ailier opposé.'},
  ];

  void save(){
    if(title.text.trim().isEmpty && content.text.trim().isEmpty) return;
    setState(() {
      notes.insert(0, {'category':category, 'title':title.text.trim().isEmpty?'Note sans titre':title.text.trim(), 'content':content.text.trim()});
      title.clear(); content.clear();
    });
  }

  @override Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Carnet entraîneur', 'Notes, plans match, observations et idées tactiques'),
      ProBox(title:'Nouvelle note', subtitle:'Simple et rapide pendant analyse', icon:Icons.edit_note_rounded, child:Column(children:[
        DropdownButtonFormField<String>(value:category, items:['Idée tactique','Observation joueur','Plan match','À tester','Erreur à corriger'].map((x)=>DropdownMenuItem(value:x, child:Text(x))).toList(), onChanged:(v)=>setState(()=>category=v!), decoration: const InputDecoration(labelText:'Catégorie')),
        const SizedBox(height:8),
        TextField(controller:title, decoration: const InputDecoration(labelText:'Titre')),
        const SizedBox(height:8),
        TextField(controller:content, minLines:3, maxLines:6, decoration: const InputDecoration(labelText:'Contenu')),
        const SizedBox(height:10),
        FilledButton.icon(onPressed:save, icon: const Icon(Icons.save), label: const Text('Ajouter au carnet')),
      ])),
      ...notes.map((n)=>ProBox(title:n['title']!, subtitle:n['category']!, icon:Icons.sticky_note_2_rounded, child:Text(n['content']!))),
    ]);
  }
}

class ExportImportPage extends StatefulWidget {
  final List<Player> players;
  final List<TeamInfo> teams;
  final List<TacticalIdea> ideas;
  final void Function(List<Player>, List<TeamInfo>, List<TacticalIdea>) onImport;
  const ExportImportPage({super.key, required this.players, required this.teams, required this.ideas, required this.onImport});
  @override State<ExportImportPage> createState()=>_ExportImportPageState();
}
class _ExportImportPageState extends State<ExportImportPage> {
  final box=TextEditingController();
  String exportJson(){
    return jsonEncode({
      'players': widget.players.where((p)=>p.id.startsWith('custom_')||p.id.startsWith('local_')).map((p)=>p.toLocalJson()).toList(),
      'teams': widget.teams.where((t)=>t.id.startsWith('custom_')||t.id.startsWith('local_')).map((t)=>t.toLocalJson()).toList(),
      'ideas': widget.ideas.map((i)=>i.toJson()).toList(),
    });
  }
  void doImport(){
    try{
      final m=jsonDecode(box.text) as Map<String,dynamic>;
      final ps=[...widget.players];
      final ts=[...widget.teams];
      final ideas=(m['ideas'] as List? ?? []).map((e)=>TacticalIdea.fromJson(Map<String,dynamic>.from(e))).toList();
      for(final e in (m['players'] as List? ?? [])){
        final p=PlayerJsonExt.fromLocalJson(Map<String,dynamic>.from(e));
        final idx=ps.indexWhere((x)=>x.id==p.id); if(idx>=0) ps[idx]=p; else ps.insert(0,p);
      }
      for(final e in (m['teams'] as List? ?? [])){
        final t=TeamJsonExt.fromLocalJson(Map<String,dynamic>.from(e));
        final idx=ts.indexWhere((x)=>x.id==t.id); if(idx>=0) ts[idx]=t; else ts.insert(0,t);
      }
      widget.onImport(ps,ts,ideas);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import terminé')));
    }catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('JSON invalide: $e')));}
  }
  @override Widget build(BuildContext context)=>ListView(padding: const EdgeInsets.all(14), children:[
    Header('Export / Import JSON', 'Sauvegarde custom players, teams et tactiques'),
    FilledButton.icon(onPressed:()=>setState(()=>box.text=exportJson()), icon: const Icon(Icons.download), label: const Text('Générer export JSON')),
    const SizedBox(height:10),
    TextField(controller:box, minLines:12, maxLines:24, decoration: const InputDecoration(labelText:'JSON export/import')),
    const SizedBox(height:10),
    FilledButton.icon(onPressed:doImport, icon: const Icon(Icons.upload), label: const Text('Importer JSON')),
  ]);
}

class TacticalPage extends StatelessWidget {
  final Player a,b; final Mode mode;
  const TacticalPage({super.key, required this.a, required this.b, required this.mode});
  @override Widget build(BuildContext context) {
    final sa=score(a,mode), sb=score(b,mode), win=sa.total>=sb.total?a:b;
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Terrain tactique', '${mode.label} • gagnant : ${win.name}'),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: AspectRatio(aspectRatio: 1.55, child: CustomPaint(painter: PitchPainter(a.name,b.name,sa.total>=sb.total,mode.key))))),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('Animation simplifiée : ligne de course/passe, zone chaude et gagnant mis en évidence.'))),
    ]);
  }
}
class PitchPainter extends CustomPainter {
  final String a,b,mode; final bool aWin;
  PitchPainter(this.a,this.b,this.aWin,this.mode);
  @override void paint(Canvas c, Size s) {
    final bg=Paint()..color=const Color(0xFF146C43); final line=Paint()..color=Colors.white70..style=PaintingStyle.stroke..strokeWidth=2;
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero&s, const Radius.circular(22)), bg);
    c.drawRect(Rect.fromLTWH(18,18,s.width-36,s.height-36), line); c.drawLine(Offset(s.width/2,18),Offset(s.width/2,s.height-18),line); c.drawCircle(Offset(s.width/2,s.height/2),42,line);
    Offset pa=Offset(s.width*.35,s.height*.55), pb=Offset(s.width*.65,s.height*.48), ball=Offset(s.width*.50,s.height*.50);
    if(mode.contains('speed')) {pa=Offset(s.width*.32,s.height*.48); pb=Offset(s.width*.56,s.height*.50); ball=Offset(s.width*.78,s.height*.40);}
    if(mode.contains('aerial')) {pa=Offset(s.width*.62,s.height*.38); pb=Offset(s.width*.70,s.height*.52); ball=Offset(s.width*.72,s.height*.47);}
    if(mode.contains('press')) {pa=Offset(s.width*.38,s.height*.52); pb=Offset(s.width*.58,s.height*.50); ball=Offset(s.width*.50,s.height*.53);}
    c.drawLine(pa, ball, Paint()..color=const Color(0xFFFACC15)..strokeWidth=4);
    c.drawLine(pb, ball, Paint()..color=Colors.white70..strokeWidth=3);
    drawP(c,pa,a.substring(0,min(2,a.length)).toUpperCase(),aWin,const Color(0xFF38BDF8));
    drawP(c,pb,b.substring(0,min(2,b.length)).toUpperCase(),!aWin,const Color(0xFFFB7185));
    c.drawCircle(ball,8,Paint()..color=Colors.white);
  }
  void drawP(Canvas c, Offset o, String t, bool win, Color col){c.drawCircle(o,win?27:23,Paint()..color=col); if(win)c.drawCircle(o,36,Paint()..color=const Color(0xFF22C55E).withOpacity(.25)); final tp=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout(); tp.paint(c,o-Offset(tp.width/2,tp.height/2));}
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>true;
}

/* === v8.2 build-fix minimal fallback classes === */
class TeamsPage extends StatelessWidget {
  final List<TeamInfo> teams;
  final List<Player> players;
  final ValueChanged<TeamInfo> onEditTeam;
  const TeamsPage({super.key, required this.teams, required this.players, required this.onEditTeam});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      Header('Teams Database', '${teams.length} équipes'),
      ...teams.take(120).map((t) => TeamCard(team: t, players: players, onEdit: () => onEditTeam(t))),
    ],
  );
}

class TeamCard extends StatelessWidget {
  final TeamInfo team;
  final List<Player> players;
  final VoidCallback onEdit;
  const TeamCard({super.key, required this.team, required this.players, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    final squad = players.where((p) => p.team == team.name).take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            IconButton.filledTonal(onPressed: onEdit, icon: const Icon(Icons.edit)),
          ]),
          Text('Manager: ${team.manager}'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: MiniScore('OVR', team.overall, 'team')),
            const SizedBox(width: 8),
            Expanded(child: MiniScore('ATT', team.attack, 'attack')),
            const SizedBox(width: 8),
            Expanded(child: MiniScore('DEF', team.defense, 'def')),
          ]),
          if (squad.isNotEmpty) const Divider(),
          ...squad.map((p) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: PlayerAvatar(p: p, size: 36),
            title: Text(p.name),
            subtitle: Text('${p.pos} • OVR ${p.ovr}'),
          )),
        ]),
      ),
    );
  }
}


/* === v8.3 full CRUD/content constants === */
const fc24PlayStylesList = ["Finesse shot", "Chip shot", "Power shot", "Dead ball", "Precision header", "Acrobatic", "Low driven shot", "Gamechanger", "Incisive pass", "Pinged pass", "Long ball pass", "Tiki taka", "Whipped pass", "Inventive", "Jockey", "Block", "Intercept", "Anticipate", "Slide tackle", "Aerial fortress", "Technical", "Rapid", "First touch", "Trickster", "Press proven", "Quick step", "Relentless", "Long throw", "Bruiser", "Enforcer", "Far throw", "Footwork", "Cross claimer", "Rush out", "Far reach", "Deflector", "Solid player", "Team player", "One club player", "Injury prone", "Leadership"];
const fc24PlayStylesPlusList = ["Finesse shot +", "Chip shot +", "Power shot +", "Dead ball +", "Precision header +", "Acrobatic +", "Low driven shot +", "Gamechanger +", "Incisive pass +", "Pinged pass +", "Long ball pass +", "Tiki taka +", "Whipped pass +", "Inventive +", "Jockey +", "Block +", "Intercept +", "Anticipate +", "Slide tackle +", "Aerial fortress +", "Technical +", "Rapid +", "First touch +", "Trickster +", "Press proven +", "Quick step +", "Relentless +", "Long throw +", "Bruiser +", "Enforcer +", "Far throw +", "Footwork +", "Cross claimer +", "Rush out +", "Far reach +", "Deflector +", "Solid player +", "Team player +", "One club player +", "Injury prone +", "Leadership +"];
const fc24SpecialitiesList = ["Poacher", "Speedster", "Aerial threat", "Dribbler", "Playmaker", "Engine", "Distance shooter", "Crosser", "FK Specialist", "Tackling", "Tactician", "Acrobat", "Strength", "Clinical finisher", "Complete defender", "Complete midfielder", "Complete forward"];

class ChipMultiSelect extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;
  const ChipMultiSelect({super.key, required this.title, required this.options, required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: options.map((x) {
      final selected = values.contains(x);
      return FilterChip(
        selected: selected,
        label: Text(x),
        onSelected: (v) {
          final next = Set<String>.from(values);
          if (v) next.add(x); else next.remove(x);
          onChanged(next);
        },
      );
    }).toList()),
  ]);
}

class ProStatEditor extends StatelessWidget {
  final Map<String, TextEditingController> ctrls;
  const ProStatEditor({super.key, required this.ctrls});
  @override
  Widget build(BuildContext context) {
    final groups = {
      'Pace / Dribble': ['acc','sprint','agi','bal','react','ball','drib'],
      'Physical / Defense': ['str','agg','stam','jump','defaw','tackle','slide','inter'],
      'Attack / Passing': ['finish','shot','longshot','comp','head','cross','shortp','longp','vision','curve','fk'],
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: groups.entries.map((g) => ExpansionTile(
      initiallyExpanded: g.key == 'Pace / Dribble',
      title: Text(g.key, style: const TextStyle(fontWeight: FontWeight.w900)),
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: g.value.map((k) => SizedBox(
          width: 96,
          child: TextField(
            controller: ctrls[k],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: labelStat(k)),
          ),
        )).toList()),
        const SizedBox(height: 8),
      ],
    )).toList());
  }
}


class PlayerCrudPage extends StatefulWidget {
  final List<Player> players;
  final ValueChanged<Player> onSave;
  const PlayerCrudPage({super.key, required this.players, required this.onSave});
  @override State<PlayerCrudPage> createState()=>_PlayerCrudPageState();
}
class _PlayerCrudPageState extends State<PlayerCrudPage> {
  Player? editing;
  String q = '';

  @override
  Widget build(BuildContext context) {
    final query = q.toLowerCase().trim();
    final rows = widget.players.where((p)=>query.isEmpty || ('${p.name} ${p.team} ${p.pos}').toLowerCase().contains(query)).take(80).toList();
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('CRUD Players Pro', 'Édition complète : identité, stats, PlayStyles, PlayStyles+, spécialités'),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Rechercher joueur à modifier...'), onChanged:(v)=>setState(()=>q=v)),
      const SizedBox(height: 10),
      PlayerFormPro(initial: editing, onSave: (p){
        widget.onSave(p);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joueur sauvegardé localement')));
      }),
      const SizedBox(height: 14),
      ProBox(title:'Sélection rapide DB', subtitle:'Clique pour charger dans le formulaire', icon: Icons.manage_search_rounded, child: Column(children: rows.map((p)=>PlayerTile(p:p, onTap:()=>setState(()=>editing=p))).toList())),
    ]);
  }
}

class PlayerFormPro extends StatefulWidget {
  final Player? initial;
  final ValueChanged<Player> onSave;
  const PlayerFormPro({super.key, required this.initial, required this.onSave});
  @override State<PlayerFormPro> createState()=>_PlayerFormProState();
}
class _PlayerFormProState extends State<PlayerFormPro> {
  final name=TextEditingController(), team=TextEditingController(), pos=TextEditingController(), pos2=TextEditingController(), image=TextEditingController();
  final ovr=TextEditingController(), pot=TextEditingController(), h=TextEditingController(), w=TextEditingController(), skill=TextEditingController(), wf=TextEditingController();
  final Map<String, TextEditingController> statCtrls = {};
  String body='Average', accel='Controlled', foot='Right', attWr='Medium', defWr='Medium';
  Set<String> playstyles = {};
  Set<String> playstylesPlus = {};
  Set<String> specialities = {};

  @override void initState(){super.initState(); for(final k in ['acc','sprint','str','agg','bal','agi','react','ball','drib','defaw','tackle','slide','inter','finish','shot','longshot','comp','stam','jump','head','cross','shortp','longp','vision','curve','fk']){statCtrls[k]=TextEditingController();} fill();}
  @override void didUpdateWidget(covariant PlayerFormPro oldWidget){super.didUpdateWidget(oldWidget); fill();}

  void fill(){
    final p=widget.initial;
    name.text=p?.name??''; team.text=p?.team??''; pos.text=p?.pos??'ST'; pos2.text=p?.pos2??''; image.text=p?.image??'';
    ovr.text='${p?.ovr??80}'; pot.text='${p?.pot??80}'; h.text='${p?.height??180}'; w.text='${p?.weight??75}'; skill.text='${p?.skill??3}'; wf.text='${p?.weakFoot??3}';
    body=p?.body??'Average'; accel=p?.accel??'Controlled'; foot=p?.foot??'Right'; attWr=p?.attWr??'Medium'; defWr=p?.defWr??'Medium';
    for(final e in statCtrls.entries){e.value.text='${p?.s[e.key]??75}';}
    final ps = p?.playstyles ?? [];
    playstyles = ps.where((x)=>fc24PlayStylesList.contains(x)).toSet();
    playstylesPlus = ps.where((x)=>fc24PlayStylesPlusList.contains(x)).toSet();
    specialities = ps.where((x)=>fc24SpecialitiesList.contains(x)).toSet();
    // keep unknown custom styles in PlayStyles normal list visually impossible; they remain in DB if not edited
  }

  @override
  Widget build(BuildContext context) {
    return ProBox(title: widget.initial == null ? 'Nouveau joueur' : 'Édition : ${widget.initial!.name}', subtitle:'Formulaire complet mobile', icon: Icons.person_add_alt_1_rounded, child: Column(children:[
      Row(children:[
        Expanded(child: TextField(controller:name, decoration: const InputDecoration(labelText:'Nom joueur'))),
        const SizedBox(width:8),
        SizedBox(width:98, child: TextField(controller:ovr, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'OVR'))),
        const SizedBox(width:8),
        SizedBox(width:98, child: TextField(controller:pot, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'POT'))),
      ]),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child: TextField(controller:team, decoration: const InputDecoration(labelText:'Équipe'))),
        const SizedBox(width:8),
        Expanded(child: TextField(controller:pos, decoration: const InputDecoration(labelText:'Poste principal'))),
        const SizedBox(width:8),
        Expanded(child: TextField(controller:pos2, decoration: const InputDecoration(labelText:'Postes secondaires'))),
      ]),
      const SizedBox(height:8),
      TextField(controller:image, decoration: const InputDecoration(labelText:'Image URL / asset')),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child: TextField(controller:h, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Taille cm'))),
        const SizedBox(width:8),
        Expanded(child: TextField(controller:w, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Poids kg'))),
        const SizedBox(width:8),
        Expanded(child: TextField(controller:skill, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Skill Moves'))),
        const SizedBox(width:8),
        Expanded(child: TextField(controller:wf, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Weak Foot'))),
      ]),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child: DropdownButtonFormField<String>(value:body, isExpanded:true, items:['Lean','Average','Stocky','High & Lean','High & Average','High & Stocky','Unique'].map((x)=>DropdownMenuItem(value:x, child:Text(x))).toList(), onChanged:(v)=>setState(()=>body=v!), decoration: const InputDecoration(labelText:'Body Type'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value:accel, isExpanded:true, items:['Explosive','Mostly Explosive','Controlled','Controlled Lengthy','Lengthy','Mostly Lengthy'].map((x)=>DropdownMenuItem(value:x, child:Text(x))).toList(), onChanged:(v)=>setState(()=>accel=v!), decoration: const InputDecoration(labelText:'AcceleRATE'))),
      ]),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child: DropdownButtonFormField<String>(value:foot, items:['Right','Left'].map((x)=>DropdownMenuItem(value:x, child:Text(x))).toList(), onChanged:(v)=>setState(()=>foot=v!), decoration: const InputDecoration(labelText:'Foot'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value:attWr, items:['Low','Medium','High'].map((x)=>DropdownMenuItem(value:x, child:Text(x))).toList(), onChanged:(v)=>setState(()=>attWr=v!), decoration: const InputDecoration(labelText:'Att WR'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value:defWr, items:['Low','Medium','High'].map((x)=>DropdownMenuItem(value:x, child:Text(x))).toList(), onChanged:(v)=>setState(()=>defWr=v!), decoration: const InputDecoration(labelText:'Def WR'))),
      ]),
      const SizedBox(height:12),
      ExpansionTile(title: const Text('Stats détaillées', style: TextStyle(fontWeight: FontWeight.w900)), initiallyExpanded:false, children:[ProStatEditor(ctrls: statCtrls)]),
      const SizedBox(height:10),
      ExpansionTile(title: const Text('PlayStyles', style: TextStyle(fontWeight: FontWeight.w900)), children:[ChipMultiSelect(title:'PlayStyles FC24', options:fc24PlayStylesList, values:playstyles, onChanged:(v)=>setState(()=>playstyles=v))]),
      ExpansionTile(title: const Text('PlayStyles+', style: TextStyle(fontWeight: FontWeight.w900)), children:[ChipMultiSelect(title:'PlayStyles+ FC24', options:fc24PlayStylesPlusList, values:playstylesPlus, onChanged:(v)=>setState(()=>playstylesPlus=v))]),
      ExpansionTile(title: const Text('Player Specialities', style: TextStyle(fontWeight: FontWeight.w900)), children:[ChipMultiSelect(title:'Specialities', options:fc24SpecialitiesList, values:specialities, onChanged:(v)=>setState(()=>specialities=v))]),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:save, icon: const Icon(Icons.save), label: const Text('Sauvegarder joueur complet')),
    ]));
  }

  void save(){
    final base=widget.initial;
    final stats=<String,int>{};
    for(final e in statCtrls.entries){stats[e.key]=int.tryParse(e.value.text)??75;}
    widget.onSave(Player(
      id: base?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.text.trim().isEmpty?'Custom Player':name.text.trim(),
      team: team.text.trim().isEmpty?'Custom':team.text.trim(),
      pos: pos.text.trim().isEmpty?'ST':pos.text.trim(),
      pos2: pos2.text.trim(),
      image: image.text.trim(),
      ovr: int.tryParse(ovr.text)??80,
      pot: int.tryParse(pot.text)??int.tryParse(ovr.text)??80,
      height: int.tryParse(h.text)??180,
      weight: int.tryParse(w.text)??75,
      body: body,
      accel: accel,
      foot: foot,
      attWr: attWr,
      defWr: defWr,
      skill: int.tryParse(skill.text)??3,
      weakFoot: int.tryParse(wf.text)??3,
      playstyles: [...playstyles, ...playstylesPlus, ...specialities],
      s: stats,
    ));
  }
}


class TeamCrudPage extends StatefulWidget {
  final List<TeamInfo> teams;
  final ValueChanged<TeamInfo> onSave;
  const TeamCrudPage({super.key, required this.teams, required this.onSave});
  @override State<TeamCrudPage> createState()=>_TeamCrudPageState();
}
class _TeamCrudPageState extends State<TeamCrudPage> {
  TeamInfo? editing;
  String q='';
  @override
  Widget build(BuildContext context) {
    final query=q.toLowerCase().trim();
    final rows=widget.teams.where((t)=>query.isEmpty||('${t.name} ${t.manager}').toLowerCase().contains(query)).take(80).toList();
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('CRUD Teams Pro', 'Édition équipe : notes, forces/faiblesses, XI, valeurs globales'),
      TextField(decoration: const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'Rechercher équipe...'), onChanged:(v)=>setState(()=>q=v)),
      const SizedBox(height:10),
      TeamFormPro(initial:editing, onSave:(t){widget.onSave(t); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Team sauvegardée localement')));}),
      const SizedBox(height:14),
      ProBox(title:'Sélection équipes DB', subtitle:'Clique pour charger dans le formulaire', icon:Icons.shield_rounded, child:Column(children:rows.map((t)=>Card(child:ListTile(title:Text(t.name), subtitle:Text('OVR ${t.overall} • ${t.manager}'), trailing: const Icon(Icons.edit), onTap:()=>setState(()=>editing=t)))).toList())),
    ]);
  }
}

class TeamFormPro extends StatefulWidget {
  final TeamInfo? initial;
  final ValueChanged<TeamInfo> onSave;
  const TeamFormPro({super.key, required this.initial, required this.onSave});
  @override State<TeamFormPro> createState()=>_TeamFormProState();
}
class _TeamFormProState extends State<TeamFormPro> {
  final name=TextEditingController(), manager=TextEditingController(), ovr=TextEditingController(), att=TextEditingController(), mid=TextEditingController(), def=TextEditingController(), strong=TextEditingController(), weak=TextEditingController(), equal=TextEditingController(), xi=TextEditingController(), notes=TextEditingController();
  @override void initState(){super.initState(); fill();}
  @override void didUpdateWidget(covariant TeamFormPro oldWidget){super.didUpdateWidget(oldWidget); fill();}
  void fill(){final t=widget.initial; name.text=t?.name??''; manager.text=t?.manager??''; ovr.text='${t?.overall??80}'; att.text='${t?.attack??80}'; mid.text='${t?.midfield??80}'; def.text='${t?.defense??80}'; strong.text=(t?.strongTraits??[]).join(', '); weak.text=(t?.weakTraits??[]).join(', '); equal.text=(t?.equalTraits??[]).join(', '); xi.text=(t?.xi??[]).join(', '); notes.text='';}
  @override
  Widget build(BuildContext context)=>ProBox(title:widget.initial==null?'Nouvelle équipe':'Édition : ${widget.initial!.name}', subtitle:'Formulaire team complet', icon:Icons.add_business_rounded, child:Column(children:[
    Row(children:[Expanded(child:TextField(controller:name, decoration: const InputDecoration(labelText:'Nom équipe'))), const SizedBox(width:8), Expanded(child:TextField(controller:manager, decoration: const InputDecoration(labelText:'Manager')))]),
    const SizedBox(height:8),
    Row(children:[
      Expanded(child:TextField(controller:ovr, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'OVR'))),
      const SizedBox(width:8), Expanded(child:TextField(controller:att, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'Attack'))),
      const SizedBox(width:8), Expanded(child:TextField(controller:mid, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'Midfield'))),
      const SizedBox(width:8), Expanded(child:TextField(controller:def, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'Defense'))),
    ]),
    const SizedBox(height:8),
    TextField(controller:strong, decoration: const InputDecoration(labelText:'Forces / strong traits séparés par virgule')),
    const SizedBox(height:8),
    TextField(controller:weak, decoration: const InputDecoration(labelText:'Faiblesses / weak traits séparés par virgule')),
    const SizedBox(height:8),
    TextField(controller:equal, decoration: const InputDecoration(labelText:'Traits équilibrés séparés par virgule')),
    const SizedBox(height:8),
    TextField(controller:xi, decoration: const InputDecoration(labelText:'XI / joueurs clés séparés par virgule')),
    const SizedBox(height:8),
    TextField(controller:notes, minLines:3, maxLines:5, decoration: const InputDecoration(labelText:'Notes coach / tactique')),
    const SizedBox(height:12),
    FilledButton.icon(onPressed:save, icon: const Icon(Icons.save), label: const Text('Sauvegarder équipe complète')),
  ]));

  void save(){
    widget.onSave(TeamInfo(
      id: widget.initial?.id ?? 'custom_team_${DateTime.now().millisecondsSinceEpoch}',
      name: name.text.trim().isEmpty?'Custom Team':name.text.trim(),
      manager: manager.text.trim().isEmpty?'—':manager.text.trim(),
      overall:int.tryParse(ovr.text)??80,
      attack:int.tryParse(att.text)??80,
      midfield:int.tryParse(mid.text)??80,
      defense:int.tryParse(def.text)??80,
      citylikeScore: widget.initial?.citylikeScore??0,
      weakTraits: weak.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),
      equalTraits: equal.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),
      strongTraits: strong.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),
      xi: xi.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),
    ));
  }
}


Future<void> showTeamEditor(BuildContext context, TeamInfo team) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(team.name),
      content: SizedBox(width: 680, child: SingleChildScrollView(child: TeamFormPro(initial: team, onSave: (_) => Navigator.pop(context)))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
    ),
  );
}

class ModesGuidePage extends StatelessWidget {
  const ModesGuidePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      Header('Guide modes & matchups', 'Explication des situations'),
      ...modes.map((m) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(m.desc),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: m.w.entries.map((e) => Chip(label: Text('${labelStat(e.key)} ${(e.value * 100).round()}%'))).toList()),
          ]),
        ),
      )),
    ],
  );
}
