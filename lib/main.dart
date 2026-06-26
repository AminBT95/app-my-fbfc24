import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class AppTheme {
  // V21 — design system audit fix: high contrast, football premium, fewer weak icons/colors.
  static const bg = Color(0xFF020817);
  static const card = Color(0xFF071225);
  static const surface = Color(0xFF0B1B31);
  static const ink = Color(0xFFF8FAFC);
  static const muted = Color(0xFF9FB2CC);
  static const pink = Color(0xFF14B881); // legacy alias used by old widgets -> now emerald
  static const purple = Color(0xFF2F80FF);
  static const blue = Color(0xFF2F80FF);
  static const dark = Color(0xFF071225);
  static const line = Color(0xFF243B55);
  static const green = Color(0xFF38D996);
  static const pitch = Color(0xFF0B7A44);
  static const navy = Color(0xFF071225);
  static const orange = Color(0xFFFFC857);
  static const danger = Color(0xFFFF5D73);
  static const chip = Color(0xFF10243A);
  static const darkText = Color(0xFF071225);
}


class Fc24HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => host.contains('eep-fifa.de');
    return client;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = Fc24HttpOverrides();
  FlutterError.onError = (details) => FlutterError.presentError(details);
  runZonedGuarded(() => runApp(const FC24CoachApp()), (error, stack) {
    debugPrint('FC24 Coach AI crash: $error');
  });
}

class FC24CoachApp extends StatelessWidget {
  const FC24CoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FC24 Coach AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bg,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.purple, brightness: Brightness.dark).copyWith(
          primary: AppTheme.pink,
          secondary: AppTheme.purple,
          surface: AppTheme.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.bg,
          foregroundColor: AppTheme.ink,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(color: AppTheme.ink, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        cardTheme: CardTheme(
          color: AppTheme.card,
          elevation: 0,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: const BorderSide(color: AppTheme.line)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.surface,
          labelStyle: const TextStyle(color: AppTheme.muted),
          hintStyle: const TextStyle(color: AppTheme.muted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.pink, width: 1.4)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppTheme.dark,
          indicatorColor: AppTheme.pink.withOpacity(.18),
          labelTextStyle: MaterialStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppTheme.chip,
          selectedColor: AppTheme.pink.withOpacity(.22),
          side: const BorderSide(color: AppTheme.line),
          labelStyle: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700),
        ),
      ),
      home: AppShell(key: appShellKey),
    );
  }
}

class Player {
  final String id, name, team, teamId, pos, pos2, body, accel, foot, attWr, defWr, image;
  final int ovr, pot, height, weight, skill, weakFoot, gender;
  final List<String> playstyles;
  final Map<String, int> s;

  const Player({
    required this.id, required this.name, required this.team, this.teamId = '', required this.pos, required this.pos2,
    required this.image,
    required this.ovr, required this.pot, required this.height, required this.weight,
    required this.body, required this.accel, required this.foot, required this.attWr, required this.defWr,
    required this.skill, required this.weakFoot, this.gender = 0, required this.playstyles, required this.s,
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
      'vision': n(j['vision']), 'curve': n(j['curve']), 'fk': n(j['fk']), 'posi': n(j['positioning']), 'attpos': n(j['positioning']), 'volleys': n(j['volleys']), 'penalties': n(j['penalties']),
      'marking': n(j['marking'], n(j['defaw'])), 'block': n(j['blocking'], n(j['defaw'])), 'recovery': n(j['reactions']), 'workrate': n(j['stamina']),
      'gkdiv': n(j['gkdiving']), 'gkhan': n(j['gkhandling']), 'gkkick': n(j['gkkicking']), 'gkpos': n(j['gkpositioning']), 'gkref': n(j['gkreflexes']),
    };
    final ps = <String>[
      ...list(j['playstyles']).map(normalizePlayStyle).where((x)=>x.isNotEmpty),
      ...list(j['trait1Decoded']).map(normalizeTrait).where((x)=>x.isNotEmpty),
      ...list(j['trait2Decoded']).map(normalizeTrait).where((x)=>x.isNotEmpty),
      ...inferPlaystyles(stats, str(j['pos']), str(j['pos2'])),
    ].where((x) => x.trim().isNotEmpty && !RegExp(r'^\d+$').hasMatch(x.trim())).toSet().toList();

    return Player(
      id: str(j['id']),
      name: str(j['name'], 'Player'),
      image: str(j['image']),
      team: str(j['team'], '—'),
      teamId: str(j['teamid'], str(j['teamId'])),
      pos: str(j['pos'], 'N/A'),
      pos2: str(j['pos2']),
      ovr: n(j['ovr']),
      pot: n(j['pot']),
      height: n(j['height'], 180),
      weight: n(j['weight'], 75),
      body: decodeBody(str(j['bodytype'])),
      accel: guessAccel(stats, n(j['height'], 180), n(j['weight'], 75)),
      foot: str(j['foot']) == '2' ? 'Left' : 'Right',
      attWr: decodeWr(str(j['attWR'], str(j['attWr']))),
      defWr: decodeWr(str(j['defWR'], str(j['defWr']))),
      skill: n(j['skill']),
      weakFoot: n(j['weakfoot']),
      gender: n(j['gender'], 0),
      playstyles: ps,
      s: stats,
    );
  }

  static String normalizePlayStyle(String v) {
    var t = v.trim();
    if (t.isEmpty || t == '0' || t == 'null' || RegExp(r'^\d+$').hasMatch(t)) return '';
    t = t.replaceAll('_', ' ').replaceAll('-', ' ');
    final plus = t.contains('+');
    t = t.replaceAll('+', '').trim().toLowerCase();
    const map = {
      'finesse shot':'Finesse Shot','chip shot':'Chip Shot','power shot':'Power Shot','dead ball':'Dead Ball','power header':'Power Header','precision header':'Power Header','acrobatic':'Acrobatic','incisive pass':'Incisive Pass','pinged pass':'Pinged Pass','long ball pass':'Long Ball Pass','tiki taka':'Tiki Taka','whipped pass':'Whipped Pass','jockey':'Jockey','block':'Block','intercept':'Intercept','anticipate':'Anticipate','slide tackle':'Slide Tackle','aerial':'Aerial','aerial fortress':'Aerial','technical':'Technical','rapid':'Rapid','first touch':'First Touch','trickster':'Trickster','press proven':'Press Proven','quick step':'Quick Step','relentless':'Relentless','long throw':'Long Throw','bruiser':'Bruiser','far throw':'Far Throw','footwork':'Footwork','cross claimer':'Cross Claimer','rush out':'Rush Out','far reach':'Far Reach','deflector':'Deflector'
    };
    final out = map[t] ?? t.split(' ').where((w)=>w.isNotEmpty).map((w)=>w[0].toUpperCase()+w.substring(1)).join(' ');
    return plus ? '$out+' : out;
  }

  static String normalizeTrait(String v) {
    final t = v.trim();
    if (t.isEmpty || t == '0' || t == 'null' || RegExp(r'^\d+$').hasMatch(t)) return '';
    const map = {
      'Play Maker':'Playmaker Trait','Injury Free':'Injury Free Trait','Injury Prone':'Injury Prone Trait','Solid Player':'Solid Player Trait','Team Player':'Team Player Trait','Leadership':'Leadership Trait','One Club Player':'One Club Player Trait','Flair':'Flair Trait','Power Header':'Power Header Trait','Giant Throw-in':'Giant Throw-in Trait','Long Throw-in':'Long Throw-in Trait','Pushes Up For Corners':'Pushes Up For Corners','Comes For Crosses':'Comes For Crosses','Rushes Out Of Goal':'Rushes Out Of Goal','Saves with Feet':'Saves With Feet','Cautious With Crosses':'Cautious With Crosses','Stutter Penalty':'Stutter Penalty'
    };
    return map[t] ?? t;
  }

  static List<String> inferPlaystyles(Map<String,int> s, String pos, String pos2) {
    final out = <String>[];
    void add(String x){ if(!out.contains(x)) out.add(x); }
    final p='${pos.toUpperCase()} ${pos2.toUpperCase()}';
    if ((s['finish']??0)>=88 && (s['curve']??0)>=82) add('Finesse Shot');
    if ((s['shot']??0)>=88) add('Power Shot');
    if ((s['vision']??0)>=87 && (s['shortp']??0)>=86) add('Incisive Pass');
    if ((s['longp']??0)>=88) add('Long Ball Pass');
    if ((s['shortp']??0)>=88 && (s['ball']??0)>=86) add('Tiki Taka');
    if ((s['cross']??0)>=86) add('Whipped Pass');
    if ((s['defaw']??0)>=86 && (s['inter']??0)>=84) add('Intercept');
    if ((s['tackle']??0)>=86 && (s['defaw']??0)>=84) add('Anticipate');
    if ((s['slide']??0)>=84) add('Slide Tackle');
    if ((s['drib']??0)>=88 && (s['agi']??0)>=86) add('Technical');
    if ((s['sprint']??0)>=90) add('Rapid');
    if ((s['acc']??0)>=90) add('Quick Step');
    if ((s['ball']??0)>=88 && (s['react']??0)>=86) add('First Touch');
    if ((s['stam']??0)>=88) add('Relentless');
    if ((s['str']??0)>=86 && (s['agg']??0)>=78) add('Bruiser');
    if ((s['jump']??0)>=86 && (s['head']??0)>=82) add('Aerial');
    if (p.contains('GK')) { if((s['gkref']??0)>=84) add('Far Reach'); if((s['gkkick']??0)>=84) add('Far Throw'); if((s['gkpos']??0)>=84) add('Rush Out'); }
    return out;
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
    'id': id, 'name': name, 'team': team, 'teamId': teamId, 'pos': pos, 'pos2': pos2, 'image': image,
    'ovr': ovr, 'pot': pot, 'height': height, 'weight': weight, 'body': body, 'accel': accel,
    'foot': foot, 'attWr': attWr, 'defWr': defWr, 'skill': skill, 'weakFoot': weakFoot, 'gender': gender,
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
      teamId: str(j['teamId']),
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
      gender: n(j['gender'], 0),
      playstyles: Player.list(j['playstyles']),
      s: stats.isEmpty ? {'acc':75,'sprint':75,'str':75,'agg':70,'bal':75,'agi':75,'react':75,'ball':75,'drib':75,'defaw':60,'tackle':60,'inter':60,'finish':75,'shot':75,'comp':75,'stam':75,'jump':75,'head':70,'cross':70,'shortp':70,'longp':70,'vision':70} : stats,
    );
  }
}

extension PlayerCopyExt on Player {
  Player copyWith({String? team, String? teamId, String? pos, String? pos2}) => Player(
    id: id,
    name: name,
    team: team ?? this.team,
    teamId: teamId ?? this.teamId,
    pos: pos ?? this.pos,
    pos2: pos2 ?? this.pos2,
    image: image,
    ovr: ovr,
    pot: pot,
    height: height,
    weight: weight,
    body: body,
    accel: accel,
    foot: foot,
    attWr: attWr,
    defWr: defWr,
    skill: skill,
    weakFoot: weakFoot,
    gender: gender,
    playstyles: playstyles,
    s: s,
  );
}

extension TeamCopyExt on TeamInfo {
  TeamInfo copyWith({List<String>? xi, String? name, String? manager}) => TeamInfo(
    id: id,
    name: name ?? this.name,
    manager: manager ?? this.manager,
    overall: overall,
    attack: attack,
    midfield: midfield,
    defense: defense,
    citylikeScore: citylikeScore,
    weakTraits: weakTraits,
    equalTraits: equalTraits,
    strongTraits: strongTraits,
    xi: xi ?? this.xi,
  );
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
    final custom = players.map((p)=>p.toLocalJson()).toList();
    final f = await _file('players.json');
    await f.writeAsString(jsonEncode(custom));
  }

  static Future<void> saveCustomTeams(List<TeamInfo> teams) async {
    final custom = teams.map((t)=>t.toLocalJson()).toList();
    final f = await _file('teams.json');
    await f.writeAsString(jsonEncode(custom));
  }

  static Future<void> saveTempFormations(Map<String, String> formations) async {
    final f = await _file('temp_formations.json');
    await f.writeAsString(jsonEncode(formations));
  }

  static Future<Map<String, String>> loadTempFormations() async {
    try {
      final f = await _file('temp_formations.json');
      if (!f.existsSync()) return {};
      final raw = jsonDecode(await f.readAsString()) as Map;
      return raw.map((k,v)=>MapEntry(k.toString(), v.toString()));
    } catch (_) { return {}; }
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

  String get _digits => RegExp(r'\d+').firstMatch(p.id)?.group(0) ?? '';
  String get _url {
    final explicit = p.image.trim();
    if (explicit.startsWith('http')) return explicit;
    if (_digits.isNotEmpty) return 'https://eep-fifa.de/Minifaces/p$_digits.png';
    return explicit;
  }

  @override
  Widget build(BuildContext context) {
    final img = _url;
    final initials = p.name.startsWith('Player ') ? '#${_digits.isEmpty ? '?' : _digits.substring(max(0, _digits.length-3))}' : p.name.trim().split(RegExp(r'\s+')).where((x)=>x.isNotEmpty).take(2).map((x)=>x[0].toUpperCase()).join();
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors:[Color(0xFF14243A), Color(0xFF0B1728)]),
        border: Border.all(color: AppTheme.line, width: 2.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0,4))],
      ),
      child: Center(child: Text(initials.isEmpty ? '?' : initials, textAlign: TextAlign.center, style: TextStyle(fontSize: size * .23, fontWeight: FontWeight.w900, color: AppTheme.ink))),
    );
    if (img.isEmpty) return fallback;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: AppTheme.line, width: 1.5)),
      child: ClipOval(
        child: img.startsWith('http')
            ? Image.network(
                img,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                headers: const {'User-Agent':'Mozilla/5.0 (Android) AppleWebKit/537.36','Accept':'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8','Referer':'https://eep-fifa.de/generic.html'},
                loadingBuilder: (c,w,progress)=>progress==null?w:Stack(fit:StackFit.expand, children:[fallback, Center(child:SizedBox(width:size*.28,height:size*.28,child:const CircularProgressIndicator(strokeWidth:2)))]),
                errorBuilder: (_, __, ___) => fallback,
              )
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
            Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600, height: 1.25)),
          ])),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    ),
  );
}



class UxTabSection extends StatelessWidget {
  final List<String> tabs;
  final List<Widget> children;
  final double height;
  const UxTabSection({super.key, required this.tabs, required this.children, this.height = 520});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: tabs.length,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.line)),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          unselectedLabelColor: AppTheme.muted,
          tabs: tabs.map((t)=>Tab(text:t)).toList(),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: height,
        child: TabBarView(children: children.map((w)=>SingleChildScrollView(child:w)).toList()),
      ),
    ]),
  );
}

class QuickSearchHeader extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;
  final bool filtersOpen;
  const QuickSearchHeader({super.key, this.hint='Recherche rapide...', this.onChanged, this.onFilter, this.filtersOpen=false});
  @override
  Widget build(BuildContext context)=>Row(children:[
    Expanded(child:TextField(decoration:InputDecoration(prefixIcon:const Icon(Icons.search), hintText:hint), onChanged:onChanged)),
    const SizedBox(width:8),
    FilledButton.tonalIcon(onPressed:onFilter, icon:Icon(filtersOpen?Icons.expand_less_rounded:Icons.tune_rounded), label:Text(filtersOpen?'Filtres':'Filtres')),
  ]);
}

void showUxDetailModal(BuildContext context, String title, List<Widget> sections) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .95,
      builder: (context, ctrl) => Container(
        decoration: const BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: ListView(controller: ctrl, padding: const EdgeInsets.all(16), children: [
          Container(width:52,height:5,margin:const EdgeInsets.only(bottom:14),decoration:BoxDecoration(color:AppTheme.line,borderRadius:BorderRadius.circular(99))),
          Header(title, 'Détail IA • explication • impact • conseils'),
          ...sections,
        ]),
      ),
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
  FormationPreset('4-4-2', {
    'GK': Offset(.08,.50),'LB': Offset(.24,.22),'CB1': Offset(.24,.42),'CB2': Offset(.24,.58),'RB': Offset(.24,.78),
    'LM': Offset(.48,.22),'CM1': Offset(.48,.42),'CM2': Offset(.48,.58),'RM': Offset(.48,.78),'ST1': Offset(.76,.42),'ST2': Offset(.76,.58),
  }),
  FormationPreset('4-1-2-1-2', {
    'GK': Offset(.08,.50),'LB': Offset(.23,.23),'CB1': Offset(.23,.42),'CB2': Offset(.23,.58),'RB': Offset(.23,.77),
    'CDM': Offset(.42,.50),'CM1': Offset(.52,.33),'CM2': Offset(.52,.67),'CAM': Offset(.65,.50),'ST1': Offset(.82,.40),'ST2': Offset(.82,.60),
  }),
  FormationPreset('3-4-2-1', {
    'GK': Offset(.08,.50),'CB1': Offset(.25,.32),'CB2': Offset(.23,.50),'CB3': Offset(.25,.68),
    'LM': Offset(.45,.18),'CM1': Offset(.45,.42),'CM2': Offset(.45,.58),'RM': Offset(.45,.82),'LF': Offset(.66,.36),'RF': Offset(.66,.64),'ST': Offset(.82,.50),
  }),
  FormationPreset('3-5-2', {
    'GK': Offset(.08,.50),'CB1': Offset(.24,.32),'CB2': Offset(.22,.50),'CB3': Offset(.24,.68),
    'LM': Offset(.45,.18),'CDM': Offset(.43,.50),'RM': Offset(.45,.82),'CAM1': Offset(.62,.38),'CAM2': Offset(.62,.62),'ST1': Offset(.82,.42),'ST2': Offset(.82,.58),
  }),
  FormationPreset('5-3-2', {
    'GK': Offset(.08,.50),'LWB': Offset(.25,.18),'CB1': Offset(.24,.36),'CB2': Offset(.24,.50),'CB3': Offset(.24,.64),'RWB': Offset(.25,.82),
    'CM1': Offset(.50,.35),'CM2': Offset(.48,.50),'CM3': Offset(.50,.65),'ST1': Offset(.76,.42),'ST2': Offset(.76,.58),
  }),
  FormationPreset('5-2-1-2', {
    'GK': Offset(.08,.50),'LWB': Offset(.25,.18),'CB1': Offset(.24,.36),'CB2': Offset(.24,.50),'CB3': Offset(.24,.64),'RWB': Offset(.25,.82),
    'CM1': Offset(.48,.42),'CM2': Offset(.48,.58),'CAM': Offset(.62,.50),'ST1': Offset(.78,.42),'ST2': Offset(.78,.58),
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
      xi: (() {
        final rawXi = j['xi'];
        if (rawXi is List) {
          return rawXi.map((e) {
            if (e is Map) return Player.str(e['id']);
            return Player.str(e);
          }).where((id) => id.isNotEmpty && id != '0').toList();
        }
        return split(rawXi);
      })(),
    );
  }
}


bool isHiddenTeamName(String name, {bool showWomen = false, bool showSoccerAid = false}) {
  final n = name.toLowerCase();
  if (!showWomen && (n.contains('women') || n.contains('female') || n.contains('fémin') || n.contains('femin'))) return true;
  if (!showSoccerAid && (n.contains('soccer aid') || n.contains('classic xi') || n.contains('adidas') || n.contains('world xi'))) return true;
  return false;
}

bool isHiddenPlayer(Player p, {bool showWomen = false, bool showSoccerAid = false}) {
  final t = p.team.toLowerCase();
  final n = p.name.toLowerCase();
  if (!showWomen && p.gender != 0) return true;
  if (!showWomen && (t.contains('women') || t.contains('female') || n.contains('women'))) return true;
  if (!showSoccerAid && (t.contains('soccer aid') || t.contains('classic xi') || t.contains('adidas') || t.contains('world xi'))) return true;
  return false;
}

List<TeamInfo> cleanTeamList(List<TeamInfo> teams, {bool showWomen = false, bool showSoccerAid = false}) {
  final list = teams.where((t)=>!isHiddenTeamName(t.name, showWomen: showWomen, showSoccerAid: showSoccerAid)).toList();
  list.sort((a,b)=>a.name.compareTo(b.name));
  return list;
}

List<TeamInfo> cleanTeamListForPlayers(List<TeamInfo> teams, List<Player> players, {bool showWomen = false, bool showSoccerAid = false}) {
  final base = cleanTeamList(teams, showWomen: showWomen, showSoccerAid: showSoccerAid);
  final cleanPlayers = cleanPlayerList(players, showWomen: showWomen, showSoccerAid: showSoccerAid);
  bool hasVisiblePlayers(TeamInfo t) => cleanPlayers.any((p) {
    final sameId = t.id.isNotEmpty && p.teamId.isNotEmpty && p.teamId == t.id;
    final sameName = p.team == t.name;
    if(t.id.isNotEmpty && p.teamId.isNotEmpty) return sameId;
    return sameId || sameName;
  });
  final list = base.where(hasVisiblePlayers).toList();
  return list.isEmpty ? base : list;
}

List<Player> cleanPlayerList(List<Player> players, {bool showWomen = false, bool showSoccerAid = false}) {
  return players.where((p)=>!isHiddenPlayer(p, showWomen: showWomen, showSoccerAid: showSoccerAid)).toList();
}

void openPlayer(BuildContext context, Player p) => showPlayerDetails(context, p);

String coachStrengths(Player p) {
  final parts = <String>[];
  if ((p.s['pac']??0) >= 88) parts.add('vitesse/profondeur');
  if ((p.s['dri']??0) >= 86) parts.add('dribble court');
  if ((p.s['phy']??0) >= 82) parts.add('contact physique');
  if ((p.s['def']??0) >= 82) parts.add('lecture défensive');
  if ((p.s['pas']??0) >= 84) parts.add('passe qui casse les lignes');
  if ((p.s['sho']??0) >= 84) parts.add('finition/frappe');
  return parts.isEmpty ? 'profil équilibré, à utiliser selon le poste' : parts.join(', ');
}

String coachWeaknesses(Player p) {
  final parts = <String>[];
  if ((p.s['pac']??0) < 70) parts.add('attaquer sa vitesse');
  if ((p.s['phy']??0) < 65) parts.add('le mettre au contact');
  if ((p.s['def']??0) < 55 && !p.pos.contains('ST')) parts.add('le presser dans son dos');
  if ((p.s['stam']??0) < 70) parts.add('augmenter le tempo en fin de match');
  return parts.isEmpty ? 'pas de faiblesse claire, utiliser un plan spécifique' : parts.join(', ');
}

String teamCoachReport(TeamInfo t, List<Player> players) {
  final squad = _teamSquad(t, players).take(18).toList();
  final fast = squad.where((p)=>(p.s['pac']??0)>=85).length;
  final strong = squad.where((p)=>(p.s['phy']??0)>=80).length;
  final creators = squad.where((p)=>(p.s['pas']??0)>=84 || (p.s['vision']??0)>=84).length;
  final defenders = squad.where((p)=>(p.s['def']??0)>=82).length;
  return 'Forces : ${fast>=4?'vitesse élevée, ':''}${strong>=4?'impact physique, ':''}${creators>=3?'création entre les lignes, ':''}${defenders>=4?'bloc défensif solide, ':''}OVR ${t.overall}.\n'
         'Faiblesses à tester : transitions rapides si les latéraux montent, espace entre CB-LB/RB, pressing sur le premier relanceur.\n'
         'Comment profiter : attaque l’espace faible, isole ton meilleur dribbleur contre leur latéral, utilise cutback si leur bloc recule.\n'
         'Comment contrer : garde un CDM devant les CB, ferme les passes verticales, force le jeu côté faible.';
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
  Mode('shoulder', 'Épaule contre épaule', 'Duel', 'Contact direct, protection et gain du duel physique.', {'str':.34,'agg':.18,'bal':.15,'sprint':.10,'react':.10,'stam':.08,'jump':.05}),
  Mode('physical', 'Duel physique complet', 'Duel', 'Contact, stabilité, agressivité et animation de corps.', {'str':.32,'agg':.18,'bal':.16,'react':.12,'sprint':.08,'stam':.08,'jump':.06}),
  Mode('shield', 'Protéger ballon dos au but', 'Duel', 'Pivot, faux 9, sortie de balle sous pressing.', {'str':.26,'bal':.22,'ball':.18,'comp':.12,'react':.10,'agg':.07,'drib':.05}),
  Mode('speed_short', 'Vitesse courte 0-10m', 'Vitesse', 'Démarrage explosif, crochet, premier pas.', {'acc':.42,'sprint':.20,'agi':.14,'react':.12,'bal':.07,'stam':.05}),
  Mode('speed_long', 'Course longue 25m+', 'Vitesse', 'Appel profondeur, poursuite, transition.', {'sprint':.42,'acc':.22,'stam':.14,'str':.08,'react':.08,'agi':.06}),
  Mode('through_ball', 'Appel profondeur vs CB', 'Vitesse', 'ST lancé dans le dos contre défenseur central.', {'sprint':.28,'acc':.22,'react':.14,'finish':.10,'str':.08,'ball':.08,'stam':.06,'comp':.04}),
  Mode('dribble_wing', '1v1 aile / crochet', 'Attaque', 'Ailier contre latéral, crochet intérieur/extérieur.', {'agi':.24,'drib':.22,'acc':.18,'bal':.14,'ball':.12,'react':.10}),
  Mode('dribble_central', 'Dribble petits espaces', 'Attaque', 'CAM/ST entre les lignes, demi-tour, conduite serrée.', {'drib':.22,'ball':.22,'bal':.18,'agi':.17,'react':.13,'comp':.08}),
  Mode('dribble', 'Dribble 1v1 global', 'Attaque', 'Dribble général contre défenseur.', {'agi':.24,'drib':.22,'acc':.18,'bal':.14,'ball':.12,'react':.10}),
  Mode('tackle', 'Tacle debout / récupération', 'Défense', 'Défenseur qui attaque le ballon.', {'tackle':.28,'defaw':.24,'inter':.16,'react':.12,'str':.10,'agg':.10}),
  Mode('defense', 'Défense complète', 'Défense', 'Awareness, tacle, interception et contact.', {'tackle':.24,'defaw':.24,'inter':.18,'react':.13,'str':.11,'agg':.10}),
  Mode('jockey', 'Jockey défensif / contenir', 'Défense', 'Contenir sans se jeter, fermer l’angle.', {'defaw':.24,'agi':.20,'bal':.16,'tackle':.16,'react':.14,'acc':.10}),
  Mode('interception', 'Interception passe au sol', 'Lecture', 'Couper une ligne de passe ou défendre bloc bas.', {'inter':.32,'defaw':.24,'react':.16,'acc':.10,'vision':.08,'stam':.06,'shortp':.04}),
  Mode('pressing', 'Pressing / harcèlement', 'Pressing', 'Presser le porteur, contre-pressing, deuxième ballon.', {'stam':.22,'agg':.20,'acc':.18,'react':.14,'defaw':.10,'str':.08,'agi':.08}),
  Mode('pass_break', 'Casser ligne par passe', 'Passe', 'Passe verticale, bloc bas, troisième homme.', {'vision':.26,'shortp':.22,'longp':.20,'comp':.12,'react':.08,'ball':.08,'drib':.04}),
  Mode('crossing', 'Centre / cutback offensif', 'Passe', 'Centre depuis l’aile ou passe en retrait.', {'cross':.30,'vision':.16,'acc':.12,'drib':.12,'ball':.10,'stam':.08,'shortp':.07,'comp':.05}),
  Mode('cutback', 'Cutback attaque/défense', 'Zone', 'Passe en retrait, couverture de zone.', {'acc':.14,'drib':.14,'cross':.14,'vision':.12,'inter':.16,'defaw':.16,'react':.14}),
  Mode('cutback_def', 'Défendre cutback', 'Zone', 'Couper la passe en retrait dans la surface.', {'defaw':.30,'inter':.22,'react':.18,'acc':.10,'tackle':.10,'bal':.05,'stam':.05}),
  Mode('aerial', 'Duel aérien / centre', 'Aérien', 'Centre, corner, ballon long, deuxième poteau.', {'head':.28,'jump':.24,'str':.18,'react':.10,'agg':.08,'defaw':.06,'finish':.06}),
  Mode('finish', 'Finition sous pression', 'Tir', 'Face au but avec contact ou défense proche.', {'finish':.28,'comp':.22,'shot':.18,'react':.12,'ball':.08,'str':.06,'bal':.06}),
  Mode('finish_pressure', 'Finition sous forte pression', 'Tir', 'Tir rapide avec défenseur au contact.', {'finish':.30,'comp':.20,'shot':.18,'react':.12,'ball':.08,'bal':.07,'str':.05}),
  Mode('long_shot', 'Frappe de loin / puissance', 'Tir', 'Frappe de loin, Power Shot, finesse sous pression.', {'shot':.30,'comp':.18,'finish':.16,'ball':.10,'str':.08,'vision':.08,'react':.06,'bal':.04}),
  Mode('keeper_1v1', 'ST vs GK 1 contre 1', 'Gardien', 'Face-à-face attaquant/gardien.', {'finish':.26,'comp':.22,'react':.16,'ball':.12,'acc':.08,'drib':.08,'shot':.08}),
  Mode('gk_shot_stop', 'Gardien arrêt réflexe', 'Gardien', 'Comparer gardiens : réflexes, plongeon, placement.', {'gkref':.30,'gkdiv':.24,'gkpos':.18,'react':.14,'gkhan':.10,'str':.04}),
  Mode('gk_sweeper', 'Gardien libéro / sortie', 'Gardien', 'Sortie rapide, jeu long, couverture profondeur.', {'gkpos':.24,'gkref':.18,'gkkick':.18,'sprint':.12,'react':.12,'longp':.10,'gkhan':.06}),
  Mode('low_block_break', 'Casser bloc bas', 'IA Simulator', 'Vision, composure et passe incisive pour ouvrir un bloc bas.', {'vision':.28,'shortp':.22,'longp':.18,'comp':.14,'ball':.10,'drib':.08}),
  Mode('low_block_defend', 'Défendre bloc bas', 'IA Simulator', 'Placement, interceptions et blocage pour tenir une surface compacte.', {'defaw':.30,'inter':.22,'react':.16,'str':.10,'tackle':.10,'bal':.06,'stam':.06}),
  Mode('transition_attack', 'Transition offensive rapide', 'IA Simulator', 'Exploser après récupération : vitesse, conduite et passe longue.', {'sprint':.28,'acc':.22,'stam':.12,'ball':.12,'longp':.10,'vision':.08,'drib':.08}),
  Mode('transition_defense', 'Transition défensive / retour', 'IA Simulator', 'Retour défensif après perte, couverture profondeur et interceptions.', {'sprint':.26,'acc':.20,'stam':.18,'defaw':.14,'inter':.12,'react':.10}),
  Mode('wing_cross', 'Centre depuis l’aile', 'IA Simulator', 'Gagner le couloir et envoyer un centre/cutback précis.', {'cross':.32,'acc':.16,'drib':.14,'vision':.12,'ball':.10,'shortp':.08,'stam':.08}),
  Mode('box_header', 'Centre surface / tête', 'IA Simulator', 'Attaquer le centre dans la surface : timing, taille, tête, force.', {'head':.30,'jump':.24,'str':.16,'react':.10,'finish':.10,'agg':.06,'bal':.04}),
  Mode('hold_up_play', 'Pivot / dos au but', 'IA Simulator', 'Fixer le CB, protéger et remettre proprement.', {'str':.26,'bal':.22,'ball':.20,'comp':.12,'shortp':.08,'react':.07,'agg':.05}),
  Mode('first_touch_turn', 'Contrôle orienté + demi-tour', 'IA Simulator', 'Premier contrôle sous pression puis changement de direction.', {'ball':.30,'agi':.20,'bal':.18,'react':.14,'drib':.12,'comp':.06}),
  Mode('att_positioning', 'Positionnement offensif / appel', 'Poste vs poste', 'Attacking positioning, timing d’appel et présence zone dangereuse.', {'attpos':.30,'react':.18,'acc':.16,'finish':.14,'ball':.10,'comp':.08,'vision':.04}),
  Mode('marking_cover', 'Marquage + couverture', 'Poste vs poste', 'Défenseur qui suit appel, ferme angle et couvre la zone.', {'marking':.28,'defaw':.26,'inter':.16,'react':.12,'tackle':.10,'str':.08}),
  Mode('fb_vs_winger', 'Latéral vs ailier', 'Poste vs poste', 'RB/LB contre LW/RW : vitesse, jockey, tacle, centres coupés.', {'acc':.16,'sprint':.16,'defaw':.18,'tackle':.18,'agi':.12,'inter':.10,'stam':.10}),
  Mode('winger_vs_fb', 'Ailier vs latéral', 'Poste vs poste', 'LW/RW contre RB/LB : 1v1, crochet, accélération, centre/cutback.', {'acc':.20,'sprint':.16,'drib':.20,'agi':.16,'cross':.10,'ball':.10,'comp':.08}),
  Mode('st_vs_cb', 'BU vs défenseur central', 'Poste vs poste', 'ST/CF contre CB : profondeur, contact, finition et défense du dos.', {'sprint':.18,'acc':.15,'str':.16,'finish':.15,'attpos':.12,'react':.10,'head':.08,'comp':.06}),
  Mode('cb_vs_st', 'CB vs BU', 'Poste vs poste', 'CB contre ST/CF : marquage, contact, couverture profondeur, duel aérien.', {'defaw':.22,'marking':.20,'str':.16,'tackle':.14,'inter':.10,'sprint':.08,'head':.06,'react':.04}),
  Mode('cam_vs_cdm', 'CAM vs CDM', 'Poste vs poste', 'Créateur entre lignes contre sentinelle : vision, contrôle, interception.', {'vision':.20,'shortp':.18,'ball':.18,'drib':.12,'comp':.12,'react':.10,'inter':.06,'defaw':.04}),
  Mode('cdm_vs_cam', 'CDM vs CAM', 'Poste vs poste', 'Sentinelle contre meneur : interception, awareness, pressing et tacle.', {'inter':.24,'defaw':.22,'tackle':.16,'react':.12,'stam':.10,'agg':.08,'shortp':.08}),
  Mode('fullback_overlap', 'Overlap latéral', 'Poste vs poste', 'Latéral qui dédouble : volume, centre, vitesse et retour défensif.', {'stam':.20,'sprint':.18,'acc':.14,'cross':.18,'shortp':.10,'defaw':.10,'inter':.05,'react':.05}),
  Mode('inside_forward', 'Inside forward / rentrer pied fort', 'Poste vs poste', 'Ailier qui rentre intérieur pour tir/passe : dribble, finition, composure.', {'drib':.20,'agi':.16,'acc':.14,'finish':.18,'shot':.12,'comp':.10,'vision':.10}),
  Mode('gk_vs_st', 'GK vs ST face-à-face', 'Poste vs poste', 'Gardien face à attaquant : réflexes/positioning contre finition/composure.', {'gkref':.25,'gkpos':.20,'gkdiv':.16,'react':.14,'gkhan':.10,'sprint':.06,'comp':.05,'str':.04}),
  Mode('speed_0_5', 'Explosion 0-5m', 'Vitesse', 'Premier pas, sortie de contrôle et micro espace.', {'acc':.50,'agi':.16,'react':.14,'bal':.10,'sprint':.06,'stam':.04}),
  Mode('speed_10_20', 'Sprint 10-20m', 'Vitesse', 'Course lancée, appel profondeur et retour défensif.', {'sprint':.46,'acc':.18,'stam':.14,'str':.08,'react':.08,'agi':.06}),
  Mode('turning', 'Virage / changement direction', 'Attaque', 'Changer d’angle sans perdre la balle.', {'agi':.32,'bal':.24,'drib':.18,'ball':.12,'acc':.08,'react':.06}),
  Mode('first_control', 'Premier contrôle', 'Attaque', 'Réception sous pression, contrôle orienté et conservation.', {'ball':.34,'react':.20,'comp':.18,'drib':.12,'bal':.10,'agi':.06}),
  Mode('long_dribble', 'Conduite longue', 'Attaque', 'Porter le ballon en transition sans perdre vitesse.', {'sprint':.24,'drib':.22,'ball':.16,'acc':.14,'stam':.12,'agi':.08,'comp':.04}),
  Mode('short_pass_press', 'Passe courte sous pressing', 'Passe', 'Sortir d’un pressing par passe courte et sang froid.', {'shortp':.30,'comp':.20,'ball':.18,'vision':.16,'react':.10,'bal':.06}),
  Mode('long_switch', 'Switch longue diagonale', 'Passe', 'Renverser le jeu côté faible.', {'longp':.36,'vision':.24,'cross':.14,'comp':.12,'shot':.06,'shortp':.08}),
  Mode('through_pass', 'Passe profondeur', 'Passe', 'Trouver l’appel dans le dos.', {'vision':.32,'longp':.20,'shortp':.18,'comp':.14,'ball':.08,'react':.08}),
  Mode('press_resist', 'Résister au pressing', 'Pressing', 'Recevoir, protéger, ressortir sans perdre balle.', {'comp':.24,'ball':.22,'bal':.18,'str':.14,'shortp':.10,'react':.08,'drib':.04}),
  Mode('counter_press', 'Contre-pressing 5s', 'Pressing', 'Récupérer juste après perte.', {'stam':.26,'agg':.22,'acc':.18,'react':.14,'defaw':.10,'inter':.10}),
  Mode('second_ball', 'Deuxième ballon', 'Lecture', 'Gagner le ballon qui traîne après duel ou dégagement.', {'react':.24,'agg':.20,'inter':.18,'stam':.14,'bal':.10,'str':.08,'vision':.06}),
  Mode('block_shot', 'Tir vs bloc', 'Défense', 'Se placer pour bloquer la frappe.', {'defaw':.28,'react':.22,'block':.18,'inter':.12,'str':.08,'jump':.06,'tackle':.06}),
  Mode('cover_depth', 'Couverture profondeur', 'Défense', 'Gérer l’appel dans le dos sans casser la ligne.', {'defaw':.26,'sprint':.20,'inter':.16,'react':.14,'marking':.12,'str':.06,'acc':.06}),
  Mode('underlap', 'Underlap intérieur', 'Poste vs poste', 'Latéral/milieu attaque le demi-espace intérieur.', {'acc':.18,'stam':.18,'shortp':.16,'vision':.14,'ball':.12,'attpos':.12,'drib':.10}),
  Mode('overlap_cross', 'Overlap + centre', 'Poste vs poste', 'Dédoublement extérieur puis centre/cutback.', {'sprint':.20,'stam':.18,'cross':.22,'acc':.14,'shortp':.10,'drib':.08,'defaw':.08}),
  Mode('false_nine', 'Faux 9 entre lignes', 'Poste vs poste', 'Décrocher, combiner et attirer un CB.', {'vision':.22,'shortp':.20,'ball':.18,'comp':.14,'drib':.12,'attpos':.08,'react':.06}),
  Mode('target_man', 'Target man / point d’appui', 'Poste vs poste', 'Remise dos au but, jeu aérien, contact CB.', {'str':.24,'head':.20,'jump':.16,'ball':.12,'shortp':.10,'comp':.08,'agg':.06,'bal':.04}),
  Mode('wide_defense', 'Défendre couloir', 'Poste vs poste', 'Latéral ferme centre, crochet et profondeur.', {'defaw':.22,'tackle':.20,'acc':.16,'sprint':.14,'agi':.10,'inter':.10,'stam':.08}),
];

String labelStat(String k) => {
  'pac':'Pace','sho':'Shooting','pas':'Passing','dri':'Dribbling card','def':'Defending card','phy':'Physical card','acc':'Acceleration','sprint':'Sprint Speed','str':'Strength','agg':'Aggression','bal':'Balance','agi':'Agility','react':'Reactions',
  'ball':'Ball Control','drib':'Dribbling','defaw':'Def. Awareness','tackle':'Standing Tackle','slide':'Slide Tackle','inter':'Interceptions',
  'finish':'Finishing','shot':'Shot Power','longshot':'Long Shots','comp':'Composure','stam':'Stamina','jump':'Jumping','head':'Heading',
  'cross':'Crossing','shortp':'Short Passing','longp':'Long Passing','vision':'Vision','curve':'Curve','fk':'Free Kick','posi':'Att. Positioning','attpos':'Att. Positioning','marking':'Marking','recovery':'Recovery runs','workrate':'Work rate impact','volleys':'Volleys','penalties':'Penalties','block':'Block','gkdiv':'GK Diving','gkhan':'GK Handling','gkkick':'GK Kicking','gkpos':'GK Positioning','gkref':'GK Reflexes'
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
    'shoulder': {'Bruiser+':9,'Press Proven+':5,'Aerial+':3,'Block+':2},
    'shield': {'Press Proven+':9,'Bruiser+':6,'First Touch+':5,'Tiki Taka+':4,'Technical+':3},
    'speed_short': {'Quick Step+':10,'Rapid+':4,'Technical+':2},
    'speed_long': {'Rapid+':9,'Quick Step+':4,'Relentless+':3},
    'through_ball': {'Rapid+':8,'Quick Step+':5,'First Touch+':4,'Finesse+':3},
    'dribble': {'Technical+':9,'Trickster+':7,'First Touch+':5,'Press Proven+':4,'Quick Step+':4},
    'dribble_wing': {'Technical+':9,'Trickster+':7,'Rapid+':5,'Quick Step+':5,'Whipped Pass+':3},
    'dribble_central': {'Technical+':9,'First Touch+':7,'Trickster+':6,'Press Proven+':5,'Finesse+':3},
    'defense': {'Anticipate+':9,'Block+':7,'Jockey+':6,'Slide Tackle+':5,'Bruiser+':3,'Intercept+':4},
    'tackle': {'Anticipate+':9,'Slide Tackle+':7,'Jockey+':6,'Bruiser+':4,'Block+':3},
    'interception': {'Intercept+':9,'Anticipate+':5,'Block+':4,'Incisive Pass+':3,'Long Ball Pass+':2},
    'pressing': {'Relentless+':9,'Intercept+':7,'Bruiser+':4,'Anticipate+':4,'Press Proven+':3},
    'pass_break': {'Incisive Pass+':9,'Long Ball Pass+':8,'Tiki Taka+':7,'Whipped Pass+':6,'First Touch+':3},
    'crossing': {'Whipped Pass+':10,'Rapid+':4,'Technical+':4,'Tiki Taka+':3},
    'aerial': {'Aerial+':10,'Power Header+':9,'Bruiser+':4,'Anticipate+':3},
    'finish': {'Finesse+':8,'Power Shot+':8,'Aerial+':3,'First Touch+':3,'Technical+':2},
    'finish_pressure': {'Finesse+':8,'Power Shot+':8,'First Touch+':5,'Technical+':3,'Press Proven+':3},
    'long_shot': {'Power Shot+':10,'Finesse+':8,'Dead Ball+':3,'Technical+':2},
    'cutback': {'Whipped Pass+':6,'Intercept+':7,'Block+':5,'Technical+':4},
    'cutback_def': {'Intercept+':9,'Block+':8,'Anticipate+':7,'Jockey+':4},
    'jockey': {'Jockey+':8,'Anticipate+':6,'Block+':4},
    'keeper_1v1': {'Finesse+':6,'Power Shot+':6,'Quick Step+':4,'Rush Out+':8,'Far Throw+':2},
    'gk_shot_stop': {'Rush Out+':4,'Far Throw+':2},
    'gk_sweeper': {'Rush Out+':9,'Long Ball Pass+':7,'Far Throw+':5},
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
  'Tiki Taka+':'passe courte',
  'Rush Out+':'sortie gardien',
  'Far Throw+':'relance rapide gardien',
  'Dead Ball+':'coups de pied arrêtés'
}[ps] ?? 'impact situationnel';

final GlobalKey appShellKey = GlobalKey();

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
  Player? crudInitialPlayer;
  final Set<String> favoritePlayerIds = <String>{};
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
        final i = mergedPlayers.indexWhere((x)=>x.id == p.id);
        if (i >= 0) {
          mergedPlayers[i] = p;
        } else {
          mergedPlayers.insert(0, p);
        }
      }
      for (final t in savedTeams) {
        final i = mergedTeams.indexWhere((x)=>x.id == t.id);
        if (i >= 0) {
          mergedTeams[i] = t;
        } else {
          mergedTeams.insert(0, t);
        }
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

  void openCrudFromDetails(Player p) {
    setState(() { crudInitialPlayer = p; tab = 5; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Édition chargée : ${p.name}')));
  }

  void addFavoritePlayer(Player p) {
    setState(() => favoritePlayerIds.add(p.id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} ajouté aux favoris')));
  }

  void compareFromDetails(Player p) {
    setState(() {
      a = p;
      b ??= customPlayers.firstWhere((x)=>x.id != p.id, orElse: ()=>p);
      tab = 1;
    });
    Navigator.maybePop(context);
  }

  @override Widget build(BuildContext context) {
    final loaded = db;
    final pages = loaded == null ? <Widget>[] : [
      DashboardPage(db: GameDb(customPlayers, customTeams), onStart: ()=>setState(()=>tab=1), onGo:(i)=>setState(()=>tab=i)),
      ComparePage(players: customPlayers, a: a!, b: b!, mode: mode, onA:(p)=>setState(()=>a=p), onB:(p)=>setState(()=>b=p), onMode:(m)=>setState(()=>mode=m), onSaveHistory:(row) async { setState(()=>history.insert(0,row)); await LocalStore.saveHistory(history); }),
      DetectorPage(players: customPlayers, ref: a!, mode: mode),
      DatabasePage(players: customPlayers),
      TeamsPage(teams: customTeams, players: customPlayers, onEditTeam: (t)=>showTeamEditor(context, t)),
      PlayerCrudPage(players: customPlayers, initial: crudInitialPlayer, onSave: (p){
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
      TransferPlayerPage(players: customPlayers, teams: customTeams, onSave: (ps, ts) async {
        setState(() { customPlayers = ps; customTeams = ts; });
        await LocalStore.saveCustomPlayers(customPlayers);
        await LocalStore.saveCustomTeams(customTeams);
      }),
      StartingXIManagerPage(players: customPlayers, teams: customTeams, onSave: (ts) async {
        setState(() { customTeams = ts; });
        await LocalStore.saveCustomTeams(customTeams);
      }),
      TeamAnalyzerPage(teams: customTeams, players: customPlayers),
      V42TeamVsTeamProPage(teams: customTeams, players: customPlayers),
      ManagersCoachPage(teams: customTeams, players: customPlayers),
      FormationCounterEnginePage(teams: customTeams, players: customPlayers),
      SituationsCoachPage(players: customPlayers),
      StatsEncyclopediaPage(),
      DuelVisualsCrudPage(players: customPlayers),
      MatchupFinderPage(players: customPlayers),
      TacticalIdeasPage(players: customPlayers, ideas: tacticalIdeas, onSave: (ideas) async { setState(()=>tacticalIdeas = ideas); await LocalStore.saveIdeas(ideas); }),
      V42TacticalLabFullPage(initialA: a!, initialB: b!, initialMode: mode, players: customPlayers),
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
      AiSimulatorPage(players: customPlayers, teams: customTeams),
      TacticBoardAnimationStudioPage(players: customPlayers, teams: customTeams),
      SettingsPage(players: customPlayers, teams: customTeams, ideas: tacticalIdeas, history: history),
      V42ProfessionalWorkflowPage(players: customPlayers, teams: customTeams, onGo:(i)=>setState(()=>tab=i), onOpenPlayer:(p)=>showPlayerDetails(context,p)),
      V45FinalVipPolishPage(players: customPlayers, teams: customTeams, ideas: tacticalIdeas, history: history, onGo:(i)=>setState(()=>tab=i), onOpenPlayer:(p)=>showPlayerDetails(context,p)),
    ];

    return Scaffold(
      drawer: loaded == null ? null : AppDrawer(current: tab, onGo: go),
      appBar: AppBar(
        title: const Text('FC24 Coach AI Pro'),
        leading: loaded == null ? null : Builder(builder: (context)=>IconButton(icon: const Icon(Icons.menu_rounded), onPressed: ()=>Scaffold.of(context).openDrawer())),
        actions: [
          if (loaded != null) IconButton(
            tooltip: 'Recherche globale',
            icon: const Icon(Icons.manage_search_rounded),
            onPressed: ()=>showGlobalCommandSearch(context, customPlayers, customTeams, (i)=>setState(()=>tab=i)),
          ),
          if (loaded != null) Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: Text('${customPlayers.length} joueurs', style: const TextStyle(color: AppTheme.pink, fontWeight: FontWeight.w900)))),
        ],
      ),
      body: SafeArea(
        child: loaded == null
          ? StartLoader(error: error, onRetry: _load)
          : AnimatedSwitcher(duration: const Duration(milliseconds: 260), child: pages[tab]),
      ),
      floatingActionButton: loaded == null ? null : FloatingActionButton.extended(
        onPressed: ()=>showQuickActions(context, (i)=>setState(()=>tab=i)),
        icon: const Icon(Icons.bolt_rounded),
        label: const Text('Actions'),
      ),
      bottomNavigationBar: loaded == null ? null : NavigationBar(
        selectedIndex: [0,28,1,10,18,29].contains(tab) ? [0,28,1,10,18,29].indexOf(tab) : 0,
        onDestinationSelected: (i)=>setState(()=>tab = [0,28,1,10,18,29][i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.compare_arrows_rounded), label: 'Compare'),
          NavigationDestination(icon: Icon(Icons.shield_rounded), label: 'Teams'),
          NavigationDestination(icon: Icon(Icons.sports_soccer_rounded), label: 'Coach'),
          NavigationDestination(icon: Icon(Icons.workspace_premium_rounded), label: 'VIP'),
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
      (7, Icons.swap_horiz_rounded, 'Transfert joueur'),
      (8, Icons.format_list_numbered_rounded, 'Gérer XI départ'),
      (9, Icons.analytics_rounded, 'Team Analyzer'),
      (10, Icons.compare_rounded, 'Team vs Team'),
      (11, Icons.manage_accounts_rounded, 'Managers Coach'),
      (12, Icons.account_tree_rounded, 'Formation Counter'),
      (13, Icons.sports_soccer_rounded, 'Situations Coach'),
      (14, Icons.school_rounded, 'Football Knowledge'),
      (15, Icons.polyline_rounded, 'Duel Visuals CRUD'),
      (16, Icons.hub_rounded, 'Matchup Finder'),
      (17, Icons.auto_awesome_motion_rounded, 'Banque tactique'),
      (18, Icons.sports_soccer_rounded, 'Tactical Lab'),
      (19, Icons.grid_on_rounded, 'Formation Builder'),
      (20, Icons.history_rounded, 'Historique'),
      (21, Icons.bolt_rounded, 'Détection PlayStyles'),
      (22, Icons.edit_note_rounded, 'Carnet entraîneur'),
      (23, Icons.import_export_rounded, 'Export / Import'),
      (24, Icons.menu_book_rounded, 'Guide modes'),
      (25, Icons.auto_awesome_rounded, 'IA Simulator Pro'),
      (26, Icons.animation_rounded, 'Tactic Board Studio'),
      (27, Icons.settings_rounded, 'Paramètres / Backup'),
      (28, Icons.manage_search_rounded, 'Command Center Pro'),
      (29, Icons.workspace_premium_rounded, 'VIP Final Polish'),
    ];
    return Drawer(
      backgroundColor: AppTheme.dark,
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors:[Color(0xFF14B881), Color(0xFF2F80FF)])),
          child: const Row(children: [
            Icon(Icons.sports_soccer, color: Colors.white, size: 36),
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
  final ValueChanged<int>? onGo;
  const DashboardPage({super.key, required this.db, required this.onStart, this.onGo});
  @override Widget build(BuildContext context) {
    final top = cleanPlayerList(db.players).where((p)=>!p.name.startsWith('Player ')).take(8).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF13C28B), Color(0xFF236BFE), Color(0xFF071225)]),
          border: Border.all(color: Color(0xFF284766)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Coach AI Pro', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Comparaison joueur vs joueur, modes tactiques, détection des meilleurs profils, DB complète plugin.', style: TextStyle(color: Colors.white, height: 1.35)),
          const SizedBox(height: 16),
          Wrap(spacing:10, runSpacing:10, children:[
            FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow), label: const Text('Lancer comparaison')),
            OutlinedButton.icon(onPressed: ()=>onGo?.call(28), icon: const Icon(Icons.manage_search_rounded), label: const Text('Global Search')),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Kpi('Joueurs', '${db.players.length}', Icons.people_alt_rounded)),
        const SizedBox(width: 10),
        Expanded(child: Kpi('Équipes', '${db.teamCount}', Icons.shield_rounded)),
      ]),
      const SizedBox(height: 14),
      const UxAuditFixCard(),
      const SizedBox(height: 14),
      ProContentHub(onGo:onGo),
      const SizedBox(height: 14),
      Text('Top joueurs DB', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      ...top.map((p)=>PlayerTile(p: p, onTap:()=>openPlayer(context,p))),
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


class UxAuditFixCard extends StatelessWidget {
  const UxAuditFixCard({super.key});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppTheme.line),
    ),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children:[Icon(Icons.check_circle_rounded, color: AppTheme.green), SizedBox(width:8), Expanded(child: Text('UX audit appliqué', style: TextStyle(fontWeight: FontWeight.w900, fontSize:18)))]),
      SizedBox(height:8),
      Text('Navigation simplifiée, contraste renforcé, modules clés regroupés, joueurs/équipes cliquables, modes de comparaison centralisés.', style: TextStyle(color: AppTheme.muted, height:1.35, fontWeight:FontWeight.w700)),
    ]),
  );
}

class ProComparisonHero extends StatelessWidget {
  final Player a,b; final DuelScore sa,sb; final Mode mode;
  const ProComparisonHero({super.key, required this.a, required this.b, required this.sa, required this.sb, required this.mode});
  @override Widget build(BuildContext context) {
    final total=max(1, sa.total+sb.total), pa=(sa.total/total*100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[Color(0xFF073B82), Color(0xFF061426), Color(0xFF020617)]), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.25), blurRadius:28, offset:Offset(0,14))]),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Row(children:[
          Expanded(child:_heroPlayer(a, sa.total, true)),
          Container(padding: const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white.withOpacity(.12), borderRadius:BorderRadius.circular(18)), child: const Text('VS', style:TextStyle(fontWeight:FontWeight.w900))),
          Expanded(child:_heroPlayer(b, sb.total, false)),
        ]),
        const SizedBox(height:14),
        Text(mode.label, style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:18)),
        const SizedBox(height:8),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value:pa/100, minHeight:12, backgroundColor:Colors.white24)),
        const SizedBox(height:6),
        Text('${a.name} $pa% • ${b.name} ${100-pa}%', style: const TextStyle(color:Colors.white70)),
      ]),
    );
  }
  Widget _heroPlayer(Player p, int score, bool left)=>Column(crossAxisAlignment:left?CrossAxisAlignment.start:CrossAxisAlignment.end, children:[
    PlayerAvatar(p:p, size:88), const SizedBox(height:8),
    Text(p.name, maxLines:1, overflow:TextOverflow.ellipsis, textAlign:left?TextAlign.left:TextAlign.right, style: const TextStyle(color:Colors.white, fontSize:20, fontWeight:FontWeight.w900)),
    Text('${p.team} • ${p.pos}', maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(color:Colors.white70)),
    const SizedBox(height:6), Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:7), decoration:BoxDecoration(color:Colors.white.withOpacity(.14), borderRadius:BorderRadius.circular(999)), child:Text('$score pts • OVR ${p.ovr}', style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w800))),
  ]);
}

class TacticalSituationCard extends StatelessWidget {
  final Mode mode; final Player a,b;
  const TacticalSituationCard({super.key, required this.mode, required this.a, required this.b});
  @override Widget build(BuildContext context)=>ProBox(title:'Situation tactique', subtitle:mode.group, icon:Icons.sports_soccer_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
    Text(mode.desc, style: const TextStyle(color:AppTheme.muted)),
    const SizedBox(height:10),
    Wrap(spacing:8, runSpacing:8, children:mode.w.keys.map((k)=>Chip(label:Text('${labelStat(k)} ${(mode.w[k]!*100).round()}%'))).toList()),
    const SizedBox(height:10),
    Text(_advice(), style: const TextStyle(fontWeight:FontWeight.w700)),
  ]));
  String _advice(){
    if(mode.key.contains('cutback')) return 'Coach : cherche le joueur qui gagne la zone entre latéral et CB. Défensivement, priorité à awareness + interceptions.';
    if(mode.key.contains('through')) return 'Coach : attaque l’espace dans le dos. Le défenseur doit reculer tôt et défendre la profondeur.';
    if(mode.key.contains('gk')) return 'Coach : pour GK, la ligne GK Reflexes / Positioning / Diving est plus importante que les stats générales.';
    if(mode.key.contains('shield')) return 'Coach : dos au but, body type + balance + Press Proven changent les animations.';
    if(mode.key.contains('dribble')) return 'Coach : isole le joueur, attaque le mauvais appui et surveille Technical/Quick Step.';
    return 'Coach : compare les stats pondérées + profil caché + PlayStyles réellement activés.';
  }
}

class _MiniSlider extends StatelessWidget {
  final String label; final double value; final ValueChanged<double> onChanged;
  const _MiniSlider({required this.label, required this.value, required this.onChanged});
  @override Widget build(BuildContext context)=>Row(children:[SizedBox(width:58, child:Text('$label ≥ ${value.round()}', style: const TextStyle(fontSize:12, fontWeight:FontWeight.w800))), Expanded(child:Slider(value:value,min:0,max:99,divisions:99,onChanged:onChanged))]);
}


class MatchupSpec {
  final String key, label, desc;
  final List<String> modeKeys;
  const MatchupSpec(this.key, this.label, this.desc, this.modeKeys);
}

const matchupSpecs = <MatchupSpec>[
  MatchupSpec('all', 'Tous les duels', 'Affiche tous les modes de comparaison disponibles.', []),
  MatchupSpec('st_cb', 'ST / CF vs CB', 'Attaquant axial contre défenseur central : profondeur, contact, aérien, finition.', ['st_vs_cb','cb_vs_st','through_ball','shoulder','aerial','finish_pressure','att_positioning','marking_cover']),
  MatchupSpec('cb_st', 'CB vs ST / CF', 'Défenseur central qui doit contrôler un buteur.', ['cb_vs_st','st_vs_cb','marking_cover','tackle','aerial','speed_long','shoulder','low_block_defend']),
  MatchupSpec('lw_rb', 'LW vs RB', 'Ailier gauche contre latéral droit : 1v1, cutback, centre, retour défensif.', ['winger_vs_fb','fb_vs_winger','dribble_wing','speed_short','crossing','cutback','inside_forward','jockey']),
  MatchupSpec('rw_lb', 'RW vs LB', 'Ailier droit contre latéral gauche : mêmes critères avec pied fort/crochet intérieur.', ['winger_vs_fb','fb_vs_winger','dribble_wing','speed_short','crossing','cutback','inside_forward','jockey']),
  MatchupSpec('rb_lw', 'RB vs LW', 'Latéral droit contre ailier gauche : contenir, bloquer centre, gérer la profondeur.', ['fb_vs_winger','winger_vs_fb','jockey','tackle','interception','speed_long','cutback_def','fullback_overlap']),
  MatchupSpec('lb_rw', 'LB vs RW', 'Latéral gauche contre ailier droit : contenir, anticiper cutback et intérieur.', ['fb_vs_winger','winger_vs_fb','jockey','tackle','interception','speed_long','cutback_def','fullback_overlap']),
  MatchupSpec('cam_cdm', 'CAM vs CDM', 'Meneur entre les lignes contre sentinelle.', ['cam_vs_cdm','cdm_vs_cam','pass_break','dribble_central','pressing','interception','first_touch_turn','low_block_break']),
  MatchupSpec('cm_cm', 'CM vs CM', 'Milieu contre milieu : pressing, passe, volume et lecture.', ['pressing','pass_break','interception','physical','first_touch_turn','transition_attack','transition_defense','cdm_vs_cam']),
  MatchupSpec('st_gk', 'ST vs GK', 'Face-à-face attaquant/gardien.', ['keeper_1v1','gk_vs_st','finish','finish_pressure','long_shot','aerial','box_header']),
  MatchupSpec('gk_st', 'GK vs ST', 'Gardien contre buteur : réflexes, sortie, placement.', ['gk_vs_st','gk_shot_stop','gk_sweeper','keeper_1v1','aerial']),
  MatchupSpec('wing_cutback', 'Aile / cutback', 'Situation de côté : gagner ligne, cutback ou défendre la passe en retrait.', ['winger_vs_fb','fb_vs_winger','cutback','cutback_def','crossing','wing_cross','inside_forward']),
  MatchupSpec('press_resist', 'Pressing vs sortie de balle', 'Porteur sous pression contre joueur qui presse.', ['pressing','shield','pass_break','first_touch_turn','physical','low_block_break','transition_defense']),
];

List<Mode> modesForMatchup(String key) {
  final spec = matchupSpecs.firstWhere((m)=>m.key==key, orElse:()=>matchupSpecs.first);
  if (spec.modeKeys.isEmpty) return modes;
  final result = <Mode>[];
  for (final k in spec.modeKeys) {
    final found = modes.where((m)=>m.key==k).toList();
    if (found.isNotEmpty) result.add(found.first);
  }
  return result.isEmpty ? modes : result;
}

String autoMatchupFromPositions(Player a, Player b) {
  final pa='${a.pos} ${a.pos2}'.toUpperCase();
  final pb='${b.pos} ${b.pos2}'.toUpperCase();
  bool has(String s, String x)=>s.split(RegExp(r'[/, ]')).contains(x);
  if ((has(pa,'ST')||has(pa,'CF')) && has(pb,'CB')) return 'st_cb';
  if (has(pa,'CB') && (has(pb,'ST')||has(pb,'CF'))) return 'cb_st';
  if (has(pa,'LW') && (has(pb,'RB')||has(pb,'RWB'))) return 'lw_rb';
  if (has(pa,'RW') && (has(pb,'LB')||has(pb,'LWB'))) return 'rw_lb';
  if ((has(pa,'RB')||has(pa,'RWB')) && has(pb,'LW')) return 'rb_lw';
  if ((has(pa,'LB')||has(pa,'LWB')) && has(pb,'RW')) return 'lb_rw';
  if (has(pa,'CAM') && (has(pb,'CDM')||has(pb,'CM'))) return 'cam_cdm';
  if ((has(pa,'CM')||has(pa,'CDM')) && (has(pb,'CM')||has(pb,'CAM')||has(pb,'CDM'))) return 'cm_cm';
  if ((has(pa,'ST')||has(pa,'CF')) && has(pb,'GK')) return 'st_gk';
  if (has(pa,'GK') && (has(pb,'ST')||has(pb,'CF'))) return 'gk_st';
  return 'all';
}

String matchupCoachText(String key, Player a, Player b) {
  final spec = matchupSpecs.firstWhere((m)=>m.key==key, orElse:()=>matchupSpecs.first);
  return '${spec.desc}\nPriorité coach : utilise les modes filtrés ci-dessous, puis ouvre le détail pour voir stats core/support/context, comment profiter et comment contrer.';
}

class ComparePage extends StatefulWidget {
  final List<Player> players; final Player a,b; final Mode mode;
  final ValueChanged<Player> onA,onB; final ValueChanged<Mode> onMode; final ValueChanged<Map<String,dynamic>> onSaveHistory;
  const ComparePage({super.key, required this.players, required this.a, required this.b, required this.mode, required this.onA, required this.onB, required this.onMode, required this.onSaveHistory});
  @override State<ComparePage> createState()=>_ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  String matchupKey = 'all';
  bool autoApplied = false;

  @override void didUpdateWidget(covariant ComparePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.a.id != widget.a.id || oldWidget.b.id != widget.b.id) {
      autoApplied = false;
      final k = autoMatchupFromPositions(widget.a, widget.b);
      if (k != 'all') matchupKey = k;
    }
  }

  @override Widget build(BuildContext context) {
    if (!autoApplied) { final k=autoMatchupFromPositions(widget.a, widget.b); if(k!='all') matchupKey=k; autoApplied=true; }
    final modeList = modesForMatchup(matchupKey);
    final effectiveMode = modeList.any((m)=>m.key==widget.mode.key) ? widget.mode : modeList.first;
    final sa=score(widget.a,effectiveMode), sb=score(widget.b,effectiveMode), win=sa.total>=sb.total?widget.a:widget.b;
    final spec = matchupSpecs.firstWhere((m)=>m.key==matchupKey, orElse:()=>matchupSpecs.first);
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors:[Color(0xFF071225), Color(0xFF0B1728), Color(0xFFF3F7FB)])),
      child: ListView(padding: const EdgeInsets.all(14), children: [
        Header('Comparateur Pro+', 'Gagnant prévu : ${win.name}'),
        ProComparisonHero(a:widget.a,b:widget.b,sa:sa,sb:sb,mode:effectiveMode),
        const SizedBox(height: 12),
        CoachExpansion(title:'Réglages matchup', subtitle:'Poste vs poste + modes adaptés', initiallyExpanded:false, child:Column(children:[
          _MatchupSelector(value: matchupKey, onChanged: (v){ setState(()=>matchupKey=v); final ml=modesForMatchup(v); if(ml.isNotEmpty) widget.onMode(ml.first); }),
          const SizedBox(height: 10),
          _DarkCoachPanel(title: 'Poste vs poste : ${spec.label}', body: matchupCoachText(matchupKey, widget.a, widget.b), icon: Icons.route_rounded),
          const SizedBox(height: 10),
          _ModeChipsPanel(modes: modeList, selected: effectiveMode, onMode: widget.onMode),
        ])),
        CoachExpansion(title:'Joueurs', subtitle:'Changer joueur A/B sans casser le scroll', initiallyExpanded:false, child:Column(children:[
          PlayerPicker(title:'Joueur A', players:widget.players, value:widget.a, onChanged:widget.onA),
          PlayerPicker(title:'Joueur B', players:widget.players, value:widget.b, onChanged:widget.onB),
        ])),
        TacticalSituationCard(mode:effectiveMode, a:widget.a, b:widget.b),
        const SizedBox(height: 10),
        AttackVsDefenseMatrix(a:widget.a, b:widget.b),
        const SizedBox(height: 10),
        ScoreSummary(a:widget.a,b:widget.b,sa:sa,sb:sb),
        FilledButton.icon(onPressed: () => widget.onSaveHistory({'date': DateTime.now().toIso8601String(), 'a': widget.a.name, 'b': widget.b.name, 'matchup': spec.label, 'mode': effectiveMode.label, 'scoreA': sa.total, 'scoreB': sb.total, 'winner': win.name}), icon: const Icon(Icons.save), label: const Text('Sauvegarder dans historique')),
        const SizedBox(height: 10),
        CoachExpansion(title:'Détail du duel', subtitle:'Calcul IA, stats pondérées, conseils', initiallyExpanded:false, child:ProDuelBreakdown(a:widget.a,b:widget.b,mode:effectiveMode)),
        const SizedBox(height: 10),
        CoachExpansion(title:'Stats complètes', subtitle:'Profil, PlayStyles et détail chiffré', initiallyExpanded:false, child:DetailCard(a:widget.a,b:widget.b,sa:sa,sb:sb,mode:effectiveMode)),
        const SizedBox(height: 10),
        CoachExpansion(title:'Tous les modes de comparaison', subtitle:'Replié par défaut pour réduire le scroll', initiallyExpanded:false, child:AllComparisonModesPanel(a:widget.a, b:widget.b, selected:effectiveMode, onMode:widget.onMode, modeList:modeList, matchupLabel:spec.label)),
      ]),
    );
  }
}


class CoachExpansion extends StatelessWidget {
  final String title, subtitle; final Widget child; final bool initiallyExpanded;
  const CoachExpansion({super.key, required this.title, required this.subtitle, required this.child, this.initiallyExpanded=false});
  @override Widget build(BuildContext context)=>Card(child:Theme(data:Theme.of(context).copyWith(dividerColor:Colors.transparent), child:ExpansionTile(
    initiallyExpanded: initiallyExpanded,
    tilePadding: const EdgeInsets.symmetric(horizontal:16, vertical:4),
    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    title: Text(title, style: const TextStyle(fontWeight:FontWeight.w900)),
    subtitle: Text(subtitle, style: const TextStyle(color:AppTheme.muted, fontWeight:FontWeight.w700)),
    children:[child],
  )));
}

class AttackVsDefenseMatrix extends StatelessWidget {
  final Player a,b;
  const AttackVsDefenseMatrix({super.key, required this.a, required this.b});
  @override Widget build(BuildContext context){
    final rows = <(String,String,String)>[
      ('Dribble vs tacle','drib','tackle'),('Agilité vs placement','agi','defaw'),('Contrôle vs interceptions','ball','inter'),('Accélération vs réaction','acc','react'),('Centre vs défense','cross','def'),('Finition vs bloc','finish','block'),
    ];
    return ProBox(title:'Attaque vs défenseur', subtitle:'Comparaison spéciale dribble/attaque contre stats défensives', icon:Icons.sports_martial_arts_rounded, child:Column(children:rows.map((r)=>_row(r.$1, a.s[r.$2]??0, b.s[r.$3]??0)).toList()));
  }
  Widget _row(String label,int av,int bv){ final total=max(1,av+bv); final pa=(av/total*100).round(); final diff=av-bv; return Padding(padding:const EdgeInsets.only(bottom:12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
    Row(children:[Expanded(child:Text(label, style:const TextStyle(fontWeight:FontWeight.w900))), Text('$av - $bv', style:TextStyle(fontWeight:FontWeight.w900, color:diff>=0?AppTheme.green:Colors.redAccent))]),
    const SizedBox(height:6), ClipRRect(borderRadius:BorderRadius.circular(99), child:SizedBox(height:9, child:Row(children:[Expanded(flex:max(1,pa), child:Container(color:AppTheme.green)), Expanded(flex:max(1,100-pa), child:Container(color:AppTheme.line))]))),
  ]));}
}

class _MatchupSelector extends StatelessWidget {
  final String value; final ValueChanged<String> onChanged;
  const _MatchupSelector({required this.value, required this.onChanged});
  @override Widget build(BuildContext context)=>Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius:BorderRadius.circular(26), color: const Color(0xFF071225), border: Border.all(color: const Color(0xFF1D4ED8).withOpacity(.45)), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.18), blurRadius:20, offset:const Offset(0,10))]),
    child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(children: const [Icon(Icons.swap_horiz_rounded, color:Color(0xFF34D399)), SizedBox(width:8), Expanded(child:Text('Poste vs poste', style:TextStyle(color:Colors.white, fontSize:18, fontWeight:FontWeight.w900)))]),
      const SizedBox(height:8),
      DropdownButtonFormField<String>(value:value, dropdownColor: const Color(0xFF0B1728), style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w800), decoration: const InputDecoration(labelText:'Matchup', fillColor:Color(0xFF0B1728)), items: matchupSpecs.map((m)=>DropdownMenuItem(value:m.key, child:Text(m.label, overflow:TextOverflow.ellipsis))).toList(), onChanged:(v){ if(v!=null) onChanged(v); }),
    ]),
  );
}

class _ModeChipsPanel extends StatelessWidget {
  final List<Mode> modes; final Mode selected; final ValueChanged<Mode> onMode;
  const _ModeChipsPanel({required this.modes, required this.selected, required this.onMode});
  @override Widget build(BuildContext context)=>Container(
    margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(24), border:Border.all(color:AppTheme.line)),
    child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      const Text('Modes adaptés au matchup', style:TextStyle(fontWeight:FontWeight.w900, fontSize:16)),
      const SizedBox(height:8),
      Wrap(spacing:8, runSpacing:8, children:modes.map((m)=>ChoiceChip(label:Text(m.label), selected:m.key==selected.key, onSelected:(_)=>onMode(m))).toList()),
    ]),
  );
}

class _DarkCoachPanel extends StatelessWidget {
  final String title, body; final IconData icon;
  const _DarkCoachPanel({required this.title, required this.body, required this.icon});
  @override Widget build(BuildContext context)=>Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF061426), borderRadius:BorderRadius.circular(24), border:Border.all(color: const Color(0xFF284766))),
    child: Row(crossAxisAlignment:CrossAxisAlignment.start, children:[Icon(icon,color:const Color(0xFF34D399)), const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(title, style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)), const SizedBox(height:6), Text(body, style:const TextStyle(color:Color(0xFFB7C9E8),height:1.35,fontWeight:FontWeight.w700))]))]),
  );
}


class AllComparisonModesPanel extends StatelessWidget {
  final Player a, b;
  final Mode selected;
  final ValueChanged<Mode> onMode;
  final List<Mode>? modeList;
  final String matchupLabel;
  const AllComparisonModesPanel({super.key, required this.a, required this.b, required this.selected, required this.onMode, this.modeList, this.matchupLabel='Tous les duels'});

  @override
  Widget build(BuildContext context) {
    int winsA = 0, winsB = 0, draws = 0;
    for (final m in (modeList ?? modes)) {
      final sa = score(a, m).total;
      final sb = score(b, m).total;
      if (sa > sb) winsA++; else if (sb > sa) winsB++; else draws++;
    }
    final globalWinner = winsA == winsB ? 'Égalité globale' : (winsA > winsB ? a.name : b.name);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(colors: [Color(0xFF061426), Color(0xFF0B2340)]),
        border: Border.all(color: Color(0xFF284766)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.22), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.analytics_rounded, color: Color(0xFF34D399)),
          SizedBox(width: 8),
          Expanded(child: Text('Tous les modes de comparaison', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 6),
        Text('Matchup : $matchupLabel • clique sur un mode pour voir détail, stats core/support/context et conseils coach.', style: const TextStyle(color: Color(0xFFB7C9E8), height: 1.35)),
        const SizedBox(height: 14),
        _GlobalScoreBar(a:a,b:b,winsA:winsA,winsB:winsB,draws:draws,winner:globalWinner),
        const SizedBox(height: 14),
        ..._groupedModes(context),
      ]),
    );
  }

  List<Widget> _groupedModes(BuildContext context) {
    final groups = <String, List<Mode>>{};
    for (final m in (modeList ?? modes)) {
      groups.putIfAbsent(m.group, () => <Mode>[]).add(m);
    }
    return groups.entries.map((entry) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.key, style: const TextStyle(color: Color(0xFF8EEBC2), fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 8),
        ...entry.value.map((m) => _ModeResultTile(a:a,b:b,mode:m,selected:m.key==selected.key,onTap:(){
          onMode(m);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ModeDetailSheet(a:a,b:b,mode:m),
          );
        })),
      ]),
    )).toList();
  }
}

class _GlobalScoreBar extends StatelessWidget {
  final Player a,b; final int winsA,winsB,draws; final String winner;
  const _GlobalScoreBar({required this.a, required this.b, required this.winsA, required this.winsB, required this.draws, required this.winner});
  @override Widget build(BuildContext context) {
    final total = max(1, winsA + winsB + draws);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF0B1B31), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF284766))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _winColumn('A', a.name, winsA, const Color(0xFF2F80FF))),
          Container(width:1,height:48,color:const Color(0xFF284766)),
          Expanded(child: _winColumn('=', 'Égalités', draws, const Color(0xFF94A3B8))),
          Container(width:1,height:48,color:const Color(0xFF284766)),
          Expanded(child: _winColumn('B', b.name, winsB, const Color(0xFF45D06D))),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(height: 12, child: Row(children: [
            Expanded(flex: max(1,winsA), child: Container(color: const Color(0xFF2F80FF))),
            if(draws>0) Expanded(flex: draws, child: Container(color: const Color(0xFF64748B))),
            Expanded(flex: max(1,winsB), child: Container(color: const Color(0xFF45D06D))),
          ])),
        ),
        const SizedBox(height: 10),
        Text('Gagnant global : $winner • $winsA - $winsB, $draws égalités sur $total modes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ]),
    );
  }
  Widget _winColumn(String tag, String name, int n, Color color)=>Padding(
    padding: const EdgeInsets.symmetric(horizontal:8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width:34,height:34,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,color:color),child:Text(tag, style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))),
      const SizedBox(height:6),
      Text('$n victoires', style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
      Text(name, maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(color:Color(0xFFB7C9E8), fontSize:12)),
    ]),
  );
}

class _ModeResultTile extends StatelessWidget {
  final Player a,b; final Mode mode; final bool selected; final VoidCallback onTap;
  const _ModeResultTile({required this.a, required this.b, required this.mode, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) {
    final sa=score(a,mode), sb=score(b,mode);
    final total=max(1,sa.total+sb.total);
    final pa=(sa.total/total*100).clamp(0,100).round();
    final win = sa.total == sb.total ? 'Égalité' : (sa.total > sb.total ? 'A' : 'B');
    final winColor = win=='A' ? const Color(0xFF2F80FF) : win=='B' ? const Color(0xFF45D06D) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom:8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF123A66) : const Color(0xFF0D2038),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? const Color(0xFF34D399) : const Color(0xFF284766)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(mode.label, maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:15))),
            Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), decoration:BoxDecoration(color:winColor.withOpacity(.18),borderRadius:BorderRadius.circular(999),border:Border.all(color:winColor.withOpacity(.7))), child:Text(win, style:TextStyle(color:winColor, fontWeight:FontWeight.w900))),
          ]),
          const SizedBox(height: 4),
          Text(mode.desc, maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(color:Color(0xFFB7C9E8), fontSize:12)),
          const SizedBox(height: 9),
          Row(children: [
            SizedBox(width:44, child:Text('${sa.total}', style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w900))),
            Expanded(child: ClipRRect(borderRadius:BorderRadius.circular(99), child:SizedBox(height:10, child:Row(children:[
              Expanded(flex:max(1,pa), child:Container(color:const Color(0xFF2F80FF))),
              Expanded(flex:max(1,100-pa), child:Container(color:const Color(0xFF45D06D))),
            ])))),
            SizedBox(width:44, child:Text('${sb.total}', textAlign:TextAlign.end, style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w900))),
            const SizedBox(width:6),
            const Icon(Icons.keyboard_arrow_right_rounded, color:Color(0xFFB7C9E8)),
          ]),
        ]),
      ),
    );
  }
}

class _ModeDetailSheet extends StatelessWidget {
  final Player a,b; final Mode mode;
  const _ModeDetailSheet({required this.a, required this.b, required this.mode});
  @override Widget build(BuildContext context) {
    final sa=score(a,mode), sb=score(b,mode);
    final win = sa.total == sb.total ? 'Égalité' : (sa.total > sb.total ? a.name : b.name);
    final h = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: h * .88),
      decoration: const BoxDecoration(color: Color(0xFF061426), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [
        Center(child: Container(width:44,height:5,decoration:BoxDecoration(color:const Color(0xFF46627F), borderRadius:BorderRadius.circular(99)))),
        const SizedBox(height: 14),
        Row(children:[
          Expanded(child: Text(mode.label, style: const TextStyle(color:Colors.white, fontSize:22, fontWeight:FontWeight.w900))),
          IconButton(onPressed:()=>Navigator.pop(context), icon: const Icon(Icons.close_rounded, color:Colors.white)),
        ]),
        Text(mode.group, style: const TextStyle(color:Color(0xFF34D399), fontWeight:FontWeight.w900)),
        const SizedBox(height: 6),
        Text(mode.desc, style: const TextStyle(color:Color(0xFFB7C9E8), height:1.35)),
        const SizedBox(height: 14),
        _detailScore(a,b,sa,sb,win),
        const SizedBox(height: 14),
        const Text('Stats utilisées dans ce mode', style: TextStyle(color:Colors.white, fontSize:18, fontWeight:FontWeight.w900)),
        const SizedBox(height: 8),
        ...mode.w.entries.map((e)=>_statDetailRow(e.key, e.value, a.s[e.key]??0, b.s[e.key]??0)),
        const SizedBox(height: 14),
        _coachBox(win),
        const SizedBox(height: 14),
        _impactBox('Profil / body / AcceleRATE', sa.profileRows, sb.profileRows),
        const SizedBox(height: 10),
        _impactBox('PlayStyles & traits activés', sa.playRows.where((x)=>x.active).toList(), sb.playRows.where((x)=>x.active).toList()),
      ]),
    );
  }
  Widget _detailScore(Player a, Player b, DuelScore sa, DuelScore sb, String win)=>Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF0D2038), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF284766))),
    child: Column(children:[
      Row(children:[
        Expanded(child:_playerScore(a,sa,const Color(0xFF2F80FF))),
        Container(width:1,height:72,color:const Color(0xFF284766)),
        Expanded(child:_playerScore(b,sb,const Color(0xFF45D06D))),
      ]),
      const SizedBox(height: 12),
      Text('Gagnant du mode : $win', style: const TextStyle(color:Color(0xFF8EEBC2), fontWeight:FontWeight.w900, fontSize:16)),
    ]),
  );
  Widget _playerScore(Player p, DuelScore s, Color c)=>Padding(
    padding: const EdgeInsets.symmetric(horizontal:8),
    child: Row(children:[
      PlayerAvatar(p:p,size:50),
      const SizedBox(width:8),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
        Text('${s.total} pts • core ${s.core} • profil ${s.profile} • styles ${s.play}', style: const TextStyle(color:Color(0xFFB7C9E8), fontSize:12)),
      ])),
    ]),
  );
  Widget _statDetailRow(String key, double w, int va, int vb) {
    final maxv=max(1,max(va,vb));
    return Container(
      margin: const EdgeInsets.only(bottom:8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0D2038), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF284766))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children:[Expanded(child:Text('${labelStat(key)} • poids ${(w*100).round()}%', style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w800))), Text('$va - $vb', style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))]),
        const SizedBox(height:8),
        ClipRRect(borderRadius:BorderRadius.circular(99), child:SizedBox(height:10, child:Row(children:[
          Expanded(flex:max(1,(va/maxv*100).round()), child:Container(color:const Color(0xFF2F80FF))),
          Expanded(flex:max(1,(vb/maxv*100).round()), child:Container(color:const Color(0xFF45D06D))),
        ]))),
      ]),
    );
  }
  Widget _coachBox(String win)=>Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF092B24), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1FBF75))),
    child: Text('Lecture coach : $win est le profil le plus adapté pour ce mode.\n\nComment profiter : provoque ce duel, oriente le jeu vers les stats vertes et utilise les PlayStyles activés.\n\nComment contrer : évite le duel direct, force le joueur vers son mauvais pied/mauvais angle, ferme la zone du mode et demande une couverture proche.\n\nÀ éviter : courir tout droit si l’adversaire gagne vitesse/contact, centrer si l’adversaire gagne aérien, presser seul si l’adversaire gagne Press Proven/Composure.', style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w700, height:1.35)),
  );
  Widget _impactBox(String title, List<ImpactRow> ra, List<ImpactRow> rb)=>Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF0D2038), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF284766))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(title, style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:_impactList(ra)),
        const SizedBox(width:10),
        Expanded(child:_impactList(rb)),
      ]),
    ]),
  );
  Widget _impactList(List<ImpactRow> rows)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children: rows.take(6).map((r)=>Padding(
    padding: const EdgeInsets.only(bottom:6),
    child: Text('${r.points>=0?'+':''}${r.points} ${r.name}', maxLines:2, overflow:TextOverflow.ellipsis, style: const TextStyle(color:Color(0xFFB7C9E8), fontSize:12, fontWeight:FontWeight.w700)),
  )).toList());
}

class Header extends StatelessWidget {
  final String title, sub;
  const Header(this.title,this.sub,{super.key});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 4), Text(sub, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600, height: 1.25)),
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
  return showModalBottomSheet<Player>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PlayerSearchDialog(players: players, current: current),
  );
}

class PlayerSearchDialog extends StatefulWidget {
  final List<Player> players; final Player current;
  const PlayerSearchDialog({super.key, required this.players, required this.current});
  @override State<PlayerSearchDialog> createState()=>_PlayerSearchDialogState();
}
class _PlayerSearchDialogState extends State<PlayerSearchDialog> {
  String q=''; String team='all'; String pos='all'; String foot='all'; String accel='all'; String body='all'; String play='all'; String wr='all';
  bool showWomen=false, showSoccerAid=false, onlyNamed=false; RangeValues ovrRange=const RangeValues(40,99); RangeValues hRange=const RangeValues(150,210); RangeValues wRange=const RangeValues(45,115); double minPace=0; double minPhy=0; double minDri=0; double minDef=0;
  @override Widget build(BuildContext context) {
    bool hidden(Player p){final t=p.team.toLowerCase(), n=p.name.toLowerCase(); if(!showWomen && (t.contains('women')||t.contains('female')||n.contains('women'))) return true; if(!showSoccerAid && (t.contains('soccer aid')||t.contains('classic xi')||t.contains('adidas'))) return true; return false;}
    final visible=widget.players.where((p)=>!hidden(p)).toList();
    final teams=['all', ...visible.map((p)=>p.team).where((t)=>t!='—').toSet().take(350)];
    final plays=['all', ...widget.players.expand((p)=>mergedPlayStyles(p)).toSet().take(120)];
    final query=q.toLowerCase().trim();
    final res=widget.players.where((p){
      if(hidden(p)) return false;
      if(onlyNamed && p.name.startsWith('Player ')) return false;
      if(team!='all' && p.team!=team) return false;
      if(pos!='all' && !p.pos.toUpperCase().contains(pos)) return false;
      if(foot!='all' && p.foot!=foot) return false;
      if(accel!='all' && p.accel!=accel) return false;
      if(body!='all' && p.body!=body) return false;
      if(play!='all' && !mergedPlayStyles(p).contains(play)) return false;
      if(wr!='all' && !(p.attWr==wr || p.defWr==wr)) return false;
      if(p.ovr < ovrRange.start.round() || p.ovr > ovrRange.end.round()) return false;
      if(p.height < hRange.start.round() || p.height > hRange.end.round()) return false;
      if(p.weight < wRange.start.round() || p.weight > wRange.end.round()) return false;
      if((p.s['pac']??0) < minPace.round()) return false;
      if((p.s['phy']??0) < minPhy.round()) return false;
      if((p.s['dri']??0) < minDri.round()) return false;
      if((p.s['def']??0) < minDef.round()) return false;
      if(query.isNotEmpty && !('${p.id} ${p.name} ${p.team} ${p.pos} ${p.ovr} ${p.playstyles.join(' ')} ${p.body} ${p.accel}').toLowerCase().contains(query)) return false;
      return true;
    }).take(250).toList();
    final activeFilters = [team,pos,foot,accel,body,play,wr].where((x)=>x!='all').length + (onlyNamed?1:0) + (showWomen?1:0) + (showSoccerAid?1:0) + (ovrRange.start.round()>40 || ovrRange.end.round()<99 ? 1:0) + (hRange.start.round()>150 || hRange.end.round()<210 ? 1:0) + (wRange.start.round()>45 || wRange.end.round()<115 ? 1:0) + (minPace>0?1:0) + (minPhy>0?1:0) + (minDri>0?1:0) + (minDef>0?1:0);
    return DraggableScrollableSheet(
      initialChildSize: .92,
      minChildSize: .55,
      maxChildSize: .98,
      expand: false,
      builder: (context, scrollController) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(color: Color(0xFF061426), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 46, height: 5, decoration: BoxDecoration(color: Color(0xFF46627F), borderRadius: BorderRadius.circular(99))),
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 10, 8), child: Row(children: [
            const Expanded(child: Text('Choisir joueur', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
            IconButton(onPressed:()=>Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children:[
            Expanded(child: TextField(autofocus:true, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Rechercher nom, équipe, poste...'), onChanged:(v)=>setState(()=>q=v))),
            const SizedBox(width: 10),
            IconButton.filledTonal(tooltip:'Filtres', onPressed:(){}, icon: const Icon(Icons.tune_rounded)),
          ])),
          const SizedBox(height: 8),
          Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children:[
            Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              title: Text('Filtres ($activeFilters actifs)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              subtitle: const Text('Cachés par défaut pour gagner de la place', style: TextStyle(color: Color(0xFF9FB2CC))),
              children: [
                LayoutBuilder(builder:(context,c){
                  Widget gap = const SizedBox(height: 8);
                  Widget row(Widget a, Widget b)=> c.maxWidth < 440 ? Column(children:[a,gap,b]) : Row(children:[Expanded(child:a), const SizedBox(width:8), Expanded(child:b)]);
                  return Column(children:[
                    row(DropdownButtonFormField<String>(value: team, isExpanded: true, items: teams.map((t)=>DropdownMenuItem(value:t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>team=v!), decoration: const InputDecoration(labelText:'Équipe')), DropdownButtonFormField<String>(value: pos, isExpanded:true, items: ['all','ST','CF','LW','RW','CAM','CM','CDM','LM','RM','LWB','RWB','LB','RB','CB','GK'].map((t)=>DropdownMenuItem(value:t, child: Text(t))).toList(), onChanged:(v)=>setState(()=>pos=v!), decoration: const InputDecoration(labelText:'Poste'))),
                    gap,
                    row(DropdownButtonFormField<String>(value: foot, items: ['all','Right','Left'].map((t)=>DropdownMenuItem(value:t, child: Text(t))).toList(), onChanged:(v)=>setState(()=>foot=v!), decoration: const InputDecoration(labelText:'Pied')), DropdownButtonFormField<String>(value: accel, isExpanded:true, items: ['all','Controlled','Explosive','Mostly Explosive','Controlled Lengthy','Lengthy'].map((t)=>DropdownMenuItem(value:t, child: Text(t, overflow:TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>accel=v!), decoration: const InputDecoration(labelText:'AcceleRATE'))),
                    gap,
                    row(DropdownButtonFormField<String>(value: body, isExpanded:true, items: ['all','Lean','Average','Stocky','High & Lean','High & Average','High & Stocky','Unique'].map((t)=>DropdownMenuItem(value:t, child: Text(t, overflow:TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>body=v!), decoration: const InputDecoration(labelText:'Body Type')), DropdownButtonFormField<String>(value: play, isExpanded:true, items: plays.map((t)=>DropdownMenuItem(value:t, child: Text(t, overflow:TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>play=v!), decoration: const InputDecoration(labelText:'PlayStyle / trait'))),
                    gap,
                    DropdownButtonFormField<String>(value: wr, isExpanded:true, items: ['all','Low','Medium','High'].map((t)=>DropdownMenuItem(value:t, child: Text(t))).toList(), onChanged:(v)=>setState(()=>wr=v!), decoration: const InputDecoration(labelText:'Work rate attaque ou défense')),
                    const SizedBox(height: 8),
                    Row(children:[Text('OVR ${ovrRange.start.round()}-${ovrRange.end.round()}'), Expanded(child:RangeSlider(values:ovrRange,min:1,max:99,divisions:98,onChanged:(v)=>setState(()=>ovrRange=v)))]),
                    Row(children:[Text('Taille ${hRange.start.round()}-${hRange.end.round()}cm'), Expanded(child:RangeSlider(values:hRange,min:150,max:210,divisions:60,onChanged:(v)=>setState(()=>hRange=v)))]),
                    Row(children:[Text('Poids ${wRange.start.round()}-${wRange.end.round()}kg'), Expanded(child:RangeSlider(values:wRange,min:45,max:115,divisions:70,onChanged:(v)=>setState(()=>wRange=v)))]),
                    Row(children:[Expanded(child:Slider(value:minPace,min:0,max:99,divisions:99,label:'PAC ${minPace.round()}',onChanged:(v)=>setState(()=>minPace=v))), Expanded(child:Slider(value:minDri,min:0,max:99,divisions:99,label:'DRI ${minDri.round()}',onChanged:(v)=>setState(()=>minDri=v)))]),
                    Row(children:[Expanded(child:Slider(value:minPhy,min:0,max:99,divisions:99,label:'PHY ${minPhy.round()}',onChanged:(v)=>setState(()=>minPhy=v))), Expanded(child:Slider(value:minDef,min:0,max:99,divisions:99,label:'DEF ${minDef.round()}',onChanged:(v)=>setState(()=>minDef=v)))]),
                    Wrap(spacing:8, runSpacing:8, children:[FilterChip(label:const Text('Vrais noms'), selected:onlyNamed, onSelected:(v)=>setState(()=>onlyNamed=v)), FilterChip(label:const Text('Afficher Female'), selected:showWomen, onSelected:(v)=>setState(()=>showWomen=v)), FilterChip(label:const Text('Afficher Soccer Aid'), selected:showSoccerAid, onSelected:(v)=>setState(()=>showSoccerAid=v)), ActionChip(label:const Text('Effacer filtres'), avatar:const Icon(Icons.refresh), onPressed:()=>setState((){team=pos=foot=accel=body=play=wr='all'; onlyNamed=showWomen=showSoccerAid=false; ovrRange=const RangeValues(40,99); hRange=const RangeValues(150,210); wRange=const RangeValues(45,115); minPace=minPhy=minDri=minDef=0;}))]),
                  ]);
                }),
              ],
            )),
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${res.length} résultats', style: const TextStyle(color: Color(0xFF9FB2CC), fontWeight: FontWeight.w800))),
            ...res.map((p)=>PlayerTile(p:p, onTap:()=>Navigator.pop(context,p))),
          ])),
        ]),
      ),
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
      ...rows.take(80).map((x)=>Card(child: ListTile(
        title: Text(x.p.name),
        subtitle: Text('${x.p.team} • ${x.p.pos} • ${x.p.body} • ${x.p.accel}\nClique pour détail comparaison vs ${ref.name}', maxLines:2, overflow:TextOverflow.ellipsis),
        trailing: Text('${x.sc}  +${x.sc-refScore}', style: const TextStyle(color: AppTheme.pink, fontWeight: FontWeight.w900)),
        onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>_ModeDetailSheet(a:x.p,b:ref,mode:mode)),
      ))),
    ]);
  }
}


class DatabasePage extends StatefulWidget {
  final List<Player> players;
  const DatabasePage({super.key, required this.players});
  @override State<DatabasePage> createState()=>_DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  String q='', pos='all', team='all', foot='all', accel='all', body='all', play='all'; double minPac=0, minSho=0, minPas=0, minDri=0, minDef=0, minPhy=0;
  bool showWomen=false, showSoccerAid=false, onlyNamed=false, onlyPlayStyles=false, onlyGk=false, showFilters=false;
  RangeValues ovrRange = const RangeValues(40, 99);

  bool hidden(Player p) {
    final t=p.team.toLowerCase();
    final n=p.name.toLowerCase();
    if (!showWomen && p.gender != 0) return true;
  if (!showWomen && (t.contains('women') || t.contains('female') || n.contains('women'))) return true;
    if (!showSoccerAid && (t.contains('soccer aid') || t.contains('adidas') || t.contains('classic xi'))) return true;
    return false;
  }

  @override Widget build(BuildContext context) {
    final visibleForTeams = widget.players.where((p)=>!hidden(p)).toList();
    final teams=['all', ...visibleForTeams.map((p)=>p.team).where((t)=>t!='—').toSet().take(350)];
    final plays=['all', ...widget.players.expand((p)=>mergedPlayStyles(p)).toSet().take(120)];
    final query=q.toLowerCase().trim();
    final rows=widget.players.where((p){
      if (hidden(p)) return false;
      if (onlyNamed && p.name.startsWith('Player ')) return false;
      if (onlyPlayStyles && p.playstyles.isEmpty) return false;
      if (onlyGk && !p.pos.toUpperCase().contains('GK')) return false;
      if (team!='all' && p.team!=team) return false;
      if (pos!='all' && !p.pos.toUpperCase().contains(pos)) return false;
      if (foot!='all' && p.foot!=foot) return false;
      if (accel!='all' && p.accel!=accel) return false;
      if (body!='all' && p.body!=body) return false;
      if (play!='all' && !mergedPlayStyles(p).contains(play)) return false;
      if ((p.s['pac']??0) < minPac.round() || (p.s['sho']??0) < minSho.round() || (p.s['pas']??0) < minPas.round() || (p.s['dri']??0) < minDri.round() || (p.s['def']??0) < minDef.round() || (p.s['phy']??0) < minPhy.round()) return false;
      if (p.ovr < ovrRange.start.round() || p.ovr > ovrRange.end.round()) return false;
      if (query.isNotEmpty && !('${p.name} ${p.team} ${p.pos} ${p.ovr} ${p.playstyles.join(' ')}').toLowerCase().contains(query)) return false;
      return true;
    }).take(500).toList();

    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Base joueurs Pro', '${rows.length} affichés / ${widget.players.length} joueurs'),
      ProBox(title:'Recherche rapide', subtitle:'Filtres cachés par défaut pour éviter le scroll', icon:Icons.search_rounded, child:Column(children:[
        TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Nom, ID, équipe, poste, PlayStyle...'), onChanged:(v)=>setState(()=>q=v)),
        const SizedBox(height:10),
        Row(children:[
          Expanded(child: Text('Filtres actifs : poste $pos • équipe $team • OVR ${ovrRange.start.round()}-${ovrRange.end.round()}', maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:AppTheme.muted))),
          FilledButton.tonalIcon(onPressed:()=>setState(()=>showFilters=!showFilters), icon:Icon(showFilters?Icons.expand_less_rounded:Icons.tune_rounded), label:Text(showFilters?'Masquer':'Afficher filtres')),
        ]),
      ])),
      if(showFilters) DefaultTabController(length:4, child:ProBox(title:'Filtres avancés', subtitle:'Général, profil, stats et options', icon:Icons.filter_alt_rounded, child:Column(children:[
        const TabBar(isScrollable:true, tabs:[Tab(text:'Général'),Tab(text:'Profil'),Tab(text:'Stats'),Tab(text:'Options')]),
        SizedBox(height:390, child:TabBarView(children:[
          ListView(padding:EdgeInsets.zero, children:[
            Row(children:[
              Expanded(child: DropdownButtonFormField<String>(value: pos, items: ['all','ST','CF','LW','RW','CAM','CM','CDM','LM','RM','LB','RB','CB','GK'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>pos=v!), decoration: const InputDecoration(labelText:'Poste'))),
              const SizedBox(width:8),
              Expanded(child: DropdownButtonFormField<String>(value: team, isExpanded:true, items: teams.map((x)=>DropdownMenuItem(value:x, child: Text(x, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>team=v!), decoration: const InputDecoration(labelText:'Équipe'))),
            ]),
            const SizedBox(height:8),
            RangeSlider(values:ovrRange,min:40,max:99,divisions:59,labels:RangeLabels('${ovrRange.start.round()}','${ovrRange.end.round()}'),onChanged:(v)=>setState(()=>ovrRange=v)),
          ]),
          ListView(padding:EdgeInsets.zero, children:[
            Row(children:[
              Expanded(child: DropdownButtonFormField<String>(value: foot, items: ['all','Right','Left'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>foot=v!), decoration: const InputDecoration(labelText:'Pied'))),
              const SizedBox(width:8),
              Expanded(child: DropdownButtonFormField<String>(value: accel, isExpanded:true, items: ['all','Controlled','Explosive','Mostly Explosive','Controlled Lengthy','Lengthy'].map((x)=>DropdownMenuItem(value:x, child: Text(x, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>accel=v!), decoration: const InputDecoration(labelText:'AcceleRATE'))),
            ]),
            const SizedBox(height:8),
            Row(children:[
              Expanded(child: DropdownButtonFormField<String>(value: body, isExpanded:true, items: ['all','Lean','Normal','Stocky','Unique','High & Average','Short & Lean','Tall & Lean'].map((x)=>DropdownMenuItem(value:x, child: Text(x, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>body=v!), decoration: const InputDecoration(labelText:'Body type'))),
              const SizedBox(width:8),
              Expanded(child: DropdownButtonFormField<String>(value: play, isExpanded:true, items: plays.map((x)=>DropdownMenuItem(value:x, child: Text(x, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>play=v!), decoration: const InputDecoration(labelText:'PlayStyle'))),
            ]),
          ]),
          ListView(padding:EdgeInsets.zero, children:[
            Slider(value:minPac,min:0,max:95,divisions:19,label:'PAC ${minPac.round()}', onChanged:(v)=>setState(()=>minPac=v)),
            Slider(value:minSho,min:0,max:95,divisions:19,label:'SHO ${minSho.round()}', onChanged:(v)=>setState(()=>minSho=v)),
            Slider(value:minPas,min:0,max:95,divisions:19,label:'PAS ${minPas.round()}', onChanged:(v)=>setState(()=>minPas=v)),
            Slider(value:minDri,min:0,max:95,divisions:19,label:'DRI ${minDri.round()}', onChanged:(v)=>setState(()=>minDri=v)),
            Slider(value:minDef,min:0,max:95,divisions:19,label:'DEF ${minDef.round()}', onChanged:(v)=>setState(()=>minDef=v)),
            Slider(value:minPhy,min:0,max:95,divisions:19,label:'PHY ${minPhy.round()}', onChanged:(v)=>setState(()=>minPhy=v)),
          ]),
          ListView(padding:EdgeInsets.zero, children:[
            Wrap(spacing:8, children:[
              FilterChip(label:const Text('Noms réels seulement'), selected:onlyNamed, onSelected:(v)=>setState(()=>onlyNamed=v)),
              FilterChip(label:const Text('Avec PlayStyles/Traits'), selected:onlyPlayStyles, onSelected:(v)=>setState(()=>onlyPlayStyles=v)),
              FilterChip(label:const Text('GK seulement'), selected:onlyGk, onSelected:(v)=>setState(()=>onlyGk=v)),
              FilterChip(label:const Text('Afficher Female'), selected:showWomen, onSelected:(v)=>setState(()=>showWomen=v)),
              FilterChip(label:const Text('Afficher Soccer Aid'), selected:showSoccerAid, onSelected:(v)=>setState(()=>showSoccerAid=v)),
            ]),
          ]),
        ])),
      ]))),
      ...rows.map((p)=>PlayerTile(p:p, onTap:()=>showPlayerDetails(context,p))),
    ]);
  }
}

void showPlayerDetails(BuildContext context, Player p) {
  final st = appShellKey.currentState;
  final all = st is _AppShellState ? st.customPlayers : <Player>[];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.bg,
    builder: (_) => PlayerDetailsSheet(p:p, allPlayers: all),
  );
}


class PlayerDetailsSheet extends StatelessWidget {
  final Player p;
  final List<Player> allPlayers;
  const PlayerDetailsSheet({super.key, required this.p, this.allPlayers = const []});

  @override Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .92,
      maxChildSize: .98,
      minChildSize: .50,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: ListView(controller: controller, padding: const EdgeInsets.all(16), children: [
          Container(width:52,height:5,margin:const EdgeInsets.only(bottom:14),decoration:BoxDecoration(color:AppTheme.line,borderRadius:BorderRadius.circular(99))),
          _hero(context),
          const SizedBox(height:12),
          _quickActions(context),
          const SizedBox(height:12),
          UxTabSection(
            tabs: const ['Overview','Stats','PlayStyles','Traits','Analyse IA','Duels','Counters','Similar','History'],
            height: 720,
            children: [
              _overview(context),
              _statsHub(context),
              _playStylesHub(context),
              _traitsHub(context),
              _analysisHub(context),
              _duelsHub(context),
              _countersHub(context),
              _similarHub(context),
              _historyHub(context),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _hero(BuildContext context)=>Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[AppTheme.purple, AppTheme.blue])),
    child: Row(children:[
      PlayerAvatar(p:p, size:104),
      const SizedBox(width:16),
      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(p.name, style: const TextStyle(fontSize:28, fontWeight:FontWeight.w900, color:Colors.white)),
        Text('${p.team} • ${p.pos}${p.pos2.isNotEmpty ? ' / ${p.pos2}' : ''}', style: const TextStyle(color:Colors.white70)),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children:[_heroBadge('OVR', p.ovr), _heroBadge('POT', p.pot), _heroBadge('SM', p.skill), _heroBadge('WF', p.weakFoot)]),
      ])),
    ]),
  );

  Widget _quickActions(BuildContext context)=>Wrap(spacing:8, runSpacing:8, children:[
    FilledButton.icon(onPressed:(){ Navigator.pop(context); final st = appShellKey.currentState; if (st is _AppShellState) { st.openCrudFromDetails(p); }}, icon: const Icon(Icons.edit_rounded), label: const Text('Edit CRUD')),
    FilledButton.tonalIcon(onPressed:()=>_showUseModal(context), icon: const Icon(Icons.psychology_alt_rounded), label: const Text('Analyse rapide')),
    FilledButton.tonalIcon(onPressed:(){ final st = appShellKey.currentState; if(st is _AppShellState){ st.compareFromDetails(p); } }, icon: const Icon(Icons.compare_arrows_rounded), label: const Text('Comparer')),
    FilledButton.tonalIcon(onPressed:(){ final st = appShellKey.currentState; if(st is _AppShellState){ st.addFavoritePlayer(p); } }, icon: const Icon(Icons.star_rounded), label: const Text('Favori')),
  ]);

  Widget _overview(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
    ProBox(title:'Carte joueur', subtitle:'Identité, rôle, profil physique et animations', icon:Icons.badge_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Wrap(spacing:8, runSpacing:8, children:[
        Chip(label: Text('ID ${p.id}')), Chip(label: Text('${p.height}cm')), Chip(label: Text('${p.weight}kg')), Chip(label: Text(p.body)), Chip(label: Text(p.accel)), Chip(label: Text('Foot ${p.foot}')), Chip(label: Text('WR ${p.attWr}/${p.defWr}')),
      ]),
      const SizedBox(height:10), Text(_coachProfile(p), style: const TextStyle(fontWeight:FontWeight.w800, height:1.4)),
    ])),
    ProBox(title:'Forces rapides', subtitle:'Top stats détectées', icon:Icons.bolt_rounded, child:Wrap(spacing:8,runSpacing:8, children:_topStats(p).map((x)=>Chip(label:Text(x))).toList())),
    ProBox(title:'Actions utiles', subtitle:'Accès rapide sans changer de contexte', icon:Icons.touch_app_rounded, child:Wrap(spacing:8,runSpacing:8, children:[
      ActionChip(label:const Text('Voir faiblesses'), onPressed:()=>showUxDetailModal(context,'Faiblesses ${p.name}',[_weakBox()])),
      ActionChip(label:const Text('Meilleur usage'), onPressed:()=>showUxDetailModal(context,'Comment utiliser ${p.name}',[_useBox()])),
      ActionChip(label:const Text('Stats clés'), onPressed:()=>showUxDetailModal(context,'Stats clés ${p.name}',[_topStatBox(context)])),
    ])),
  ]);

  Widget _statsHub(BuildContext context)=>UxTabSection(tabs:const ['Card','Pace','Shooting','Passing','Dribbling','Defending','Physical','GK'], height:610, children:[
    _statList(context,'Stats carte', const ['pac','sho','pas','dri','def','phy']),
    _statList(context,'Vitesse', const ['acc','sprint','agi','react','stam']),
    _statList(context,'Tir', const ['finish','shot','longshot','posi','volleys','penalties','comp']),
    _statList(context,'Passe', const ['shortp','longp','vision','cross','curve','fk']),
    _statList(context,'Dribble', const ['ball','drib','agi','bal','react','comp']),
    _statList(context,'Défense', const ['defaw','tackle','slide','inter','head','agg','block']),
    _statList(context,'Physique', const ['str','agg','stam','jump','bal','react']),
    _statList(context,'Gardien', const ['gkdiv','gkhan','gkkick','gkpos','gkref']),
  ]);

  Widget _statList(BuildContext context,String title,List<String> keys)=>ProBox(title:title, subtitle:'Clique une stat pour comprendre impact + contre', icon:Icons.bar_chart_rounded, child:Column(children:keys.map((k)=>ListTile(
    contentPadding:EdgeInsets.zero,
    title:Text(labelStat(k), style:const TextStyle(fontWeight:FontWeight.w900)),
    subtitle:Text(_statImpact(k), maxLines:2, overflow:TextOverflow.ellipsis),
    trailing:Text('${p.s[k] ?? 0}', style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:AppTheme.green)),
    onTap:()=>_showStatDetail(context,k),
  )).toList()));

  Widget _playStylesHub(BuildContext context){
    final raw=p.playstyles.where((x)=>x.trim().isNotEmpty).toSet().toList();
    final inferred=detectFc24PlayStyles(p).where((x)=>x.confidence>=82).map((x)=>x.name).where((x)=>!raw.contains(x)).toList();
    final ps=[...raw, ...inferred].toSet().toList();
    return UxTabSection(tabs:const ['Joueur','Déduits','Offensif','Passing','Défensif','Physical','GK'], height:610, children:[
      _playList(context, raw, title:'PlayStyles du joueur'),
      _playList(context, inferred, title:'PlayStyles déduits par stats'),
      _playList(context, ps.where((x)=>_playGroup(x)=='Offensif').toList(), title:'Offensif'),
      _playList(context, ps.where((x)=>_playGroup(x)=='Passing').toList(), title:'Passing'),
      _playList(context, ps.where((x)=>_playGroup(x)=='Défensif').toList(), title:'Défensif'),
      _playList(context, ps.where((x)=>_playGroup(x)=='Physical').toList(), title:'Physical'),
      _playList(context, ps.where((x)=>_playGroup(x)=='GK').toList(), title:'GK'),
    ]);
  }

  Widget _playList(BuildContext context,List<String> ps,{String title='PlayStyles'})=>ProBox(title:title, subtitle:'Impact gameplay + situations idéales + contres', icon:Icons.auto_awesome_rounded, child: ps.isEmpty ? const Text('Aucun PlayStyle détecté dans cette catégorie.') : Column(children:ps.map((x)=>ListTile(contentPadding:EdgeInsets.zero, leading:const Icon(Icons.bolt_rounded,color:AppTheme.green), title:Text(x,style:const TextStyle(fontWeight:FontWeight.w900)), subtitle:Text(_playImpact(x), maxLines:2, overflow:TextOverflow.ellipsis), onTap:()=>_showPlayDetail(context,x))).toList()));

  Widget _traitsHub(BuildContext context){
    final actual=p.playstyles.where((x)=>x.trim().isNotEmpty).toList();
    return UxTabSection(tabs:const ['Traits joueur','Spécialités','Impact'], height:420, children:[
      ProBox(title:'Traits / PlayStyles DB', subtitle:'Ce qui est réellement attaché au joueur', icon:Icons.extension_rounded, child:Wrap(spacing:8,runSpacing:8, children:actual.isEmpty?[const Chip(label:Text('Aucun trait DB'))]:actual.map((x)=>ActionChip(label:Text(x), onPressed:()=>_showPlayDetail(context,x))).toList())),
      ProBox(title:'Spécialités probables', subtitle:'Lecture depuis stats + rôle', icon:Icons.stars_rounded, child:Wrap(spacing:8,runSpacing:8, children:_topStats(p).map((x)=>Chip(label:Text(x))).toList())),
      ProBox(title:'Impact traits', subtitle:'Comment les lire', icon:Icons.psychology_rounded, child:const Text('Les traits et PlayStyles influencent animations, choix IA, réussite des gestes et comportement sans ballon. Pour décider, croise toujours avec les stats et le type de duel.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
    ]);
  }

  Widget _analysisHub(BuildContext context)=>Column(children:[
    _useBox(), _weakBox(),
    ProBox(title:'Meilleur rôle', subtitle:'Rôle conseillé selon poste/stats/playstyles', icon:Icons.assignment_ind_rounded, child:Text(_bestRole(), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
    ProBox(title:'À éviter avec ce joueur', subtitle:'Choisis les duels intelligemment', icon:Icons.warning_amber_rounded, child:Text(_avoidText(), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
  ]);

  Widget _duelsHub(BuildContext context)=>ProBox(title:'Duels recommandés', subtitle:'Clique un mode pour voir pourquoi il correspond', icon:Icons.sports_mma_rounded, child:Column(children:modes.take(18).map((m){final s=score(p,m);return ListTile(contentPadding:EdgeInsets.zero,title:Text(m.label,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(m.desc),trailing:Text('${s.total}',style:const TextStyle(fontWeight:FontWeight.w900,color:AppTheme.green)),onTap:()=>showUxDetailModal(context,m.label,[ProBox(title:'Stats utilisées', subtitle:'Poids dans le duel', icon:Icons.tune_rounded, child:Wrap(spacing:8,runSpacing:8,children:m.w.entries.map((e)=>Chip(label:Text('${labelStat(e.key)} ${(e.value*100).round()}% • ${p.s[e.key]??0}'))).toList())), _useBox()]));}).toList()));

  Widget _countersHub(BuildContext context){
    final rows=_counterPlayers().take(12).toList();
    return ProBox(title:'Counter Players', subtitle:'Profils capables de le neutraliser', icon:Icons.shield_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text('Pour contrer ${p.name}, cherche : ${_counterProfile()}', style:const TextStyle(height:1.45,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),
      if(rows.isEmpty) Wrap(spacing:8,runSpacing:8, children:_counterChips().map((x)=>Chip(label:Text(x))).toList()) else ...rows.map((x)=>ListTile(contentPadding:EdgeInsets.zero, leading:PlayerAvatar(p:x,size:38), title:Text(x.name,style:const TextStyle(fontWeight:FontWeight.w900)), subtitle:Text('${x.team} • ${x.pos} • ${_counterWhy(x)}'), trailing:Text('${_counterScore(x)}',style:const TextStyle(color:AppTheme.green,fontWeight:FontWeight.w900)), onTap:()=>showPlayerDetails(context,x))),
    ]));
  }

  Widget _similarHub(BuildContext context){
    final rows=_similarPlayers().take(12).toList();
    return ProBox(title:'Similar Players', subtitle:'Joueurs similaires calculés depuis poste/stats/profil', icon:Icons.group_work_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      if(rows.isEmpty) Text('Recherche un joueur avec : ${p.pos}, ${p.body}, ${p.accel}, stats fortes ${_topStats(p).take(3).join(', ')}.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))
      else ...rows.map((x)=>ListTile(contentPadding:EdgeInsets.zero, leading:PlayerAvatar(p:x,size:38), title:Text(x.name,style:const TextStyle(fontWeight:FontWeight.w900)), subtitle:Text('${x.team} • ${x.pos} • similarité ${_similarity(x)}%'), trailing:const Icon(Icons.open_in_new_rounded), onTap:()=>showPlayerDetails(context,x))),
    ]));
  }

  Widget _historyHub(BuildContext context)=>ProBox(title:'Historique joueur', subtitle:'Zone prête pour comparaisons/simulations récentes', icon:Icons.history_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:const[
    ListTile(contentPadding:EdgeInsets.zero, leading:Icon(Icons.compare_arrows_rounded), title:Text('Comparaisons récentes'), subtitle:Text('Les prochains workflows peuvent enregistrer ici les derniers duels.')),
    ListTile(contentPadding:EdgeInsets.zero, leading:Icon(Icons.sports_soccer_rounded), title:Text('Tactical Lab'), subtitle:Text('Scénarios sauvegardés où ce joueur est utilisé.')),
    ListTile(contentPadding:EdgeInsets.zero, leading:Icon(Icons.star_rounded), title:Text('Favoris'), subtitle:Text('Épingler ce joueur dans le dashboard/workspace.')),
  ]));

  Widget _useBox()=>ProBox(title:'Comment l’utiliser', subtitle:'Plan coach', icon:Icons.check_circle_rounded, child:Text('Utilise ${p.name} dans ses duels forts : ${coachStrengths(p)}. Cherche à l’isoler dans son meilleur rôle, avec soutien proche et angle favorable.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w800)));
  Widget _weakBox()=>ProBox(title:'Faiblesses à cibler', subtitle:'Ce que l’adversaire peut exploiter', icon:Icons.warning_amber_rounded, child:Text(coachWeaknesses(p), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800)));
  Widget _topStatBox(BuildContext context)=>ProBox(title:'Top stats', subtitle:'Clique une stat depuis l’onglet Stats pour plus de détails', icon:Icons.leaderboard_rounded, child:Wrap(spacing:8,runSpacing:8,children:_topStats(p).map((x)=>Chip(label:Text(x))).toList()));

  void _showUseModal(BuildContext context)=>showUxDetailModal(context,'Analyse ${p.name}',[_useBox(),_weakBox(),ProBox(title:'Meilleur rôle', subtitle:'Lecture IA', icon:Icons.assignment_ind_rounded, child:Text(_bestRole(), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800)))]);

  void _showStatDetail(BuildContext context,String k)=>showUxDetailModal(context,labelStat(k),[
    ProBox(title:'Valeur joueur', subtitle:p.name, icon:Icons.leaderboard_rounded, child:MiniScore(p.name,p.s[k]??0,labelStat(k))),
    ProBox(title:'Impact gameplay', subtitle:'Ce que cette stat change', icon:Icons.bolt_rounded, child:Text(_statImpact(k), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
    ProBox(title:'Contre / synergie', subtitle:'Avec quoi la croiser', icon:Icons.hub_rounded, child:Text('Synergies : ${_statSynergy(k)}. Contres : ${_statCounter(k)}.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
  ]);

  void _showPlayDetail(BuildContext context,String x)=>showUxDetailModal(context,x,[
    ProBox(title:'Impact gameplay', subtitle:'PlayStyle / trait', icon:Icons.auto_awesome_rounded, child:Text(_playImpact(x), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
    ProBox(title:'Situations idéales', subtitle:'Quand l’utiliser', icon:Icons.sports_soccer_rounded, child:Text(_playUse(x), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
    ProBox(title:'À éviter', subtitle:'Contre-mesure', icon:Icons.warning_rounded, child:Text(_playAvoid(x), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
  ]);

  List<Player> _similarPlayers(){
    final src=allPlayers.where((x)=>x.id!=p.id && x.gender==p.gender).toList();
    src.sort((a,b)=>_similarity(b).compareTo(_similarity(a)));
    return src.where((x)=>_similarity(x)>=42).toList();
  }
  int _similarity(Player x){
    int score=0;
    if(x.pos==p.pos) score+=28; else if(x.pos.contains(p.pos) || p.pos.contains(x.pos)) score+=14;
    if(x.body==p.body) score+=10; if(x.accel==p.accel) score+=10; if(x.foot==p.foot) score+=6;
    for(final k in ['pac','sho','pas','dri','def','phy','acc','sprint','str','drib','tackle','inter','finish','shortp']){ score += (8 - ((x.s[k]??0)-(p.s[k]??0)).abs()).clamp(0,8); }
    final common=mergedPlayStyles(x).toSet().intersection(mergedPlayStyles(p).toSet()).length; score += common*5;
    return score.clamp(0,100);
  }
  List<Player> _counterPlayers(){
    final src=allPlayers.where((x)=>x.id!=p.id && x.gender==p.gender).toList();
    src.sort((a,b)=>_counterScore(b).compareTo(_counterScore(a)));
    return src.where((x)=>_counterScore(x)>=58).toList();
  }
  int _counterScore(Player x){
    final pp=p.pos.toUpperCase();
    if(pp.contains('ST')) return (((x.s['defaw']??0)*.24)+((x.s['tackle']??0)*.18)+((x.s['str']??0)*.18)+((x.s['head']??0)*.14)+((x.s['sprint']??0)*.14)+((x.s['block']??0)*.12)).round();
    if(pp.contains('W')) return (((x.s['acc']??0)*.18)+((x.s['sprint']??0)*.18)+((x.s['tackle']??0)*.22)+((x.s['inter']??0)*.18)+((x.s['defaw']??0)*.16)+((x.s['str']??0)*.08)).round();
    if(pp.contains('CM')||pp.contains('CDM')||pp.contains('CAM')) return (((x.s['inter']??0)*.24)+((x.s['defaw']??0)*.20)+((x.s['stam']??0)*.16)+((x.s['tackle']??0)*.16)+((x.s['react']??0)*.14)+((x.s['str']??0)*.10)).round();
    return (((x.s['defaw']??0)+ (x.s['tackle']??0)+ (x.s['inter']??0)+ (x.s['str']??0)+ (x.s['react']??0))/5).round();
  }
  String _counterWhy(Player x)=>'répond avec ${_counterChips().take(3).join(', ')}';

  List<String> _topStats(Player p){ final items=p.s.entries.where((e)=>e.value>0).toList()..sort((a,b)=>b.value.compareTo(a.value)); return items.take(6).map((e)=>'${labelStat(e.key)} ${e.value}').toList(); }
  String _coachProfile(Player p){ if(p.pos.toUpperCase().contains('GK')) return 'Lecture coach : gardien à juger sur réflexes, placement, plongeon et jeu au pied.'; if(p.pos.toUpperCase().contains('CB')) return 'Lecture coach : CB à lire sur vitesse longue, force, awareness, tacle et body type.'; if(p.pos.toUpperCase().contains('ST')) return 'Lecture coach : ST à lire sur finition, composure, appels, force et accélération.'; if(p.pos.toUpperCase().contains('W')) return 'Lecture coach : ailier à lire sur accélération, dribble, agilité, centre/finition et pied fort.'; if(p.pos.toUpperCase().contains('CM') || p.pos.toUpperCase().contains('CDM')) return 'Lecture coach : milieu à lire sur réactions, stamina, passes, interceptions et résistance pressing.'; return 'Lecture coach : utilise ses stats fortes dans le bon type de duel.'; }
  String _bestRole(){ if(p.pos.toUpperCase().contains('GK')) return 'Gardien : protège surface, lis face-à-face, évite relances risquées si kicking faible.'; if(p.pos.toUpperCase().contains('CB')) return 'Défenseur : couverture profondeur ou stoppeur selon pace/strength. Évite sorties trop hautes si agilité faible.'; if(p.pos.toUpperCase().contains('ST')) return 'Attaquant : point d’appui, appels profondeur ou finisseur selon force/vitesse/finition.'; if(p.pos.toUpperCase().contains('W')) return 'Ailier : isoler en 1v1, varier crochet/cutback/centre selon pied fort et stats.'; return 'Rôle hybride : adapte selon meilleur trio de stats et work rates.'; }
  String _avoidText()=> 'Évite les duels où ses stats clés sont sous 75. Si ses faiblesses sont ${coachWeaknesses(p)}, change de mode : soutien proche, passe rapide, renversement ou protection balle.';
  String _counterProfile(){ if(p.pos.toUpperCase().contains('W')) return 'latéral rapide avec jockey, tacle et interceptions'; if(p.pos.toUpperCase().contains('ST')) return 'CB fort avec awareness, vitesse longue, block et heading'; if(p.pos.toUpperCase().contains('CM')) return 'CDM avec interceptions, stamina, pressing et reactions'; return 'joueur avec stats défensives fortes dans son duel principal'; }
  List<String> _counterChips()=>['Def Awareness','Standing Tackle','Interceptions','Strength','Sprint Speed','Reactions','Jockey/Anticipate'];
  String _playGroup(String x){ final y=x.toLowerCase(); if(y.contains('pass')||y.contains('tiki')||y.contains('cross')) return 'Passing'; if(y.contains('block')||y.contains('intercept')||y.contains('anticip')||y.contains('jockey')||y.contains('slide')) return 'Défensif'; if(y.contains('aerial')||y.contains('press')||y.contains('relent')||y.contains('quick')) return 'Physical'; if(y.contains('gk')||y.contains('keeper')) return 'GK'; return 'Offensif'; }
  String _playImpact(String x)=>'Impact : $x améliore les animations et la réussite dans les situations liées. Il devient vraiment fort quand les stats clés du joueur sont déjà élevées.';
  String _playUse(String x)=>'Utilise-le dans son contexte naturel : bon angle, bon pied, soutien proche et duel isolé. Croise toujours avec les stats de l’onglet Stats.';
  String _playAvoid(String x)=>'Évite de forcer ce PlayStyle si l’adversaire possède le contre naturel : interception, tacle, block, body type ou vitesse supérieure.';
  String _statImpact(String k){ final n=labelStat(k); if(['acc','sprint','pac'].contains(k)) return '$n influence départ, profondeur, pressing et récupération après perte.'; if(['drib','ball','agi','bal','dri'].contains(k)) return '$n influence conduite, changements d’angle, conservation et sortie de pression.'; if(['defaw','tackle','inter','slide','block','def'].contains(k)) return '$n influence placement, timing défensif, tacle, couverture et interceptions.'; if(['finish','shot','longshot','comp','sho'].contains(k)) return '$n influence efficacité devant le but, tirs sous pression et choix de finition.'; if(['shortp','longp','vision','cross','pas'].contains(k)) return '$n influence création, passes verticales, centres, cutbacks et renversements.'; if(['str','agg','stam','jump','head','phy'].contains(k)) return '$n influence contact, duels aériens, volume et résistance.'; if(k.startsWith('gk')) return '$n influence les animations et la fiabilité du gardien.'; return '$n influence la réussite dans les duels où cette stat est pondérée.'; }
  String _statSynergy(String k)=> ['drib','ball','agi'].contains(k)?'Acceleration, Balance, Composure': ['defaw','tackle','inter'].contains(k)?'Reactions, Strength, Aggression': ['finish','shot'].contains(k)?'Composure, Positioning, Ball Control':'Reactions, Composure, Work rate';
  String _statCounter(String k)=> ['drib','ball','agi'].contains(k)?'Jockey, Standing Tackle, Defensive Awareness': ['finish','shot'].contains(k)?'Block, GK Reflexes, Defensive Awareness': ['cross','vision'].contains(k)?'Interceptions, Marking, Pressing':'Timing, angle, soutien défensif';
  Widget _heroBadge(String label, int value)=>Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:8), decoration:BoxDecoration(color:Colors.white.withOpacity(.14), borderRadius:BorderRadius.circular(16)), child:Column(children:[Text('$value', style:const TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:18)), Text(label, style:const TextStyle(color:Colors.white70, fontSize:11))]));
}

class _StatsCategory extends StatelessWidget {
  final String title; final List<String> keys; final Player p;
  const _StatsCategory({required this.title, required this.keys, required this.p});
  @override Widget build(BuildContext context) => ProBox(title:title, subtitle:'Stats FC24 catégorisées', icon:Icons.bar_chart_rounded, child:Column(children: keys.map((k)=>StatBar(label: labelStat(k), value: p.s[k] ?? 0)).toList()));
}

class PlayerTile extends StatelessWidget {
  final Player p; final VoidCallback? onTap;
  const PlayerTile({super.key, required this.p, this.onTap});
  @override Widget build(BuildContext context)=>Card(child: InkWell(
    borderRadius: BorderRadius.circular(24), onTap:onTap,
    child: Padding(padding: const EdgeInsets.all(12), child: Row(children:[
      PlayerAvatar(p:p, size:58), const SizedBox(width:12),
      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(p.name, maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(fontWeight:FontWeight.w900, fontSize:16)),
        Text('${p.team} • ${p.pos}${p.pos2.isNotEmpty ? ' / ${p.pos2}' : ''}', maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(color:AppTheme.muted)),
        const SizedBox(height:5),
        Wrap(spacing:6, runSpacing:4, children:[
          _tiny('${p.height}cm'), _tiny('${p.weight}kg'), _tiny(p.accel), _tiny(p.playstyles.isEmpty?'traits 0':'traits ${p.playstyles.length}'),
        ]),
      ])),
      const SizedBox(width:8),
      Container(width:52, height:52, decoration:BoxDecoration(shape:BoxShape.circle, gradient: const LinearGradient(colors:[Color(0xFF22C55E), Color(0xFF38BDF8)])), child:Center(child:Text('${p.ovr}', style: const TextStyle(color:Color(0xFF052E16), fontWeight:FontWeight.w900, fontSize:18)))),
    ])),
  ));
  Widget _tiny(String t)=>Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration:BoxDecoration(color: AppTheme.chip, borderRadius:BorderRadius.circular(999), border:Border.all(color: AppTheme.line)), child:Text(t, style: const TextStyle(fontSize:11, color:AppTheme.ink, fontWeight:FontWeight.w800)));
}




class TransferPlayerPage extends StatefulWidget {
  final List<Player> players;
  final List<TeamInfo> teams;
  final Future<void> Function(List<Player>, List<TeamInfo>) onSave;
  const TransferPlayerPage({super.key, required this.players, required this.teams, required this.onSave});
  @override State<TransferPlayerPage> createState()=>_TransferPlayerPageState();
}
class _TransferPlayerPageState extends State<TransferPlayerPage>{
  Player? selected;
  TeamInfo? target;
  String q='';
  bool addToXI=false;
  @override Widget build(BuildContext context){
    final teams=cleanTeamListForPlayers(widget.teams, widget.players);
    final players=cleanPlayerList(widget.players).where((p)=>q.trim().isEmpty || '${p.name} ${p.team} ${p.pos}'.toLowerCase().contains(q.toLowerCase())).take(120).toList();
    target ??= teams.isNotEmpty?teams.first:null;
    return ListView(padding:const EdgeInsets.all(14), children:[
      Header('Transfert joueur', 'Changer l’équipe d’un joueur sans casser le XI de départ de l’ancienne équipe'),
      ProBox(title:'Nouveau transfert', subtitle:'Le joueur est retiré du XI de l’ancienne équipe. Dans la nouvelle équipe il arrive remplaçant sauf si tu coches XI.', icon:Icons.swap_horiz_rounded, child:Column(children:[
        TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'Chercher joueur...'), onChanged:(v)=>setState(()=>q=v)),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(isExpanded:true, value:selected?.id, decoration:const InputDecoration(labelText:'Joueur à transférer'), items:players.map((p)=>DropdownMenuItem(value:p.id, child:Text('${p.name} • ${p.team} • ${p.pos}', overflow:TextOverflow.ellipsis))).toList(), onChanged:(id)=>setState(()=>selected=widget.players.firstWhere((p)=>p.id==id))),
        const SizedBox(height:8),
        DropdownButtonFormField<String>(isExpanded:true, value:target?.id, decoration:const InputDecoration(labelText:'Nouvelle équipe'), items:teams.map((t)=>DropdownMenuItem(value:t.id, child:Text('${t.name} • OVR ${t.overall}', overflow:TextOverflow.ellipsis))).toList(), onChanged:(id)=>setState(()=>target=teams.firstWhere((t)=>t.id==id))),
        SwitchListTile(value:addToXI, onChanged:(v)=>setState(()=>addToXI=v), title:const Text('Ajouter directement au XI de départ'), subtitle:const Text('Si le XI a déjà 11 joueurs, le moins bien noté du même groupe/poste sort en remplaçant.')),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:selected==null||target==null?null:()=>_transfer(context), icon:const Icon(Icons.check_rounded), label:const Text('Valider transfert')),
      ])),
      const SizedBox(height:12),
      if(selected!=null) _transferPreview(selected!, target),
    ]);
  }
  Widget _transferPreview(Player p, TeamInfo? t)=>ProBox(title:'Aperçu', subtitle:'Impact équipe ancienne/nouvelle', icon:Icons.visibility_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
    ListTile(contentPadding:EdgeInsets.zero, leading:PlayerAvatar(p:p,size:44), title:Text(p.name), subtitle:Text('Actuel : ${p.team} • ${p.pos} • OVR ${p.ovr}')),
    Text('Vers : ${t?.name ?? '—'}', style:const TextStyle(fontWeight:FontWeight.w900)),
    const SizedBox(height:6),
    const Text('Ancienne équipe : supprimé du XI si présent. Nouvelle équipe : remplaçant par défaut, XI seulement si option cochée.', style:TextStyle(color:AppTheme.muted,fontWeight:FontWeight.w700,height:1.3)),
  ]));
  Future<void> _transfer(BuildContext context) async {
    final p=selected!, t=target!;
    final oldTeamId=p.teamId;
    final ps=widget.players.map((x)=>x.id==p.id?x.copyWith(team:t.name, teamId:t.id):x).toList();
    final ts=widget.teams.map((team){
      var xi=List<String>.from(team.xi)..removeWhere((id)=>id==p.id);
      if(team.id==t.id && addToXI){
        if(!xi.contains(p.id)) xi.add(p.id);
        if(xi.length>11){
          final byId={for(final pp in ps) pp.id:pp};
          final transferred=byId[p.id];
          final group=transferred==null?'ATT':_roleGroup(transferred);
          final same=xi.where((id)=>id!=p.id && byId[id]!=null && _roleGroup(byId[id]!)==group).toList();
          String removeId;
          if(same.isNotEmpty){ same.sort((a,b)=>(byId[a]!.ovr).compareTo(byId[b]!.ovr)); removeId=same.first; }
          else { final others=xi.where((id)=>id!=p.id && byId[id]!=null).toList()..sort((a,b)=>(byId[a]!.ovr).compareTo(byId[b]!.ovr)); removeId=others.isNotEmpty?others.first:xi.first; }
          xi.remove(removeId);
        }
      }
      if(team.id==oldTeamId || team.id==t.id) return team.copyWith(xi:xi);
      return team;
    }).toList();
    await widget.onSave(ps, ts);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${p.name} transféré vers ${t.name}')));
  }
}

class StartingXIManagerPage extends StatefulWidget{
  final List<Player> players; final List<TeamInfo> teams; final Future<void> Function(List<TeamInfo>) onSave;
  const StartingXIManagerPage({super.key, required this.players, required this.teams, required this.onSave});
  @override State<StartingXIManagerPage> createState()=>_StartingXIManagerPageState();
}
class _StartingXIManagerPageState extends State<StartingXIManagerPage>{
  TeamInfo? team; late List<String> xi;
  @override void initState(){ super.initState(); xi=[]; }
  void _loadTeam(TeamInfo t){ final squad=_teamSquad(t, cleanPlayerList(widget.players)); team=t; xi=List<String>.from(t.xi); if(xi.isEmpty) xi=squad.take(11).map((p)=>p.id).toList(); setState((){}); }
  @override Widget build(BuildContext context){
    final teams=cleanTeamListForPlayers(widget.teams, widget.players);
    team ??= teams.isNotEmpty?teams.first:null;
    if(team!=null && xi.isEmpty) { final squad=_teamSquad(team!, cleanPlayerList(widget.players)); xi=team!.xi.isEmpty?squad.take(11).map((p)=>p.id).toList():List<String>.from(team!.xi); }
    final t=team;
    if(t==null) return const Center(child:Text('Aucune équipe'));
    final squad=_teamSquad(t, cleanPlayerList(widget.players));
    final xiPlayers=xi.map((id)=>squad.firstWhere((p)=>p.id==id, orElse:()=>widget.players.firstWhere((p)=>p.id==id, orElse:()=>squad.first))).where((p)=>squad.any((x)=>x.id==p.id)).toList();
    final bench=squad.where((p)=>!xi.contains(p.id)).toList();
    return ListView(padding:const EdgeInsets.all(14), children:[
      Header('Gérer les 11 départ', 'Définir le XI titulaire de chaque équipe et garder les autres en remplaçants'),
      TeamAutocomplete(teams:teams, value:t.name, label:'Équipe', onSelected:(name){ final m=findTeamByAutocomplete(teams,name); if(m!=null) _loadTeam(m); }),
      const SizedBox(height:12),
      ProBox(title:'XI départ (${xiPlayers.length}/11)', subtitle:'Clique un joueur du XI pour le sortir. Clique un remplaçant pour l’ajouter.', icon:Icons.format_list_numbered_rounded, child:Column(children:[
        ...xiPlayers.map((p)=>ListTile(leading:PlayerAvatar(p:p,size:36), title:Text(p.name), subtitle:Text('${p.pos} • OVR ${p.ovr}'), trailing:IconButton(icon:const Icon(Icons.remove_circle_outline), onPressed:()=>setState(()=>xi.remove(p.id))))),
        const Divider(),
        Align(alignment:Alignment.centerRight, child:FilledButton.icon(onPressed:xiPlayers.length==11?()=>_save(t):null, icon:const Icon(Icons.save_rounded), label:const Text('Sauvegarder XI'))),
      ])),
      const SizedBox(height:12),
      ProBox(title:'Remplaçants / réserve', subtitle:'Tous les joueurs de l’équipe non présents dans le XI', icon:Icons.groups_rounded, child:Column(children:bench.take(35).map((p)=>ListTile(leading:PlayerAvatar(p:p,size:34), title:Text(p.name), subtitle:Text('${p.pos} • OVR ${p.ovr}'), trailing:IconButton(icon:const Icon(Icons.add_circle_outline), onPressed:xi.length>=11?null:()=>setState(()=>xi.add(p.id))))).toList())),
    ]);
  }
  Future<void> _save(TeamInfo t) async { final ts=widget.teams.map((x)=>x.id==t.id?x.copyWith(xi:xi.take(11).toList()):x).toList(); await widget.onSave(ts); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('XI de départ sauvegardé'))); }
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
    final teams = cleanTeamListForPlayers(widget.teams, widget.players);
    team ??= teams.isNotEmpty ? teams.first : null;
    final t = team;
    if (t == null) return const Center(child: Text('Aucune équipe'));
    final squad = _teamSquad(t, cleanPlayerList(widget.players))..sort((a,b)=>b.ovr.compareTo(a.ovr));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Team Analyzer', 'Infos organisées en onglets pour éviter le scroll'),
      TeamAutocomplete(teams:teams, value:t.name, label:'Équipe homme par défaut — autocomplete', onSelected:(name){
        final m=findTeamByAutocomplete(teams,name);
        if(m!=null) setState(()=>team=m);
      }),
      const SizedBox(height: 12),
      UxTabSection(height:620, tabs:const ['Overview','Forces','Faiblesses','Instructions','Joueurs'], children:[
        Column(children:[GestureDetector(onTap:()=>showTeamDetails(context,t,widget.players), child: TeamCard(team: t, players: widget.players, onEdit: ()=>showTeamDetails(context,t,widget.players))), const SizedBox(height:12), ProBox(title:'Rapport coach complet', subtitle:'Résumé actionnable', icon:Icons.psychology_alt_rounded, child:Text(teamCoachReport(t, widget.players), style:const TextStyle(height:1.45, fontWeight:FontWeight.w700)))]),
        Column(children:[TeamAnalyzerDeepReport(team:t, players:widget.players)]),
        Column(children:[ProTeamWeaknessReport(team:t, players:widget.players)]),
        Column(children:[TeamAnalyzerInstructions(team:t, players:widget.players)]),
        Column(children:[ProBox(title:'Joueurs clés', subtitle:'Top OVR de l’équipe + modal détail joueur', icon: Icons.stars_rounded, child: Column(children: squad.take(18).map((p)=>PlayerTile(p:p, onTap:()=>showPlayerDetails(context,p))).toList()))]),
      ]),
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
    final rows = cleanPlayerList(widget.players).where((p)=>pos=='all'||p.pos.toUpperCase().contains(pos)).map((p)=>(p:p, sc:score(p,m).total)).toList()..sort((a,b)=>b.sc.compareTo(a.sc));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Matchup Finder', 'Classe les meilleurs profils par situation'),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(value: mode, isExpanded: true, items: modes.map((x)=>DropdownMenuItem(value:x.key, child: Text(x.label, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>mode=v!), decoration: const InputDecoration(labelText:'Mode'))),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField<String>(value: pos, items: ['all','ST','LW','RW','CAM','CM','CDM','LB','RB','CB','GK'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>pos=v!), decoration: const InputDecoration(labelText:'Poste'))),
      ]),
      const SizedBox(height: 12),
      ProBox(title:'Lecture Coach du mode', subtitle:'Forces / faiblesses utilisées dans le classement', icon:Icons.psychology_rounded, child:Text('Mode ${m.label} : privilégie ${m.w.keys.map(labelStat).join(', ')}. Utilise ces profils pour profiter des faiblesses adverses, et clique un joueur pour voir comment le contrer.', style:const TextStyle(height:1.4, fontWeight:FontWeight.w700))),
      ...rows.take(80).map((x)=>PlayerTile(p:x.p, onTap:(){
        final opponents=cleanPlayerList(widget.players).where((o)=>o.id!=x.p.id && _isNaturalOpponent(x.p,o)).toList();
        final opp=opponents.isNotEmpty?opponents.first:refOpponentFor(x.p, cleanPlayerList(widget.players));
        showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>_ModeDetailSheet(a:x.p,b:opp,mode:m));
      })),
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
  String scenario='equal';
  String? formA, formB;
  Map<String,String> savedForms={};
  @override void initState(){ super.initState(); _loadForms(); }
  Future<void> _loadForms() async { final m=await LocalStore.loadTempFormations(); if(mounted) setState(()=>savedForms=m); }
  FormationPreset _preset(String? n, TeamInfo t, List<Player> xi){
    if(n==null || n=='auto') return _guessFormation(t, xi);
    return formationPresets.firstWhere((f)=>f.name==n, orElse:()=>_guessFormation(t, xi));
  }
  Future<void> _saveProvisional(TeamInfo ta, TeamInfo tb) async {
    final m=Map<String,String>.from(savedForms);
    if(formA!=null && formA!='auto') m[ta.id]=formA!;
    if(formB!=null && formB!='auto') m[tb.id]=formB!;
    await LocalStore.saveTempFormations(m);
    if(mounted) { setState(()=>savedForms=m); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Formation provisoire enregistrée'))); }
  }
  @override Widget build(BuildContext context) {
    final teams=cleanTeamListForPlayers(widget.teams, widget.players);
    a ??= teams.isNotEmpty ? teams.first : null;
    b ??= teams.length > 1 ? teams[1] : a;
    final ta=a, tb=b;
    if(ta==null || tb==null) return const Center(child: Text('Aucune équipe'));
    formA ??= savedForms[ta.id] ?? 'auto';
    formB ??= savedForms[tb.id] ?? 'auto';
    final sqA=_teamSquad(ta, cleanPlayerList(widget.players)).take(23).toList();
    final sqB=_teamSquad(tb, cleanPlayerList(widget.players)).take(23).toList();
    final presetA=_preset(formA, ta, sqA.take(11).toList());
    final presetB=_preset(formB, tb, sqB.take(11).toList());
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFF071225),Color(0xFF0B1728),Color(0xFFF3F7FB)])),
      child: ListView(padding: const EdgeInsets.all(14), children:[
        Header('Team vs Team Coach AI Pro', 'Plan complet : attaque, défense, pressing, weak links, game state'),
        _TeamVersusHero(a:ta,b:tb),
        const SizedBox(height:12),
        UxTabSection(
          height: 640,
          tabs: const ['Setup','Terrain','Duels','Attack','Defense','Counters','Advice'],
          children: [
            Column(children:[
              LayoutBuilder(builder:(context,c){
                Widget fieldA()=>TeamAutocomplete(teams:teams, value:ta.name, label:'Ton équipe', onSelected:(name){final m=findTeamByAutocomplete(teams,name); if(m!=null) setState((){a=m; formA=savedForms[m.id]??'auto';});});
                Widget fieldB()=>TeamAutocomplete(teams:teams, value:tb.name, label:'Adversaire', onSelected:(name){final m=findTeamByAutocomplete(teams,name); if(m!=null) setState((){b=m; formB=savedForms[m.id]??'auto';});});
                if(c.maxWidth<520) return Column(children:[fieldA(), const SizedBox(height:8), fieldB(), const SizedBox(height:8), _scenario()]);
                return Row(children:[Expanded(child:fieldA()), const SizedBox(width:8), Expanded(child:fieldB()), const SizedBox(width:8), Expanded(child:_scenario())]);
              }),
              const SizedBox(height:12),
              ProBox(title:'Formations provisoires du match', subtitle:'Change la formation sur le terrain sans modifier la DB.', icon:Icons.tune_rounded, child:Column(children:[
                Row(children:[Expanded(child:_formationDrop('Formation ${ta.name}', formA, (v)=>setState(()=>formA=v))), const SizedBox(width:8), Expanded(child:_formationDrop('Formation ${tb.name}', formB, (v)=>setState(()=>formB=v)))]),
                const SizedBox(height:8),
                Row(children:[Expanded(child:Chip(label:Text('${ta.name}: ${presetA.name}'))), const SizedBox(width:8), Expanded(child:Chip(label:Text('${tb.name}: ${presetB.name}')))]),
                Align(alignment:Alignment.centerRight, child:FilledButton.icon(onPressed:()=>_saveProvisional(ta,tb), icon:const Icon(Icons.save_rounded), label:const Text('Enregistrer provisoire'))),
              ])),
              const SizedBox(height:12),
              _TeamPhaseCard(a:ta,b:tb),
            ]),
            Column(children:[TeamVsTeamTacticalMap(a:ta,b:tb,players:widget.players,scenario:scenario, formationA:presetA, formationB:presetB)]),
            Column(children:[TeamVsTeamIaSimulatorParity(a:ta,b:tb,players:widget.players,scenario:scenario), const SizedBox(height:12), TeamVsTeamCorridorMatrix(a:ta,b:tb,players:widget.players), const SizedBox(height:12), _TeamLineupCompare(a:ta,b:tb,players:widget.players)]),
            Column(children:[TeamVsTeamPluginSections(a:ta,b:tb,players:widget.players,scenario:scenario)]),
            Column(children:[_PlayerAvoidanceCard(a:ta,b:tb,players:widget.players), const SizedBox(height:12), _TeamWeakLinksCard(a:ta,b:tb,players:widget.players)]),
            Column(children:[_TeamCoachPlanCard(a:ta,b:tb,players:widget.players,scenario:scenario)]),
            Column(children:[ProBox(title:'Lecture rapide coach', subtitle:'Résumé actionnable pour trouver l’info vite', icon:Icons.psychology_alt_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text('1. Va dans Terrain pour voir qui affronte qui.', style:TextStyle(fontWeight:FontWeight.w800)),
              Text('2. Va dans Duels pour ouvrir chaque détail de comparaison.', style:TextStyle(fontWeight:FontWeight.w800)),
              Text('3. Va dans Defense pour voir quoi éviter joueur par joueur.', style:TextStyle(fontWeight:FontWeight.w800)),
              Text('4. Va dans Counters pour changer plan selon score.', style:TextStyle(fontWeight:FontWeight.w800)),
            ]))]),
          ],
        ),
      ]),
    );
  }
  Widget _formationDrop(String label, String? value, ValueChanged<String?> onChanged)=>DropdownButtonFormField<String>(value:value??'auto', isExpanded:true, decoration:InputDecoration(labelText:label), items:[const DropdownMenuItem(value:'auto',child:Text('Auto depuis XI')), ...formationPresets.map((f)=>DropdownMenuItem(value:f.name,child:Text(f.name)))], onChanged:onChanged);
  Widget _scenario()=>DropdownButtonFormField<String>(value:scenario, decoration:const InputDecoration(labelText:'Scenario'), items:const [DropdownMenuItem(value:'equal',child:Text('Niveau proche')), DropdownMenuItem(value:'weak',child:Text('Adversaire plus faible')), DropdownMenuItem(value:'strong',child:Text('Adversaire plus fort'))], onChanged:(v)=>setState(()=>scenario=v??'equal'));
}

class _TeamVersusHero extends StatelessWidget {
  final TeamInfo a,b; const _TeamVersusHero({required this.a, required this.b});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(18), decoration:BoxDecoration(borderRadius:BorderRadius.circular(30), gradient:const LinearGradient(colors:[Color(0xFF101828),Color(0xFF111827)]), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.25), blurRadius:28, offset:Offset(0,12))]), child:Column(children:[
    Row(children:[Expanded(child:_team(a,Colors.redAccent)), Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white10,borderRadius:BorderRadius.circular(16)), child:const Text('VS',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900))), Expanded(child:_team(b,const Color(0xFF2F80FF), right:true))]),
    const SizedBox(height:14),
    _dual('Attaque vs Défense', a.attack, b.defense),
    _dual('Milieu vs Milieu', a.midfield, b.midfield),
    _dual('Défense vs Attaque', a.defense, b.attack),
    _dual('Overall', a.overall, b.overall),
  ]));
  Widget _team(TeamInfo t, Color color, {bool right=false})=>Column(crossAxisAlignment:right?CrossAxisAlignment.end:CrossAxisAlignment.start, children:[Container(width:54,height:54,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,color:color.withOpacity(.25),border:Border.all(color:color,width:2)),child:Text(t.name.substring(0,1).toUpperCase(),style:TextStyle(color:color,fontWeight:FontWeight.w900,fontSize:24))), const SizedBox(height:8), Text(t.name,maxLines:2,overflow:TextOverflow.ellipsis,textAlign:right?TextAlign.right:TextAlign.left,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:20)), Text('OVR ${t.overall} • ${t.manager}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xFFB7C9E8)))]);
  Widget _dual(String label, int av, int bv){ final total=max(1,av+bv); final pa=(av/total*100).round(); return Padding(padding:const EdgeInsets.only(top:10), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(color:Colors.white70,fontWeight:FontWeight.w800))), Text('$av - $bv',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))]), const SizedBox(height:5), ClipRRect(borderRadius:BorderRadius.circular(99), child:SizedBox(height:8, child:Row(children:[Expanded(flex:max(1,pa),child:Container(color:Colors.redAccent)), Expanded(flex:max(1,100-pa),child:Container(color:const Color(0xFF2F80FF)))]))) ])); }
}

class _TeamPhaseCard extends StatelessWidget { final TeamInfo a,b; const _TeamPhaseCard({required this.a, required this.b});
  @override Widget build(BuildContext context)=>ProBox(title:'Comparaison par phase', subtitle:'Attack plan • Pressing targets • Game state', icon:Icons.bar_chart_rounded, child:Column(children:[
    _line('Construire / relance', a.midfield+a.defense, b.midfield+b.attack),
    _line('Attaquer bloc bas', a.attack+a.midfield, b.defense+b.midfield),
    _line('Défendre transitions', a.defense+a.midfield, b.attack+b.midfield),
    _line('Centres / surface', a.attack+a.defense, b.defense+b.attack),
    _line('Pressing / récupération', a.midfield+a.attack, b.midfield+b.defense),
  ]));
  Widget _line(String label,int av,int bv){ final total=max(1,av+bv); final pa=(av/total*100).round(); final diff=av-bv; return Padding(padding:const EdgeInsets.only(bottom:14), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w900))), Text('${diff>=0?'+':''}$diff',style:TextStyle(fontWeight:FontWeight.w900,color:diff>=0?AppTheme.green:Colors.redAccent))]), const SizedBox(height:6), ClipRRect(borderRadius:BorderRadius.circular(99),child:SizedBox(height:9,child:Row(children:[Expanded(flex:max(1,pa),child:Container(color:AppTheme.green)), Expanded(flex:max(1,100-pa),child:Container(color:AppTheme.line))]))) ])); }
}



class _PitchPlayer {
  final Player p;
  final String role;
  final Offset spot;
  final bool opponent;
  const _PitchPlayer(this.p, this.role, this.spot, this.opponent);
}

FormationPreset _guessFormation(TeamInfo t, List<Player> squad) {
  final defs=squad.where((p)=>_roleGroup(p)=='DEF').length;
  final wings=squad.where((p)=>_isRole(p,['LW','RW','LM','RM','LWB','RWB'])).length;
  if(defs>=5) return formationPresets.firstWhere((f)=>f.name=='5-3-2');
  if(defs<=3 && wings>=2) return formationPresets.firstWhere((f)=>f.name=='3-4-2-1');
  if(squad.where((p)=>_isRole(p,['CAM'])).isNotEmpty) return formationPresets.firstWhere((f)=>f.name=='4-2-3-1');
  return formationPresets.firstWhere((f)=>f.name=='4-3-3');
}

String _roleGroup(Player p){
  final u=p.pos.toUpperCase();
  if(u.contains('GK')) return 'GK';
  if(u.contains('CB')||u.contains('LB')||u.contains('RB')||u.contains('LWB')||u.contains('RWB')) return 'DEF';
  if(u.contains('CDM')||u.contains('CM')||u.contains('CAM')) return 'MID';
  return 'ATT';
}

bool _isRole(Player p, List<String> roles){
  final parts=p.pos.toUpperCase().split(RegExp(r'[/, ]'));
  return roles.any((r)=>parts.contains(r) || p.pos.toUpperCase().contains(r));
}

List<_PitchPlayer> _assignToFormation(List<Player> squad, FormationPreset f, {required bool opponent}) {
  final remaining=[...squad.take(11)];
  final out=<_PitchPlayer>[];
  for(final e in f.spots.entries){
    Player? best;
    final r=e.key.replaceAll(RegExp(r'[0-9]'), '').toUpperCase();
    List<String> wanted;
    if(r=='GK') wanted=['GK'];
    else if(r.contains('CB')) wanted=['CB'];
    else if(r.contains('LB')||r.contains('LWB')) wanted=['LB','LWB','LM'];
    else if(r.contains('RB')||r.contains('RWB')) wanted=['RB','RWB','RM'];
    else if(r.contains('CDM')) wanted=['CDM','CM'];
    else if(r.contains('CAM')) wanted=['CAM','CM','CF'];
    else if(r.contains('CM')) wanted=['CM','CDM','CAM'];
    else if(r.contains('LW')||r.contains('LF')||r.contains('LM')) wanted=['LW','LM','LF'];
    else if(r.contains('RW')||r.contains('RF')||r.contains('RM')) wanted=['RW','RM','RF'];
    else wanted=['ST','CF'];
    final exact=remaining.where((p)=>_isRole(p,wanted)).toList()..sort((a,b)=>b.ovr.compareTo(a.ovr));
    best=exact.isNotEmpty?exact.first:(remaining..sort((a,b)=>b.ovr.compareTo(a.ovr))).firstOrNull;
    if(best!=null){
      remaining.remove(best);
      final spot=opponent ? Offset(1-e.value.dx, 1-e.value.dy) : e.value;
      out.add(_PitchPlayer(best,e.key,spot,opponent));
    }
  }
  return out;
}

extension _FirstOrNull<T> on List<T> { T? get firstOrNull => isEmpty ? null : first; }

List<(_PitchPlayer, _PitchPlayer, double)> _facePairs(List<_PitchPlayer> mine, List<_PitchPlayer> opp){
  final available=[...opp];
  final pairs=<(_PitchPlayer,_PitchPlayer,double)>[];
  for(final m in mine){
    if(available.isEmpty) break;
    available.sort((a,b){
      double da=(a.spot-m.spot).distance, db=(b.spot-m.spot).distance;
      final na=_isNaturalOpponent(m.p,a.p)?0:0.35;
      final nb=_isNaturalOpponent(m.p,b.p)?0:0.35;
      return (da+na).compareTo(db+nb);
    });
    final o=available.removeAt(0);
    pairs.add((m,o,(o.spot-m.spot).distance));
  }
  pairs.sort((a,b)=>a.$3.compareTo(b.$3));
  return pairs;
}

List<Mode> _duelModesForFace(Player x, Player y) {
  final key=autoMatchupFromPositions(x,y);
  final base=modesForMatchup(key).take(5).toList();
  final extra=<String>['dribble','defense','speed_short','speed_long','physical','pressing','interception','cutback','aerial','finish_pressure'];
  for(final k in extra){
    final m=modes.where((e)=>e.key==k).toList();
    if(m.isNotEmpty && !base.any((e)=>e.key==k)) base.add(m.first);
  }
  return base.take(9).toList();
}

class TeamVsTeamTacticalMap extends StatelessWidget { final TeamInfo a,b; final List<Player> players; final String scenario; final FormationPreset? formationA, formationB; const TeamVsTeamTacticalMap({super.key,required this.a,required this.b,required this.players,required this.scenario,this.formationA,this.formationB});
  @override Widget build(BuildContext context){
    final clean=cleanPlayerList(players);
    final fullA=_teamSquad(a, clean).take(23).toList();
    final fullB=_teamSquad(b, clean).take(23).toList();
    final pa=fullA.take(11).toList();
    final pb=fullB.take(11).toList();
    final fa=formationA ?? _guessFormation(a,pa), fb=formationB ?? _guessFormation(b,pb);
    final mine=_assignToFormation(pa,fa,opponent:false);
    final opp=_assignToFormation(pb,fb,opponent:true);
    final pairs=_facePairs(mine,opp);
    final weak=[...pairs]..sort((x,y){
      final mx=_duelModesForFace(x.$1.p,x.$2.p).first;
      final dx=score(x.$1.p,mx).total-score(x.$2.p,mx).total;
      final my=_duelModesForFace(y.$1.p,y.$2.p).first;
      final dy=score(y.$1.p,my).total-score(y.$2.p,my).total;
      return dx.compareTo(dy);
    });
    return ProBox(title:'Terrain tactique — formations face-à-face', subtitle:'Ton XI + formation adverse sur le même terrain, duels réels par proximité', icon:Icons.map_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Wrap(spacing:8, runSpacing:8, children:[Chip(label:Text('${a.name}: ${fa.name}')), Chip(label:Text('${b.name}: ${fb.name}')), Chip(label:Text('Duels face-à-face: ${pairs.length}'))]),
      const SizedBox(height:10),
      TeamPitchCompareView(mine:mine, opp:opp, pairs:pairs.take(6).toList()),
      const SizedBox(height:12),
      TerrainPlayerVsPlayerSelector(mine:fullA, opp:fullB),
      const SizedBox(height:12),
      Row(children:[Expanded(child:_legend(AppTheme.green,'Vert = zone à attaquer')), const SizedBox(width:6), Expanded(child:_legend(AppTheme.blue,'Bleu = joueur/zone à presser'))]),
      const SizedBox(height:6),
      _legend(Colors.redAccent,'Rouge = risque de transition / duel à éviter'),
      const SizedBox(height:12),
      const Text('Duels clés face-à-face', style:TextStyle(fontWeight:FontWeight.w900, fontSize:16)),
      const SizedBox(height:8),
      ...pairs.take(7).map((e)=>_faceDuelTile(context,e.$1.p,e.$2.p)),
      const Divider(height:22),
      Wrap(spacing:8, runSpacing:8, children:[
        if(weak.isNotEmpty) Chip(label:Text('Côté à viser: ${weak.first.$2.p.name}')),
        Chip(label:Text(scenario=='strong'?'Bloc médian + transitions':'Pressing + largeur')),
        Chip(label:Text('Évite duels perdus: ${weak.take(3).map((e)=>e.$1.p.name.split(' ').last).join(', ')}')),
      ]),
    ]));
  }
  Widget _legend(Color c,String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:8), decoration:BoxDecoration(color:c.withOpacity(.14), borderRadius:BorderRadius.circular(16), border:Border.all(color:c.withOpacity(.35))), child:Text(t, style:TextStyle(color:c, fontWeight:FontWeight.w900, fontSize:12)));
  Widget _faceDuelTile(BuildContext context, Player x, Player y){
    final ms=_duelModesForFace(x,y);
    final best=ms.first;
    final sx=score(x,best).total, sy=score(y,best).total;
    return Container(margin:const EdgeInsets.only(bottom:8), decoration:BoxDecoration(color:AppTheme.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppTheme.line)), child:ListTile(
      leading:PlayerAvatar(p:x,size:40), trailing:PlayerAvatar(p:y,size:40),
      title:Text('${x.pos} ${x.name}  vs  ${y.pos} ${y.name}', maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w900)),
      subtitle:Wrap(spacing:6, runSpacing:4, children:ms.take(4).map((m)=>Chip(label:Text('${m.label} ${score(x,m).total}-${score(y,m).total}', style:const TextStyle(fontSize:11)))).toList()),
      onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>FaceDuelModesSheet(a:x,b:y,modes:ms)),
    ));
  }
}


class TerrainPlayerVsPlayerSelector extends StatefulWidget{
  final List<Player> mine, opp;
  const TerrainPlayerVsPlayerSelector({super.key, required this.mine, required this.opp});
  @override State<TerrainPlayerVsPlayerSelector> createState()=>_TerrainPlayerVsPlayerSelectorState();
}
class _TerrainPlayerVsPlayerSelectorState extends State<TerrainPlayerVsPlayerSelector>{
  Player? a,b; String modeKey='auto';
  @override Widget build(BuildContext context){
    if(widget.mine.isEmpty || widget.opp.isEmpty) return const SizedBox.shrink();
    a ??= widget.mine.first; b ??= widget.opp.first;
    final modesList=_duelModesForFace(a!,b!);
    final selectedKey=(modeKey=='auto'||modesList.any((m)=>m.key==modeKey))?modeKey:'auto';
    final mode=selectedKey=='auto'?modesList.first:modes.firstWhere((m)=>m.key==selectedKey, orElse:()=>modesList.first);
    int sc(Player p)=>score(p,mode).total;
    return Container(padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:AppTheme.surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:AppTheme.line)), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      const Text('Comparer depuis le terrain', style:TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
      const SizedBox(height:6),
      const Text('Sélectionne un joueur de ton équipe et celui qui lui fait face, puis compare poste par poste.', style:TextStyle(color:AppTheme.muted,fontWeight:FontWeight.w700,height:1.3)),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:a!.id, isExpanded:true, decoration:const InputDecoration(labelText:'Ton joueur (XI + remplaçants)'), items:List.generate(widget.mine.length,(i){ final p=widget.mine[i]; return DropdownMenuItem(value:p.id, child:Text('${i<11?'XI':'SUB'} • ${p.pos} • ${p.name}', overflow:TextOverflow.ellipsis)); }), onChanged:(v)=>setState(()=>a=widget.mine.firstWhere((p)=>p.id==v))),
      const SizedBox(height:8),
      DropdownButtonFormField<String>(value:b!.id, isExpanded:true, decoration:const InputDecoration(labelText:'Adversaire (XI + remplaçants)'), items:List.generate(widget.opp.length,(i){ final p=widget.opp[i]; return DropdownMenuItem(value:p.id, child:Text('${i<11?'XI':'SUB'} • ${p.pos} • ${p.name}', overflow:TextOverflow.ellipsis)); }), onChanged:(v)=>setState(()=>b=widget.opp.firstWhere((p)=>p.id==v))),
      const SizedBox(height:8),
      DropdownButtonFormField<String>(value:selectedKey, isExpanded:true, decoration:const InputDecoration(labelText:'Mode de comparaison'), items:[const DropdownMenuItem(value:'auto', child:Text('Auto selon postes')), ...modesList.map((m)=>DropdownMenuItem(value:m.key, child:Text(m.label, overflow:TextOverflow.ellipsis)))], onChanged:(v)=>setState(()=>modeKey=v??'auto')),
      const SizedBox(height:10),
      Row(children:[Expanded(child:_smallScore(a!, sc(a!), AppTheme.green)), const SizedBox(width:8), Expanded(child:_smallScore(b!, sc(b!), AppTheme.blue))]),
      const SizedBox(height:8),
      OffDefComparisonCards(a:a!, b:b!),
      Align(alignment:Alignment.centerRight, child:TextButton.icon(icon:const Icon(Icons.open_in_full), label:const Text('Détail modal complet'), onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>FaceDuelModesSheet(a:a!,b:b!,modes:modesList))))
    ]));
  }
  Widget _smallScore(Player p,int v,Color c)=>Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:c.withOpacity(.10),borderRadius:BorderRadius.circular(16),border:Border.all(color:c.withOpacity(.35))), child:Row(children:[PlayerAvatar(p:p,size:34),const SizedBox(width:8),Expanded(child:Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900))),Text('$v',style:TextStyle(color:c,fontWeight:FontWeight.w900))]));
}


class OffDefComparisonCards extends StatelessWidget{
  final Player a,b;
  const OffDefComparisonCards({super.key, required this.a, required this.b});
  int v(Player p,String k)=>p.s[k]??0;
  @override Widget build(BuildContext context){
    final rows=<({String label,String ak,String bk,String advice})>[
      (label:'Dribble vs Tacle', ak:'drib', bk:'tackle', advice:'Si dribble > tacle : provoque 1v1/crochet. Sinon joue remise ou dédoublement.'),
      (label:'Agilité vs Jockey', ak:'agi', bk:'defaw', advice:'Si agilité gagne : changements de direction. Sinon évite conduite longue face à lui.'),
      (label:'Contrôle balle vs Interception', ak:'ball', bk:'inter', advice:'Si contrôle gagne : reçois entre les lignes. Sinon joue en une touche.'),
      (label:'Accélération vs Couverture', ak:'acc', bk:'acc', advice:'Teste le premier pas 0-10m, surtout après contrôle orienté.'),
      (label:'Sprint vs Profondeur déf.', ak:'sprint', bk:'sprint', advice:'Si tu gagnes : appels dans le dos. Sinon cherche appui-remise.'),
      (label:'Passe courte vs Pressing', ak:'shortpass', bk:'defaw', advice:'Si passe perd : évite relance courte sous pression, cherche côté opposé.'),
      (label:'Centre/Cutback vs Interception', ak:'cross', bk:'inter', advice:'Si centre perd : cutback tardif ou renversement.'),
      (label:'Finition vs Bloc/placement', ak:'finish', bk:'defaw', advice:'Si finition gagne : tir rapide. Sinon fixe puis décale.'),
      (label:'Physique offensif vs Force déf.', ak:'str', bk:'str', advice:'Si physique perd : évite épaule contre épaule.'),
      (label:'Aérien attaque vs Aérien défense', ak:'head', bk:'head', advice:'Si aérien perd : évite centres hauts et corners directs.'),
    ];
    return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      const Text('Stats offensives vs défensives', style:TextStyle(fontWeight:FontWeight.w900)),
      const SizedBox(height:4),
      const Text('Clique une ligne pour ouvrir le détail du duel et les consignes.', style:TextStyle(color:AppTheme.muted,fontWeight:FontWeight.w700,fontSize:12)),
      const SizedBox(height:8),
      ...rows.map((r){ final av=v(a,r.ak), bv=v(b,r.bk); final good=av>=bv; return InkWell(
        borderRadius:BorderRadius.circular(16),
        onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>OffDefMetricDetailSheet(a:a,b:b,label:r.label,ak:r.ak,bk:r.bk,advice:r.advice)),
        child:Container(margin:const EdgeInsets.only(bottom:8), padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:good?AppTheme.green.withOpacity(.08):AppTheme.danger.withOpacity(.08),borderRadius:BorderRadius.circular(16),border:Border.all(color:(good?AppTheme.green:AppTheme.danger).withOpacity(.28))), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Row(children:[Expanded(child:Text(r.label,style:const TextStyle(fontWeight:FontWeight.w900))),Text('$av - $bv',style:TextStyle(fontWeight:FontWeight.w900,color:good?AppTheme.green:AppTheme.danger)), const SizedBox(width:4), const Icon(Icons.open_in_new_rounded,size:15)]),
          const SizedBox(height:3),Text(r.advice,style:const TextStyle(color:AppTheme.muted,height:1.25,fontWeight:FontWeight.w700,fontSize:12)),
        ])),
      );}).toList(),
    ]);
  }
}

class OffDefMetricDetailSheet extends StatelessWidget{
  final Player a,b; final String label,ak,bk,advice;
  const OffDefMetricDetailSheet({super.key, required this.a, required this.b, required this.label, required this.ak, required this.bk, required this.advice});
  int v(Player p,String k)=>p.s[k]??0;
  @override Widget build(BuildContext context){
    final av=v(a,ak), bv=v(b,bk), diff=av-bv;
    final good=diff>=0;
    return DraggableScrollableSheet(initialChildSize:.68,minChildSize:.45,maxChildSize:.94,builder:(context,ctrl)=>Container(decoration:const BoxDecoration(color:AppTheme.bg,borderRadius:BorderRadius.vertical(top:Radius.circular(28))), child:ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
      Row(children:[Expanded(child:Text(label,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close))]),
      const SizedBox(height:8),
      Row(children:[Expanded(child:_playerScore(a, labelStat(ak), av, AppTheme.green)), const SizedBox(width:10), Expanded(child:_playerScore(b, labelStat(bk), bv, AppTheme.blue))]),
      const SizedBox(height:12),
      ProBox(title:good?'Avantage exploitable':'Danger / duel défavorable', subtitle:'Lecture coach', icon:good?Icons.trending_up_rounded:Icons.warning_amber_rounded, child:Text('${good?'Tu peux tenter ce duel.':'Évite de forcer ce duel.'}\n$advice\nDifférence : ${diff>=0?'+':''}$diff points.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w800))),
      const SizedBox(height:10),
      ProBox(title:'Stats liées à vérifier', subtitle:'Contexte autour du duel', icon:Icons.analytics_rounded, child:Column(children:[
        StatBar(label:labelStat(ak), value:av),
        StatBar(label:labelStat(bk), value:bv),
        StatBar(label:'Agilité / réaction ${a.name}', value:((a.s['agi']??0)+(a.s['react']??0))~/2),
        StatBar(label:'Placement / réaction ${b.name}', value:((b.s['defaw']??0)+(b.s['react']??0))~/2),
      ])),
      const SizedBox(height:10),
      FilledButton.icon(onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>FaceDuelModesSheet(a:a,b:b,modes:_duelModesForFace(a,b))), icon:const Icon(Icons.compare_arrows_rounded), label:const Text('Ouvrir comparaison complète')),
    ])));
  }
  Widget _playerScore(Player p,String stat,int value,Color c)=>Container(padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:c.withOpacity(.10), borderRadius:BorderRadius.circular(18), border:Border.all(color:c.withOpacity(.35))), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[PlayerAvatar(p:p,size:46), const SizedBox(height:8), Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900)), Text('${p.pos} • $stat',style:const TextStyle(color:AppTheme.muted,fontWeight:FontWeight.w700)), const SizedBox(height:6), Text('$value',style:TextStyle(color:c,fontSize:26,fontWeight:FontWeight.w900))]));
}



class TeamPitchCompareView extends StatelessWidget {
  final List<_PitchPlayer> mine, opp;
  final List<(_PitchPlayer, _PitchPlayer, double)> pairs;
  const TeamPitchCompareView({super.key, required this.mine, required this.opp, required this.pairs});

  _PitchPlayer? _pairedFor(_PitchPlayer pp) {
    for (final e in pairs) {
      if (e.$1.p.id == pp.p.id) return e.$2;
      if (e.$2.p.id == pp.p.id) return e.$1;
    }
    return null;
  }

  void _openFromPitch(BuildContext context, _PitchPlayer pp) {
    final other = _pairedFor(pp);
    if (other == null) { showPlayerDetails(context, pp.p); return; }
    final x = pp.opponent ? other.p : pp.p;
    final y = pp.opponent ? pp.p : other.p;
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>FaceDuelModesSheet(a:x,b:y,modes:_duelModesForFace(x,y)));
  }

  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,c){
    return Container(height:390, decoration:BoxDecoration(borderRadius:BorderRadius.circular(26), gradient:const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFF14532D), Color(0xFF15803D)])), child:Stack(children:[
      Positioned.fill(child:CustomPaint(painter:_PitchLines())),
      ...pairs.map((e)=>CustomPaint(size:Size(c.maxWidth,390), painter:_PairLinePainter(e.$1.spot,e.$2.spot))),
      for(final pp in opp) Positioned(left:pp.spot.dx*c.maxWidth-23, top:pp.spot.dy*390-23, child:_dot(pp, Colors.redAccent, context)),
      for(final pp in mine) Positioned(left:pp.spot.dx*c.maxWidth-23, top:pp.spot.dy*390-23, child:_dot(pp, AppTheme.blue, context)),
      Positioned(left:12, top:12, child:_tag('Ton équipe', AppTheme.blue)),
      Positioned(right:12, top:12, child:_tag('Adversaire', Colors.redAccent)),
      Positioned(left:12, bottom:12, right:12, child:Container(padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.black.withOpacity(.45), borderRadius:BorderRadius.circular(14)), child:const Text('Clique un joueur sur le terrain : ouverture directe du duel face-à-face le plus proche.', textAlign:TextAlign.center, style:TextStyle(color:Colors.white, fontWeight:FontWeight.w800, fontSize:12)))),
    ]));
  });
  Widget _dot(_PitchPlayer pp, Color c, BuildContext context)=>InkWell(onTap:()=>_openFromPitch(context, pp), child:Column(children:[Container(width:46,height:46,alignment:Alignment.center, decoration:BoxDecoration(shape:BoxShape.circle,color:c.withOpacity(.92),border:Border.all(color:Colors.white,width:2),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.25), blurRadius:10)]), child:Text(pp.role.replaceAll(RegExp(r'[0-9]'),''), style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:10))), Container(constraints:const BoxConstraints(maxWidth:78), padding:const EdgeInsets.symmetric(horizontal:5,vertical:2), decoration:BoxDecoration(color:Colors.black.withOpacity(.55), borderRadius:BorderRadius.circular(8)), child:Text(pp.p.name.replaceFirst('Player ', '#'), maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w800)))]));
  Widget _tag(String t, Color c)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration:BoxDecoration(color:c.withOpacity(.88), borderRadius:BorderRadius.circular(99)), child:Text(t, style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:12)));
}


class _PairLinePainter extends CustomPainter{
  final Offset a,b; _PairLinePainter(this.a,this.b);
  @override void paint(Canvas c, Size s){ final p=Paint()..color=Colors.white.withOpacity(.18)..strokeWidth=1.2..style=PaintingStyle.stroke; c.drawLine(Offset(a.dx*s.width,a.dy*s.height), Offset(b.dx*s.width,b.dy*s.height), p); }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class FaceDuelModesSheet extends StatelessWidget{
  final Player a,b; final List<Mode> modes;
  const FaceDuelModesSheet({super.key, required this.a, required this.b, required this.modes});
  @override Widget build(BuildContext context)=>DraggableScrollableSheet(initialChildSize:.82,minChildSize:.45,maxChildSize:.95,builder:(_,ctrl)=>Container(decoration:const BoxDecoration(color:AppTheme.card,borderRadius:BorderRadius.vertical(top:Radius.circular(28))), child:ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
    Row(children:[PlayerAvatar(p:a,size:48),const SizedBox(width:10),Expanded(child:Text('${a.name} vs ${b.name}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))),PlayerAvatar(p:b,size:48)]),
    const SizedBox(height:8), const Text('Tous les modes utiles pour ce face-à-face, pas seulement épaule contre épaule.', style:TextStyle(color:AppTheme.muted,fontWeight:FontWeight.w700)),
    const SizedBox(height:14),
    OffDefComparisonCards(a:a,b:b),
    const SizedBox(height:14),
    ...modes.map((m){ final sa=score(a,m), sb=score(b,m); final diff=sa.total-sb.total; return Container(margin:const EdgeInsets.only(bottom:10), padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:AppTheme.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:diff>=0?AppTheme.green.withOpacity(.35):AppTheme.danger.withOpacity(.35))), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(children:[Expanded(child:Text(m.label,style:const TextStyle(fontWeight:FontWeight.w900))), Text('${sa.total} - ${sb.total}',style:TextStyle(fontWeight:FontWeight.w900,color:diff>=0?AppTheme.green:AppTheme.danger))]),
      const SizedBox(height:6), Text(m.desc,style:const TextStyle(color:AppTheme.muted,height:1.3,fontWeight:FontWeight.w700)),
      const SizedBox(height:8), Wrap(spacing:6,runSpacing:4,children:m.w.keys.take(7).map((k)=>Chip(label:Text('${labelStat(k)} ${a.s[k]??0}/${b.s[k]??0}',style:const TextStyle(fontSize:11)))).toList()),
      Align(alignment:Alignment.centerRight, child:TextButton(onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>_ModeDetailSheet(a:a,b:b,mode:m)), child:const Text('Détail complet'))),
    ])); }).toList(),
  ])));
}

class TeamVsTeamPluginSections extends StatelessWidget{
  final TeamInfo a,b; final List<Player> players; final String scenario;
  const TeamVsTeamPluginSections({super.key, required this.a, required this.b, required this.players, required this.scenario});
  @override Widget build(BuildContext context){
    final mine=_teamSquad(a, cleanPlayerList(players)).take(11).toList();
    final opp=_teamSquad(b, cleanPlayerList(players)).take(11).toList();
    final mineP=_assignToFormation(mine,_guessFormation(a,mine),opponent:false);
    final oppP=_assignToFormation(opp,_guessFormation(b,opp),opponent:true);
    final pairs=_facePairs(mineP,oppP);
    final weak=pairs.where((e){ final m=_duelModesForFace(e.$1.p,e.$2.p).first; return score(e.$1.p,m).total < score(e.$2.p,m).total; }).toList();
    return Column(children:[
      ProBox(title:'Comment attaquer', subtitle:'Section plugin : zones + joueurs cibles + mode de duel', icon:Icons.check_circle_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        _bullet('Attaque rapidement la profondeur si tes ST/ailiers gagnent vitesse courte ou course longue.'),
        _bullet('Crée des surnombres sur le côté du défenseur adverse le plus faible en défense complète/jockey.'),
        if(weak.isNotEmpty) _bullet('Target ${weak.first.$2.p.name}: profil inférieur sur ${_duelModesForFace(weak.first.$1.p,weak.first.$2.p).first.label}.'),
        _bullet('Si centre aérien perdant, cherche cutback/offensif au sol plutôt que ballon haut.'),
      ])),
      const SizedBox(height:12),
      ProBox(title:'Comment défendre', subtitle:'Section plugin : lignes de passe, pressing, joueurs dangereux', icon:Icons.shield_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        ...pairs.take(6).map((e){ final op=e.$2.p; final modes=_duelModesForFace(e.$1.p,op); final best=modes.first; return _bullet('Surveille ${op.name} : coupe sa première option et prépare ${best.label.toLowerCase()}.'); }),
        _bullet('Coupe les passes vers CAM/ST face au jeu ; ne laisse pas recevoir entre lignes.'),
        _bullet('Si l’adversaire a plus de vitesse, protège l’axe et ne monte pas tes deux latéraux ensemble.'),
      ])),
      const SizedBox(height:12),
      ProBox(title:'Risques', subtitle:'Transitions, zones rouges et erreurs à éviter', icon:Icons.report_problem_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        _risk(weak.length>=4?'Plusieurs duels face-à-face défavorables : évite les 1v1 isolés et joue à deux.':'Pas de gros risque global, mais garde ta structure.'),
        _risk('Perte dans l’axe = danger immédiat : garde CDM derrière et recycle côté faible.'),
        _risk('Ne force pas centre haut si tes ST perdent aérien vs CB/GK.'),
      ])),
      const SizedBox(height:12),
      ProBox(title:'Plan selon le score', subtitle:'Game state comme plugin', icon:Icons.sports_esports_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        _bullet('Si tu mènes : réduis passes risquées, garde CDM derrière, attaque seulement sur transition claire.'),
        _bullet('Si tu perds : augmente largeur, presse leur joueur faible à la relance, attaque son côté faible plusieurs fois.'),
        _bullet('Premières 15 min : teste le côté faible avec 2-3 attaques avant de forcer l’axe.'),
        _bullet('Fin de match : si fatigue haute, privilégie joueurs frais sur couloirs et pressing déclenché après passe latérale.'),
      ])),
    ]);
  }
  Widget _bullet(String t)=>Padding(padding:const EdgeInsets.only(bottom:10), child:Row(crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('✅ ',style:TextStyle(fontSize:17)), Expanded(child:Text(t,style:const TextStyle(height:1.35,fontWeight:FontWeight.w700)))]));
  Widget _risk(String t)=>Padding(padding:const EdgeInsets.only(bottom:9), child:Row(crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('⚠️ ',style:TextStyle(fontSize:17)), Expanded(child:Text(t,style:const TextStyle(height:1.35,fontWeight:FontWeight.w700)))]));
}

class _PlayerAvoidanceCard extends StatelessWidget {
  final TeamInfo a,b; final List<Player> players;
  const _PlayerAvoidanceCard({required this.a, required this.b, required this.players});
  @override Widget build(BuildContext context){
    final mine=_teamSquad(a, cleanPlayerList(players)).take(11).toList();
    final opp=_teamSquad(b, cleanPlayerList(players)).take(11).toList();
    final pairs=_facePairs(_assignToFormation(mine,_guessFormation(a,mine),opponent:false), _assignToFormation(opp,_guessFormation(b,opp),opponent:true));
    return ProBox(title:'À éviter joueur par joueur', subtitle:'Basé sur les joueurs qui se font face, avec tous les modes : physique, vitesse, dribble, défense, aérien', icon:Icons.warning_amber_rounded, child:Column(children:pairs.take(9).map((e)=>_avoidTile(context,e.$1.p,e.$2.p)).toList()));
  }
  Widget _avoidTile(BuildContext context, Player x, Player y){
    final ms=_duelModesForFace(x,y);
    final losing=ms.where((m)=>score(y,m).total>score(x,m).total+4).toList();
    final main=ms.first;
    final sx=score(x,main).total, sy=score(y,main).total;
    final danger=losing.isNotEmpty;
    return InkWell(onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>FaceDuelModesSheet(a:x,b:y,modes:ms)), child:Container(margin:const EdgeInsets.only(bottom:9), padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:danger?Colors.redAccent.withOpacity(.10):AppTheme.surface, borderRadius:BorderRadius.circular(18), border:Border.all(color:danger?Colors.redAccent.withOpacity(.45):AppTheme.line)), child:Row(crossAxisAlignment:CrossAxisAlignment.start, children:[
      PlayerAvatar(p:x,size:38), const SizedBox(width:8),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text('${x.name} vs ${y.name}', maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w900)),
        Text('Évite : ${_avoidAdvice(x,y,ms)}', style:const TextStyle(color:AppTheme.muted, height:1.28, fontWeight:FontWeight.w700)),
        const SizedBox(height:5), Wrap(spacing:6, runSpacing:4, children:[Chip(label:Text('${main.label} $sx-$sy')), ...losing.take(2).map((m)=>Chip(label:Text('Perd ${m.label}', style:const TextStyle(fontSize:11))))]),
      ])),
      const SizedBox(width:6), PlayerAvatar(p:y,size:38),
    ])));
  }
  String _avoidAdvice(Player me, Player op, List<Mode> ms){
    int v(Player p,String k)=>p.s[k]??0;
    final tips=<String>[];
    if ((v(op,'str')+v(op,'phy')+op.weight) > (v(me,'str')+v(me,'phy')+me.weight+15)) tips.add('duels physiques/épaule contre épaule');
    if ((v(op,'sprint')+v(op,'acc')) > (v(me,'sprint')+v(me,'acc')+10)) tips.add('courses longues dans son couloir');
    if ((v(op,'agi')+v(op,'drib')+v(op,'ball')) > (v(me,'agi')+v(me,'drib')+v(me,'ball')+14)) tips.add('1v1 sans couverture/crochet intérieur');
    if ((v(op,'tackle')+v(op,'defaw')+v(op,'inter')) > (v(me,'drib')+v(me,'ball')+v(me,'comp')+8)) tips.add('conduite trop longue près de lui');
    if ((v(op,'jump')+v(op,'head')+op.height) > (v(me,'jump')+v(me,'head')+me.height+15)) tips.add('centres aériens sur sa zone');
    for(final m in ms){ if(score(op,m).total>score(me,m).total+8) tips.add('duel direct ${m.label.toLowerCase()}'); }
    if (tips.isEmpty) return 'rien de critique, mais varie rythme/pied fort et cherche le 2v1';
    return tips.toSet().take(4).join(' • ');
  }
}

class _TeamCoachPlanCard extends StatelessWidget { final TeamInfo a,b; final List<Player> players; final String scenario; const _TeamCoachPlanCard({required this.a,required this.b,required this.players,required this.scenario});
  @override Widget build(BuildContext context)=>_dark(title:'Plan Coach AI', icon:Icons.psychology_alt_rounded, children:[
    _section('Forces à exploiter', '${a.name}: ${teamCoachReport(a, players).split('Faiblesses').first.trim()}'),
    _section('Faiblesses adverses à viser', 'Cible les latéraux/CB les moins rapides, attaque espace CB-LB/RB, force ${b.name} à défendre les cutbacks.'),
    _section('Comment attaquer', scenario=='strong'?'Bloc médian, transitions rapides, cherche 3e homme et évite pertes axiales.':'Possession agressive, isole ailier fort, provoque 1v1 puis cutback.'),
    _section('Comment défendre', 'CDM devant les CB, latéral côté ballon prudent, ne presse pas seul. Ferme passe verticale et protège zone penalty spot.'),
    _section('Game state', 'Si tu mènes : baisse rythme, garde largeur. Si tu perds : augmente pressing et attaque côté faible avec overlap.'),
  ]);
  Widget _section(String t,String b)=>Padding(padding:const EdgeInsets.only(bottom:10), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(color:Color(0xFF8EEBC2),fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(b,style:const TextStyle(color:Color(0xFFB7C9E8),height:1.35,fontWeight:FontWeight.w700))]));
  Widget _dark({required String title, required IconData icon, required List<Widget> children})=>Container(padding:const EdgeInsets.all(16), decoration:BoxDecoration(color:const Color(0xFF061426),borderRadius:BorderRadius.circular(26),border:Border.all(color:const Color(0xFF284766))), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:const Color(0xFF34D399)),const SizedBox(width:8),Expanded(child:Text(title,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)))]),const SizedBox(height:12),...children]));
}

class _TeamWeakLinksCard extends StatelessWidget { final TeamInfo a,b; final List<Player> players; const _TeamWeakLinksCard({required this.a,required this.b,required this.players});
  @override Widget build(BuildContext context){ final bp=_teamSquad(b, cleanPlayerList(players)).take(18).toList(); final weak=[...bp]..sort((x,y)=>(x.s['pac']??0)+(x.s['phy']??0)+(x.s['def']??0) - ((y.s['pac']??0)+(y.s['phy']??0)+(y.s['def']??0))); return ProBox(title:'Pressing targets / weak links', subtitle:'Joueurs adverses à cibler', icon:Icons.location_searching_rounded, child:Column(children:weak.take(5).map((p)=>ListTile(leading:PlayerAvatar(p:p,size:42),title:Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis),subtitle:Text('Faiblesse : ${coachWeaknesses(p)}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:Text('${p.ovr}',style:const TextStyle(fontWeight:FontWeight.w900)),onTap:()=>openPlayer(context,p))).toList())); }
}

class _TeamLineupCompare extends StatelessWidget { final TeamInfo a,b; final List<Player> players; const _TeamLineupCompare({required this.a,required this.b,required this.players});
  @override Widget build(BuildContext context){ final pa=_teamSquad(a,cleanPlayerList(players)).take(18).toList(); final pb=_teamSquad(b,cleanPlayerList(players)).take(18).toList(); return ProBox(title:'XI + remplaçants comparés', subtitle:'Clique joueur pour détail — les 11 premiers = titulaires, puis SUB', icon:Icons.groups_rounded, child:Column(children:List.generate(max(pa.length,pb.length),(i){ final x=i<pa.length?pa[i]:null, y=i<pb.length?pb[i]:null; return Padding(padding:const EdgeInsets.only(bottom:8), child:Row(children:[Expanded(child:x==null?const SizedBox():_miniPlayer(context,x)), const SizedBox(width:8), Expanded(child:y==null?const SizedBox():_miniPlayer(context,y))])); }))); }
  Widget _miniPlayer(BuildContext context, Player p)=>InkWell(onTap:()=>openPlayer(context,p), child:Container(padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:AppTheme.surface,borderRadius:BorderRadius.circular(16),border:Border.all(color:AppTheme.line)), child:Row(children:[PlayerAvatar(p:p,size:32),const SizedBox(width:6),Expanded(child:Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800))),Text('${p.ovr}',style:const TextStyle(fontWeight:FontWeight.w900))])));
}


bool _isNaturalOpponent(Player a, Player b) {
  final ap=a.pos.toUpperCase(), bp=b.pos.toUpperCase();
  if ((ap.contains('LW')||ap.contains('RW')||ap.contains('LM')||ap.contains('RM')) && (bp.contains('LB')||bp.contains('RB')||bp.contains('LWB')||bp.contains('RWB')||bp.contains('CB'))) return true;
  if ((ap.contains('ST')||ap.contains('CF')) && (bp.contains('CB')||bp.contains('GK'))) return true;
  if ((ap.contains('CAM')||ap.contains('CM')) && (bp.contains('CDM')||bp.contains('CM')||bp.contains('CB'))) return true;
  if (ap.contains('CB') && (bp.contains('ST')||bp.contains('CF')||bp.contains('LW')||bp.contains('RW'))) return true;
  if ((ap.contains('LB')||ap.contains('RB')) && (bp.contains('LW')||bp.contains('RW')||bp.contains('LM')||bp.contains('RM'))) return true;
  return false;
}

Player refOpponentFor(Player p, List<Player> pool) {
  final opp=pool.where((o)=>o.id!=p.id && _isNaturalOpponent(p,o)).toList()..sort((a,b)=>b.ovr.compareTo(a.ovr));
  if (opp.isNotEmpty) return opp.first;
  return pool.firstWhere((o)=>o.id!=p.id, orElse:()=>p);
}

class TeamVsTeamIaSimulatorParity extends StatelessWidget {
  final TeamInfo a,b; final List<Player> players; final String scenario;
  const TeamVsTeamIaSimulatorParity({super.key, required this.a, required this.b, required this.players, required this.scenario});
  @override Widget build(BuildContext context){
    final pa=_teamSquad(a, cleanPlayerList(players)).take(11).toList();
    final pb=_teamSquad(b, cleanPlayerList(players)).take(11).toList();
    final homeScenario=_scenarioLabel(a,b,scenario);
    final awayScenario=_scenarioLabel(b,a,scenario);
    final build= _phaseScore(pa, ['shortp','longp','vision','comp','ball']);
    final press= _phaseScore(pb, ['stam','agg','acc','defaw','inter']);
    final transition= _phaseScore(pa, ['sprint','acc','longp','vision','drib']);
    final blockBreak= _phaseScore(pa, ['vision','shortp','comp','drib','ball']);
    return ProBox(title:'IA Simulator du plugin — Team vs Team', subtitle:'Scenario, phase, overlay terrain, duels et instructions automatiques', icon:Icons.auto_awesome_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Wrap(spacing:8, runSpacing:8, children:[Chip(label:Text('${a.name}: $homeScenario')), Chip(label:Text('${b.name}: $awayScenario')), Chip(label:Text(scenario=='strong'?'Plan prudent':'Plan actif'))]),
      const SizedBox(height:10),
      _simLine('Home build-up vs away pressing', build, press),
      _simLine('Transition rapide', transition, _phaseScore(pb,['sprint','acc','defaw','inter','stam'])),
      _simLine('Casser bloc bas', blockBreak, _phaseScore(pb,['defaw','inter','react','str','tackle'])),
      const Divider(height:22),
      _instruction('Phase build-up', build>=press?'Relance courte possible : triangle GK-CB-CDM, puis switch côté faible.':'Ne force pas court : utilise remise au GK, diagonale longue ou ST pivot.'),
      _instruction('Phase pressing adverse', press>build?'Évite passes molles dans l’axe, joue en une touche et attire leur premier rideau.':'Tu peux ressortir proprement, mais ne garde pas la balle avec CB lent.'),
      _instruction('Phase transition', transition>=78?'À la récupération, première passe verticale puis attaque espace CB-latéral.':'Garde le ballon 2 secondes, fais monter le bloc avant de chercher profondeur.'),
      _instruction('Overlay terrain', 'Cible côté faible, pressing target, risque contre et duel proche sont synchronisés avec les joueurs du XI.'),
    ]));
  }
  String _scenarioLabel(TeamInfo x, TeamInfo y, String manual){
    if(manual=='strong') return 'Opponent stronger';
    if(manual=='weak') return 'Opponent weaker';
    final diff=x.overall-y.overall;
    if(diff>=3) return 'Opponent weaker';
    if(diff<=-3) return 'Opponent stronger';
    return 'Equal level';
  }
  int _phaseScore(List<Player> ps, List<String> keys){
    if(ps.isEmpty) return 0;
    int total=0,count=0;
    for(final p in ps.take(11)){ for(final k in keys){ total+=p.s[k]??0; count++; }}
    return count==0?0:(total~/count);
  }
  Widget _simLine(String label, int av, int bv){ final diff=av-bv; final total=max(1,av+bv); final pa=(av/total*100).round(); return Padding(padding:const EdgeInsets.only(bottom:10), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w900))), Text('$av - $bv',style:TextStyle(fontWeight:FontWeight.w900,color:diff>=0?AppTheme.green:AppTheme.danger))]), const SizedBox(height:6), ClipRRect(borderRadius:BorderRadius.circular(99), child:SizedBox(height:8, child:Row(children:[Expanded(flex:max(1,pa),child:Container(color:AppTheme.green)), Expanded(flex:max(1,100-pa),child:Container(color:AppTheme.blue.withOpacity(.45)))])))])); }
  Widget _instruction(String t,String body)=>Padding(padding:const EdgeInsets.only(bottom:8), child:RichText(text:TextSpan(style:const TextStyle(color:AppTheme.muted,height:1.35,fontWeight:FontWeight.w700), children:[TextSpan(text:'$t : ', style:const TextStyle(color:AppTheme.ink,fontWeight:FontWeight.w900)), TextSpan(text:body)])));
}

class TeamVsTeamCorridorMatrix extends StatelessWidget {
  final TeamInfo a,b; final List<Player> players;
  const TeamVsTeamCorridorMatrix({super.key, required this.a, required this.b, required this.players});
  @override Widget build(BuildContext context){
    final pa=_teamSquad(a, cleanPlayerList(players)).take(18).toList();
    final pb=_teamSquad(b, cleanPlayerList(players)).take(18).toList();
    final rows=[
      ('Couloir gauche attaque', _roleScore(pa,['LW','LM','LB','LWB'],['acc','sprint','drib','cross']), _roleScore(pb,['RB','RWB','CB'],['defaw','tackle','acc','inter']), 'Attaque le RB/RWB si plus lent ; cherche cutback plutôt que centre forcé.'),
      ('Couloir droit attaque', _roleScore(pa,['RW','RM','RB','RWB'],['acc','sprint','drib','cross']), _roleScore(pb,['LB','LWB','CB'],['defaw','tackle','acc','inter']), 'Même logique côté droit : isoler ailier fort puis overlap/underlap.'),
      ('Axe création', _roleScore(pa,['CAM','CM','CDM'],['vision','shortp','comp','ball']), _roleScore(pb,['CDM','CM','CB'],['inter','defaw','react','tackle']), 'Si l’axe est fermé, attire puis switch. Si avantage, joue troisième homme.'),
      ('Surface / centres', _roleScore(pa,['ST','CF','LW','RW'],['head','jump','finish','react']), _roleScore(pb,['CB','GK'],['head','jump','defaw','gkref']), 'Si désavantage aérien, évite centres hauts et privilégie cutback.'),
      ('Transition défensive', _roleScore(pa,['CB','LB','RB','CDM'],['sprint','acc','defaw','inter']), _roleScore(pb,['ST','LW','RW','CAM'],['sprint','acc','drib','longp']), 'Si négatif, sécurise latéraux et garde CDM rester derrière.'),
    ];
    return ProBox(title:'Comparaison avancée par zones', subtitle:'Couloirs, axe, surface, transition — plus proche du plugin', icon:Icons.grid_view_rounded, child:Column(children:rows.map((r)=>_row(r.$1,r.$2,r.$3,r.$4)).toList()));
  }
  int _roleScore(List<Player> ps, List<String> roles, List<String> keys){
    final list=ps.where((p)=>roles.any((r)=>p.pos.toUpperCase().contains(r))).toList();
    final use=(list.isEmpty?ps:list).take(5).toList();
    int total=0,count=0;
    for(final p in use){ for(final k in keys){ total+=p.s[k]??0; count++; }}
    return count==0?0:total~/count;
  }
  Widget _row(String label,int av,int bv,String advice){
    final diff=av-bv;
    return Container(margin:const EdgeInsets.only(bottom:10), padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:AppTheme.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:diff>=0?AppTheme.green.withOpacity(.35):AppTheme.danger.withOpacity(.35))), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w900))), Text('$av - $bv',style:TextStyle(fontWeight:FontWeight.w900,color:diff>=0?AppTheme.green:AppTheme.danger))]),
      const SizedBox(height:5), Text(advice, style:const TextStyle(color:AppTheme.muted,height:1.3,fontWeight:FontWeight.w700)),
    ]));
  }
}

class TeamAnalyzerDeepReport extends StatelessWidget {
  final TeamInfo team; final List<Player> players;
  const TeamAnalyzerDeepReport({super.key, required this.team, required this.players});
  @override Widget build(BuildContext context){
    final squad=_teamSquad(team, cleanPlayerList(players)).take(18).toList();
    int avg(List<String> keys){int t=0,c=0; for(final p in squad){ for(final k in keys){t+=p.s[k]??0;c++;}} return c==0?0:t~/c;}
    final speed=avg(['acc','sprint']), build=avg(['shortp','longp','vision','comp']), def=avg(['defaw','inter','tackle']), aerial=avg(['jump','head','str']), press=avg(['stam','agg','acc','react']);
    final weak=[...squad]..sort((x,y)=>((x.s['acc']??0)+(x.s['defaw']??0)+(x.s['comp']??0)).compareTo((y.s['acc']??0)+(y.s['defaw']??0)+(y.s['comp']??0)));
    return ProBox(title:'Team Analyzer Pro+', subtitle:'Détails par phase + weak links + rôles terrain', icon:Icons.analytics_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      _metric('Vitesse / profondeur', speed), _metric('Build-up / passe', build), _metric('Bloc défensif', def), _metric('Aérien / surface', aerial), _metric('Pressing', press),
      const Divider(height:22),
      Text('Weak links fonctionnels', style:const TextStyle(fontWeight:FontWeight.w900)),
      ...weak.take(4).map((p)=>ListTile(contentPadding:EdgeInsets.zero, leading:PlayerAvatar(p:p,size:38), title:Text(p.name), subtitle:Text('${p.pos} • éviter de lui donner responsabilités : ${coachWeaknesses(p)}'), onTap:()=>showPlayerDetails(context,p))),
    ]));
  }
  Widget _metric(String label,int v)=>Padding(padding:const EdgeInsets.only(bottom:8), child:Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w800))), SizedBox(width:42,child:Text('$v',textAlign:TextAlign.end,style:TextStyle(fontWeight:FontWeight.w900,color:v>=80?AppTheme.green:v<70?AppTheme.danger:AppTheme.orange))), const SizedBox(width:8), Expanded(flex:2, child:ClipRRect(borderRadius:BorderRadius.circular(99), child:LinearProgressIndicator(value:v.clamp(0,100)/100, minHeight:8, backgroundColor:AppTheme.line)))]));
}

class TeamAnalyzerInstructions extends StatelessWidget {
  final TeamInfo team; final List<Player> players;
  const TeamAnalyzerInstructions({super.key, required this.team, required this.players});
  @override Widget build(BuildContext context){
    final squad=_teamSquad(team, cleanPlayerList(players)).take(11).toList();
    final fast=squad.where((p)=>(p.s['sprint']??0)>=84 || (p.s['pac']??0)>=84).toList();
    final passers=squad.where((p)=>(p.s['vision']??0)>=80 || (p.s['shortp']??0)>=82).toList();
    final defenders=squad.where((p)=>(p.s['defaw']??0)>=80 || (p.s['def']??0)>=80).toList();
    return ProBox(title:'Instructions tactiques recommandées', subtitle:'Réglages coach selon le profil réel de l’équipe', icon:Icons.rule_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      _tip('Attaque', fast.length>=3?'Largeur + profondeur : lance ${fast.take(2).map((p)=>p.name.split(' ').last).join(' / ')} dans le dos.':'Jeu plus patient : appui-remise et renversement, évite longs sprints répétés.'),
      _tip('Milieu', passers.length>=2?'Passe courte + troisième homme avec ${passers.take(2).map((p)=>p.name.split(' ').last).join(' / ')}.':'Simplifie la relance, ne force pas les passes verticales sous pression.'),
      _tip('Défense', defenders.length>=3?'Bloc compact possible, pressing déclenché après passe latérale.':'Évite ligne trop haute, garde CDM devant CB et défends la profondeur.'),
      _tip('À surveiller', 'Fatigue, côté faible après perte, duels aériens si tes CB/ST ne dominent pas taille + jump.'),
    ]));
  }
  Widget _tip(String t,String b)=>Padding(padding:const EdgeInsets.only(bottom:9), child:RichText(text:TextSpan(style:const TextStyle(color:AppTheme.muted,height:1.35,fontWeight:FontWeight.w700), children:[TextSpan(text:'$t : ', style:const TextStyle(color:AppTheme.ink,fontWeight:FontWeight.w900)), TextSpan(text:b)])));
}


class ManagersCoachPage extends StatelessWidget {
  final List<TeamInfo> teams; final List<Player> players;
  const ManagersCoachPage({super.key, required this.teams, required this.players});
  @override Widget build(BuildContext context){
    final list=cleanTeamList(teams).where((t)=>t.manager.trim().isNotEmpty && t.manager!='—').take(120).toList();
    return DefaultTabController(length:3, child:Column(children:[
      const Header('Managers Coach', 'Clique un manager pour détail : style, traits, fort/faible/égal'),
      const TabBar(isScrollable:true, tabs:[Tab(text:'Managers'), Tab(text:'Traits'), Tab(text:'Plans contre')]),
      Expanded(child:TabBarView(children:[
        ListView(padding:const EdgeInsets.all(14), children:list.map((t)=>ProBox(title:t.manager.isEmpty?'Manager inconnu':t.manager, subtitle:t.name, icon:Icons.manage_accounts_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Wrap(spacing:8, runSpacing:8, children:[Chip(label:Text(_managerStyle(t))), Chip(label:Text(_systemFor(t))), Chip(label:Text('OVR ${t.overall}'))]),
          const SizedBox(height:8),
          Text(_managerReport(t, players), style:const TextStyle(height:1.42, fontWeight:FontWeight.w700)),
          const SizedBox(height:10),
          FilledButton.icon(onPressed:()=>_openManagerDetail(context,t), icon:const Icon(Icons.open_in_new_rounded), label:const Text('Détail manager')),
        ]))).toList()),
        ListView(padding:const EdgeInsets.all(14), children:list.take(60).map((t)=>_traitsBox(t)).toList()),
        ListView(padding:const EdgeInsets.all(14), children:list.take(60).map((t)=>ProBox(title:'Plan contre ${t.name}', subtitle:t.manager, icon:Icons.shield_rounded, child:Text(_counterManagerText(t), style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))).toList()),
      ])),
    ]));
  }
  Widget _traitsBox(TeamInfo t)=>ProBox(title:t.name, subtitle:'Traits fort / faible / égal', icon:Icons.psychology_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
    _traitLine('Fort', t.strongTraits, AppTheme.green), const SizedBox(height:8),
    _traitLine('Faible', t.weakTraits, AppTheme.danger), const SizedBox(height:8),
    _traitLine('Égal', t.equalTraits, AppTheme.orange),
  ]));
  Widget _traitLine(String title,List<String> xs,Color c)=>Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(title, style:TextStyle(color:c,fontWeight:FontWeight.w900)), Wrap(spacing:8, runSpacing:8, children:(xs.isEmpty?['—']:xs).map((x)=>Chip(label:Text(x))).toList())]);
  void _openManagerDetail(BuildContext context,TeamInfo t){
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppTheme.bg,builder:(_)=>DraggableScrollableSheet(expand:false,initialChildSize:.82,maxChildSize:.95,builder:(_,ctrl)=>ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
      Header(t.manager.isEmpty?'Manager inconnu':t.manager, '${t.name} • ${_managerStyle(t)}'),
      _traitsBox(t),
      ProBox(title:'Lecture coach', subtitle:'Forces, faiblesses et égalité', icon:Icons.analytics_rounded, child:Text(_managerReport(t, players), style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ProBox(title:'Plan recommandé', subtitle:'Comment jouer contre ce manager', icon:Icons.tips_and_updates_rounded, child:Text(_counterManagerText(t), style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
    ])));
  }
  String _managerStyle(TeamInfo t)=> t.attack>=t.defense+4?'Attaque / pressing':t.defense>=t.attack+4?'Bloc solide':'Équilibré';
  String _systemFor(TeamInfo t)=> t.attack>=82?'4-3-3 / 4-2-3-1':t.defense>=82?'5-3-2 / 4-4-2 compact':'4-2-3-1 équilibré';
  String _managerReport(TeamInfo t,List<Player> players){
    final squad=_teamSquad(t, cleanPlayerList(players)).take(11).toList();
    final fast=squad.where((p)=>(p.s['pac']??0)>=84).length;
    final strong=squad.where((p)=>(p.s['phy']??0)>=80).length;
    return 'Style probable : ${_managerStyle(t)}. Système conseillé : ${_systemFor(t)}. Traits forts : ${(t.strongTraits.isEmpty?'—':t.strongTraits.join(', '))}. Traits faibles : ${(t.weakTraits.isEmpty?'—':t.weakTraits.join(', '))}. Hidden context : ${fast>=4?'danger profondeur/couloirs':'rythme plus lent'}, ${strong>=4?'gros impact physique':'moins dominant au contact'}.';
  }
  String _counterManagerText(TeamInfo t){
    final weak=t.weakTraits.isEmpty?'son côté faible / relanceur faible':t.weakTraits.take(3).join(', ');
    final strong=t.strongTraits.isEmpty?'ses points forts':t.strongTraits.take(3).join(', ');
    return 'À éviter : jouer exactement dans $strong. À cibler : $weak. Si son équipe presse haut, joue direct dans le dos. Si bloc bas, patience + renversements. Si égal, crée un duel isolé avec ton meilleur joueur et évite les pertes axiales.';
  }
}


class FormationCounterEnginePage extends StatefulWidget { final List<TeamInfo> teams; final List<Player> players; const FormationCounterEnginePage({super.key, required this.teams, required this.players}); @override State<FormationCounterEnginePage> createState()=>_FormationCounterEnginePageState(); }
class _FormationCounterEnginePageState extends State<FormationCounterEnginePage>{
  String formation='5-3-2';
  final List<String> pjFormations = ["4-1-3-2", "4-1-4-1", "4-2-3-1", "4-2-4", "4-3-1-2", "4-3-2-1", "4-3-3", "4-2-2-2", "4-1-2-1-2", "4-4-2", "4-4-1-1", "4-5-1", "3-1-4-2", "3-4-1-2", "3-4-2-1", "3-4-3", "3-5-2", "3-5-1-1", "5-2-1-2", "5-2-3", "5-3-2", "5-4-1", "5-2-2-1", "5-1-2-1-1", "4-2-1-3"];
  final counters=<String,List<String>>{
    '5-3-2':['3-4-1-2','4-2-3-1','4-3-3','4-2-4'],
    '5-4-1':['4-3-3','4-2-3-1','3-5-2'],
    '5-2-3':['4-2-3-1','4-4-2','3-5-2'],
    '4-3-3':['4-2-3-1','4-4-2 compact','3-5-2','4-1-4-1'],
    '4-2-3-1':['4-3-3','4-1-2-1-2','3-4-2-1','4-2-2-2'],
    '4-4-2':['4-2-3-1','4-3-3','3-5-2','4-1-2-1-2'],
    '3-5-2':['4-3-3','4-2-3-1','5-2-3'],
    '3-4-2-1':['4-3-3','4-2-3-1','5-3-2'],
    '4-2-4':['4-2-3-1','4-1-4-1','5-3-2'],
    '4-1-2-1-2':['4-3-3','3-5-2','4-2-3-1 Large'],
  };
  @override Widget build(BuildContext context)=>DefaultTabController(length:4, child:Column(children:[
    const Header('Formation Counter Engine', 'Alimenté avec les formations PJ + détails counters'),
    const TabBar(isScrollable:true, tabs:[Tab(text:'Choix'),Tab(text:'Counters'),Tab(text:'Détail'),Tab(text:'Toutes formations')]),
    Expanded(child:TabBarView(children:[
      ListView(padding:const EdgeInsets.all(14), children:[ProBox(title:'Formation adverse', subtitle:'Choisis le système à contrer', icon:Icons.account_tree_rounded, child:DropdownButtonFormField<String>(value:formation, decoration:const InputDecoration(labelText:'Système'), items:pjFormations.where((x)=>x!='-NONE-').map((f)=>DropdownMenuItem(value:f, child:Text(f))).toList(), onChanged:(v)=>setState(()=>formation=v!)))]),
      ListView(padding:const EdgeInsets.all(14), children:[ProBox(title:'Counters recommandés', subtitle:'Clique un counter pour détail', icon:Icons.bolt_rounded, child:Wrap(spacing:8, runSpacing:8, children:_recs(formation).map((x)=>ActionChip(label:Text(x), avatar:const Icon(Icons.open_in_new_rounded), onPressed:()=>_openCounter(context, formation, x))).toList()))]),
      ListView(padding:const EdgeInsets.all(14), children:[ProBox(title:'Rapport complet ${formation}', subtitle:'Attaquer / défendre / risques / score', icon:Icons.menu_book_rounded, child:Text(_counterText(formation), style:const TextStyle(height:1.45, fontWeight:FontWeight.w700)))]),
      ListView(padding:const EdgeInsets.all(14), children:[ProBox(title:'Formations disponibles PJ', subtitle:'${pjFormations.length} systèmes chargés', icon:Icons.dataset_rounded, child:Wrap(spacing:8, runSpacing:8, children:pjFormations.where((x)=>x!='-NONE-').map((x)=>ActionChip(label:Text(x), onPressed:()=>setState(()=>formation=x))).toList()))]),
    ])),
  ]));
  List<String> _recs(String f)=>counters[f] ?? _genericCounter(f);
  List<String> _genericCounter(String f){
    if(f.startsWith('5-')) return ['4-3-3','4-2-3-1','3-4-2-1'];
    if(f.startsWith('3-')) return ['4-3-3','4-2-3-1','5-2-3'];
    if(f.contains('4-4')) return ['4-2-3-1','3-5-2','4-3-3'];
    return ['4-2-3-1','4-3-3','4-4-2'];
  }
  void _openCounter(BuildContext context,String against,String counter){
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppTheme.bg,builder:(_)=>DraggableScrollableSheet(expand:false,initialChildSize:.82,maxChildSize:.95,builder:(_,ctrl)=>ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
      Header('$counter vs $against', 'Détail du counter recommandé'),
      ProBox(title:'Pourquoi ça marche', subtitle:'Logique terrain', icon:Icons.psychology_alt_rounded, child:Text(_why(against,counter), style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ProBox(title:'Instructions attaque', subtitle:'Ce que tu dois chercher', icon:Icons.flash_on_rounded, child:Text('1) Crée supériorité sur le côté faible. 2) Ne force pas l’axe si leur bloc est compact. 3) Utilise renversement puis cutback. 4) Si tu mènes, garde CDM derrière.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ProBox(title:'Instructions défense', subtitle:'Ce que tu dois protéger', icon:Icons.shield_rounded, child:Text('Protège transitions, coupe passe vers CAM/ST, oriente le porteur vers son pied faible et évite de sortir tes CB trop tôt.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
    ])));
  }
  String _why(String f,String c)=>'Le $c répond au $f en modifiant les distances entre lignes : plus de couverture contre profondeur, plus de largeur contre pistons, ou plus de présence axe contre double ST. Le but est de créer des duels favorables au lieu de comparer poste identique uniquement.';
  String _counterText(String f){
    if(f=='5-3-2') return 'Attaque les half-spaces derrière les pistons, évite les centres forcés si les CB sont grands, utilise renversement rapide + cutback. Défense : bloque les 2 ST avec CDM devant les CB. Counters forts : ${_recs(f).join(', ')}.';
    if(f=='4-3-3') return 'Ferme les ailes puis sors vite côté opposé. Attaque l’espace entre latéral et CB. Évite de perdre le ballon axe si les ailiers sont rapides. Counters : ${_recs(f).join(', ')}.';
    if(f=='4-2-3-1') return 'Attire les 2 CDM puis joue dans le dos. Utilise un CAM mobile. Défense : empêche la passe verticale vers CAM. Counters : ${_recs(f).join(', ')}.';
    if(f=='4-4-2') return 'Crée supériorité au milieu avec CAM/CDM. Évite longs ballons sur leurs deux ST si tes CB sont lents. Counters : ${_recs(f).join(', ')}.';
    return 'Plan générique : évalue largeur, densité axe, nombre de ST et pistons. Counters conseillés : ${_recs(f).join(', ')}. Attaque le déséquilibre, protège ta perte de balle et ajuste selon score.';
  }
}


class SituationsCoachPage extends StatelessWidget { final List<Player> players; const SituationsCoachPage({super.key, required this.players});
  @override Widget build(BuildContext context){
    final items=<Map<String,String>>[
      {'t':'Espace LB-CB / RB-CB','d':'Appel ST ou ailier intérieur dans le dos du latéral. Cherche passe laser ou une-deux. Évite si le CB est très rapide/Lengthy.','a':'Passe profondeur, appel croisé, timing après sortie du latéral.','e':'Évite dribble lent dans l’axe, centre forcé, passe tardive.'},
      {'t':'Cutback','d':'Gagne la ligne, temporise, passe en retrait penalty spot.','a':'Utilise ailier rapide + joueur libre zone penalty.','e':'Évite centre aérien si ton ST est plus petit ou si CB domine aérien.'},
      {'t':'Bloc bas','d':'Patience, renversement, frappe de loin seulement si Power Shot/Finesse.','a':'Largeur + passes courtes + décrochage CAM.','e':'Évite dribbles axe sans soutien et tirs forcés.'},
      {'t':'Pressing haut','d':'Déclenche sur mauvais contrôle, GK faible ou CB lent.','a':'Oriente vers côté faible puis deuxième presseur.','e':'Évite pressing seul avec un ST fatigué.'},
      {'t':'Milieux qui montent trop','d':'Attaque la zone devant les CB. Mets CDM rester derrière pour éviter contre.','a':'Passe verticale vers CAM/ST, une-deux rapide.','e':'Évite perdre ballon avec tes latéraux hauts.'},
      {'t':'Erreur FC24 fréquente','d':'Ne va pas face au joueur : coupe d’abord la ligne de passe et oriente vers côté faible.','a':'Jockey + couverture angle, pas tacle trop tôt.','e':'Évite sortir le CB principal hors ligne.'},
    ];
    return DefaultTabController(length:3, child:Column(children:[
      const Header('Situations Coach', 'Clique une situation pour détail complet'),
      const TabBar(isScrollable:true, tabs:[Tab(text:'Situations'),Tab(text:'Plans'),Tab(text:'À éviter')]),
      Expanded(child:TabBarView(children:[
        ListView(padding:const EdgeInsets.all(14), children:items.map((e)=>ProBox(title:e['t']!, subtitle:'Situation tactique', icon:Icons.sports_soccer_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(e['d']!, style:const TextStyle(height:1.45, fontWeight:FontWeight.w700)), const SizedBox(height:10), FilledButton.icon(onPressed:()=>_open(context,e), icon:const Icon(Icons.open_in_new), label:const Text('Voir détail'))]))).toList()),
        ListView(padding:const EdgeInsets.all(14), children:items.map((e)=>ProBox(title:e['t']!, subtitle:'Comment exploiter', icon:Icons.flash_on_rounded, child:Text(e['a']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))).toList()),
        ListView(padding:const EdgeInsets.all(14), children:items.map((e)=>ProBox(title:e['t']!, subtitle:'À éviter', icon:Icons.warning_amber_rounded, child:Text(e['e']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))).toList()),
      ])),
    ]));
  }
  void _open(BuildContext context, Map<String,String> e){
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppTheme.bg,builder:(_)=>DraggableScrollableSheet(expand:false,initialChildSize:.82,maxChildSize:.95,builder:(_,ctrl)=>ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
      Header(e['t']!, 'Détail coach'),
      ProBox(title:'Lecture situation', subtitle:'Pourquoi ça arrive', icon:Icons.visibility_rounded, child:Text(e['d']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ProBox(title:'Plan à appliquer', subtitle:'Actions terrain', icon:Icons.check_circle_rounded, child:Text(e['a']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ProBox(title:'À éviter', subtitle:'Risques FC24', icon:Icons.warning_rounded, child:Text(e['e']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
    ])));
  }
}


class StatsEncyclopediaPage extends StatelessWidget { const StatsEncyclopediaPage({super.key});
  @override Widget build(BuildContext context){
    final statRows=<Map<String,String>>[
      {'t':'Acceleration','g':'Vitesse 0-10m','i':'Impact : premier pas, pressing, crochet, appel court. Très important pour ailiers, latéraux, ST rapides et CDM qui sortent au pressing.','u':'Utilise-la pour créer l’écart sur le premier contrôle.','e':'Ne juge pas seulement la vitesse longue : un joueur avec grosse Acceleration peut gagner le duel même avec Sprint Speed plus bas.'},
      {'t':'Sprint Speed','g':'Course longue','i':'Impact : profondeur, retour défensif, contre-attaque, poursuite sur 20-40m.','u':'Cherche les espaces derrière la ligne ou les transitions rapides.','e':'Évite les longs sprints avec joueur lent contre défenseur rapide.'},
      {'t':'Agility','g':'Changement direction','i':'Impact : tourner vite, jockey, crochet court, sortie de pressing.','u':'Utilise petits dribbles, L1/R1 et changements courts.','e':'Évite les grands virages avec joueur peu agile.'},
      {'t':'Balance','g':'Stabilité','i':'Impact : rester debout après contact, garder ballon en pivot, résister au tacle.','u':'Bon pour protéger ballon et dribbler sous pression.','e':'Ne force pas les contacts si Balance + Strength sont faibles.'},
      {'t':'Ball Control','g':'Premier contrôle','i':'Impact : réception propre, contrôle orienté, demi-tour rapide.','u':'Important pour CAM/ST dos au jeu et sorties de balle.','e':'Évite passes fortes vers joueur avec Ball Control faible sous pression.'},
      {'t':'Dribbling','g':'Conduite balle','i':'Impact : qualité du 1v1, conduite serrée, capacité à éliminer.','u':'Compare contre Standing Tackle, Def Awareness, Jockey et Interceptions adverses.','e':'Ne dribble pas dans l’axe si le défenseur gagne tacle + interception.'},
      {'t':'Strength','g':'Physique','i':'Impact : épaule contre épaule, protection, duel CB/ST, aérien.','u':'Utilise pivot, corps entre ballon et adversaire.','e':'Évite duels physiques si ton joueur est dominé.'},
      {'t':'Aggression','g':'Intensité duel','i':'Impact : pressing, second ballon, volonté de récupérer.','u':'Fort pour CDM/CB en pressing et duel.','e':'Peut créer fautes/espaces si tu te jettes trop.'},
      {'t':'Def. Awareness','g':'Placement défensif','i':'Impact : marquage auto, couverture, fermeture angle, bloc bas.','u':'Très important contre cutback, appels et passes dans le dos.','e':'Évite défense manuelle trop agressive avec faible Awareness.'},
      {'t':'Interceptions','g':'Couper passes','i':'Impact : couper ligne, défendre cutback, bloquer passe verticale.','u':'Place CDM/CB dans les lignes de passe.','e':'Ne presse pas trop loin si tu perds la zone d’interception.'},
      {'t':'Standing Tackle','g':'Tacle debout','i':'Impact : gagner ballon proprement en face-à-face.','u':'Compare contre Dribbling, Agility, Balance et Ball Control.','e':'Évite tacle debout tardif contre Technical/Press Proven.'},
      {'t':'Sliding Tackle','g':'Tacle glissé','i':'Impact : dernier recours, blocage latéral, couper centre/tir.','u':'Utile sur aile ou situation désespérée.','e':'À éviter dans la surface ou contre joueur très agile.'},
      {'t':'Reactions','g':'Réactivité','i':'Impact : rebonds, ballons libres, timing défense/attaque.','u':'Très utile dans surface, pressing et duel aérien.','e':'Un joueur lent en reactions réagit moins bien aux seconds ballons.'},
      {'t':'Composure','g':'Sang-froid','i':'Impact : tir/passe sous pression, choix dans la surface.','u':'Favorise finisseurs et créateurs fiables en match serré.','e':'Évite tirs forcés avec Composure faible.'},
      {'t':'Finishing','g':'Finition','i':'Impact : précision face au but, surtout dans surface.','u':'Compare contre GK Reflexes/Positioning et Block des défenseurs.','e':'Ne confonds pas Shot Power et Finishing.'},
      {'t':'Shot Power','g':'Puissance tir','i':'Impact : frappes fortes, tirs de loin, angles fermés.','u':'Utile avec Power Shot / Low Driven.','e':'Sans Composure/Finishing, la puissance seule ne suffit pas.'},
      {'t':'Positioning','g':'Appels offensifs','i':'Impact : appels, placement dans surface, timing pour recevoir.','u':'Fort pour ST/ailiers qui attaquent le dos.','e':'Évite jeu statique si Positioning faible.'},
      {'t':'Vision','g':'Lecture offensive','i':'Impact : passe verticale, dernière passe, casser bloc bas.','u':'Utilise avec Short/Long Passing et Incisive Pass.','e':'Ne force pas passe difficile avec Vision faible.'},
      {'t':'Short Passing','g':'Passe courte','i':'Impact : combinaisons, sortie sous pressing, une-deux.','u':'Important pour CAM/CDM/CM.','e':'Attention aux passes rapides sous pression si stat faible.'},
      {'t':'Long Passing','g':'Passe longue','i':'Impact : transversales, passes profondeur, changement côté.','u':'Utile pour switch contre bloc compact.','e':'Évite longues passes avec faible Long Passing.'},
      {'t':'Crossing','g':'Centre / cutback','i':'Impact : centres, passes retrait, précision couloir.','u':'Compare contre Interceptions, Def Awareness, Aerial et Block.','e':'Ne centre pas si tes attaquants perdent aérien.'},
      {'t':'Heading Accuracy','g':'Tête','i':'Impact : précision tête sur centre/corner.','u':'À combiner avec Jumping, Strength et Positioning.','e':'Évite centres hauts si Heading/Jumping faibles.'},
      {'t':'Jumping','g':'Détente','i':'Impact : gagner duel aérien, corners, dégagements.','u':'Important CB/ST.','e':'Un joueur petit peut compenser un peu avec Jumping, mais pas toujours.'},
      {'t':'Stamina','g':'Volume','i':'Impact : pressing long, retours, latéraux, fin de match.','u':'Fort pour gegenpressing et overlap.','e':'Évite pressing constant avec stamina faible.'},
      {'t':'GK Reflexes','g':'Gardien réflexe','i':'Impact : arrêts rapides, tirs proches, face-à-face.','u':'Compare contre Finishing/Composure attaquant.','e':'Un GK bon au pied mais faible reflexes subit en surface.'},
      {'t':'GK Positioning','g':'Placement GK','i':'Impact : angles, sorties, lecture frappe.','u':'Très utile contre finesse/face-à-face.','e':'Positioning faible = angles ouverts.'},
    ];
    final playRows=<Map<String,String>>[
      {'t':'Finesse Shot','g':'Tir placé','i':'Améliore les frappes enroulées. Impact énorme avec bon Finishing, Curve, Composure.','u':'Cherche angle intérieur avec pied fort.','e':'Évite si défenseur bloque l’angle ou si mauvais pied.'},
      {'t':'Power Shot','g':'Tir puissant','i':'Rend les frappes lourdes plus dangereuses, surtout avec Shot Power et Composure.','u':'Utilise quand tu as espace avant frappe.','e':'À éviter si défenseur proche peut bloquer.'},
      {'t':'Chip Shot','g':'Lob','i':'Meilleur lob contre gardien sorti.','u':'À utiliser en 1v1 si GK rush out.','e':'Évite si GK reste bas.'},
      {'t':'Dead Ball','g':'Coups francs/corners','i':'Améliore précision et courbe sur arrêtés.','u':'Choisis ce joueur pour corners et CPA.','e':'Ne gaspille pas corners avec joueur sans Crossing/Curve.'},
      {'t':'Precision Header','g':'Têtes précises','i':'Améliore la finition de la tête.','u':'Centre sur lui, surtout 2e poteau.','e':'Évite centres bas si son avantage est aérien.'},
      {'t':'Incisive Pass','g':'Passe qui casse ligne','i':'Améliore passes dans le dos et dernières passes.','u':'Très fort contre bloc haut/ligne lente.','e':'Évite si receveur n’a pas vitesse/positioning.'},
      {'t':'Pinged Pass','g':'Passe tendue','i':'Passe rapide au sol, utile pour casser pressing.','u':'Joue vite entre lignes.','e':'Risque perte si receveur a mauvais contrôle.'},
      {'t':'Long Ball Pass','g':'Ballon long','i':'Meilleures transversales/profondeur.','u':'Switch côté faible.','e':'Évite contre défense très rapide si appel mal timé.'},
      {'t':'Tiki Taka','g':'Jeu court','i':'Améliore passes courtes rapides et remises.','u':'Combine en triangle sous pression.','e':'Ne force pas dans axe saturé.'},
      {'t':'Whipped Pass','g':'Centre fort','i':'Centres plus tendus et dangereux.','u':'Cherche ST fort tête/positioning.','e':'Évite si défense gagne aérien.'},
      {'t':'Technical','g':'Dribble technique','i':'Conduite plus fluide, fort en R1/dribble contrôlé.','u':'Isole contre défenseur lent/agility faible.','e':'Évite contact physique contre Bruiser/Block fort.'},
      {'t':'Rapid','g':'Sprint balle au pied','i':'Meilleure vitesse en conduite et appels.','u':'Attaque espace derrière latéral.','e':'Évite petits espaces sans Agility.'},
      {'t':'Quick Step','g':'Premier pas','i':'Explosion sur les premiers mètres.','u':'Utilise crochet + accélération.','e':'Si défenseur a Jockey/Anticipate, varie.'},
      {'t':'First Touch','g':'Contrôle initial','i':'Contrôle plus propre sous pression.','u':'Reçois dos au jeu puis oriente.','e':'Évite passe forte vers joueur sans First Touch.'},
      {'t':'Trickster','g':'Gestes techniques','i':'Animations skills plus efficaces.','u':'1v1 aile ou surface.','e':'Ne skill pas dans zone de tacle multiple.'},
      {'t':'Press Proven','g':'Résiste pressing','i':'Meilleure protection/conservation sous pression.','u':'Utilise pour sortir pressing et pivot.','e':'Ne force pas si entouré par 2 défenseurs.'},
      {'t':'Relentless','g':'Endurance pressing','i':'Maintient intensité plus longtemps.','u':'Parfait pressing et latéraux.','e':'Même avec Relentless, évite sprint permanent inutile.'},
      {'t':'Jockey','g':'Contenir','i':'Meilleur déplacement défensif latéral.','u':'Contiens ailier sans te jeter.','e':'Ne spam tacle si Jockey suffit.'},
      {'t':'Block','g':'Blocage tir','i':'Améliore blocs de tirs/centres.','u':'Place défenseur sur ligne de tir.','e':'Évite sortir trop tôt de l’axe.'},
      {'t':'Intercept','g':'Interception','i':'Meilleure coupe de ligne de passe.','u':'Contrôle CDM dans ligne de passe.','e':'Ne casse pas la ligne si personne couvre.'},
      {'t':'Anticipate','g':'Tacle propre','i':'Meilleur tacle debout et récupération.','u':'Attends mauvais contrôle puis tacle.','e':'Évite tacle de face contre dribbleur très agile.'},
      {'t':'Slide Tackle','g':'Tacle glissé','i':'Glissades plus efficaces.','u':'Coupe centre ou dernier recours.','e':'Danger dans surface.'},
      {'t':'Bruiser','g':'Duel physique','i':'Contacts plus dominants.','u':'Va au contact contre joueur faible Strength/Balance.','e':'Évite contre dribbleur qui change direction vite.'},
      {'t':'Aerial Fortress','g':'Duel aérien','i':'Gros bonus tête/détente/présence aérienne.','u':'Centres, corners, dégagements.','e':'Évite centres contre défenseur avec ce playstyle.'},
      {'t':'Footwork','g':'GK pied/réflexe','i':'Gardien plus fort sur déplacements courts.','u':'Utile face tirs proches.','e':'Attaque avec feinte ou tir croisé.'},
      {'t':'Cross Claimer','g':'GK centres','i':'Gardien capte mieux les centres.','u':'Bon contre spam centre.','e':'Évite centres flottants contre lui.'},
      {'t':'Rush Out','g':'GK sortie','i':'Gardien sort mieux sur profondeur.','u':'Utile défense haute.','e':'Contre lui, lob ou passe latérale.'},
      {'t':'Far Reach','g':'GK détente','i':'Meilleure allonge sur tirs placés.','u':'Bon contre finesse/angles.','e':'Cherche cutback plutôt que frappe loin.'},
      {'t':'Deflector','g':'GK déviation','i':'Meilleure gestion des tirs repoussés.','u':'Réduit danger rebonds.','e':'Suis le tir avec ST pour second ballon.'},
    ];
    Widget tile(Map<String,String> r)=>Card(child:ListTile(
      leading:const Icon(Icons.info_outline_rounded),
      title:Text(r['t']!, style:const TextStyle(fontWeight:FontWeight.w900)),
      subtitle:Text('${r['g']}\n${r['i']}', maxLines:3, overflow:TextOverflow.ellipsis),
      onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppTheme.bg,builder:(_)=>DraggableScrollableSheet(expand:false,initialChildSize:.78,maxChildSize:.95,builder:(_,ctrl)=>ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
        Header(r['t']!, r['g']!),
        ProBox(title:'Impact gameplay', subtitle:'Ce que ça change dans FC24', icon:Icons.bolt_rounded, child:Text(r['i']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
        ProBox(title:'Comment l’utiliser', subtitle:'Plan terrain', icon:Icons.check_circle_rounded, child:Text(r['u']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
        ProBox(title:'À éviter', subtitle:'Erreur fréquente', icon:Icons.warning_rounded, child:Text(r['e']!, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ]))),
    ));
    return DefaultTabController(length:3, child:Column(children:[
      Header('Encyclopédie Stats & PlayStyles', 'Explication, impact, utilisation et erreurs à éviter'),
      const TabBar(isScrollable:true, tabs:[Tab(text:'Stats'),Tab(text:'PlayStyles'),Tab(text:'Guide duels')]),
      Expanded(child:TabBarView(children:[
        ListView(padding:const EdgeInsets.all(14), children:statRows.map(tile).toList()),
        ListView(padding:const EdgeInsets.all(14), children:playRows.map(tile).toList()),
        ListView(padding:const EdgeInsets.all(14), children:[
          ProBox(title:'Offensif vs Défensif', subtitle:'Lire une comparaison correctement', icon:Icons.compare_arrows_rounded, child:const Text('Dribbling/Agility/Balance/Ball Control doivent être lus contre Standing Tackle/Def Awareness/Jockey/Interceptions. Si l’attaquant gagne dribble mais perd physique, évite contact et joue crochet court. Si le défenseur gagne Awareness + Interceptions, évite passes prévisibles et cherche changement de côté.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
          ProBox(title:'Aérien', subtitle:'Centre ou pas ?', icon:Icons.air_rounded, child:const Text('Heading + Jumping + Strength + Aerial Fortress décident les centres. Si le défenseur gagne ces critères, joue cutback au sol plutôt que centre haut.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
          ProBox(title:'Pressing', subtitle:'Sortir proprement', icon:Icons.directions_run_rounded, child:const Text('Pressing se lit avec Stamina, Aggression, Acceleration, Reactions, Def Awareness. Pour sortir : Ball Control, Composure, Short Passing, Press Proven, First Touch.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
          ProBox(title:'Finition vs défense', subtitle:'Tir ou passe ?', icon:Icons.sports_soccer_rounded, child:const Text('Finishing + Composure + Shot Power doivent être lus contre Block, Def Awareness, GK Reflexes/Positioning. Si Block adverse est haut, cherche cutback ou feinte avant frappe.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
        ]),
      ])),
    ]));
  }
}

class DuelVisualsCrudPage extends StatefulWidget { final List<Player> players; const DuelVisualsCrudPage({super.key, required this.players}); @override State<DuelVisualsCrudPage> createState()=>_DuelVisualsCrudPageState(); }
class _DuelVisualsCrudPageState extends State<DuelVisualsCrudPage>{
  final templates=<Map<String,String>>[
    {'name':'Ailier vs latéral crochet intérieur','mode':'dribble_wing','note':'LW/RW reçoit large, fixe, crochet intérieur ou cutback.'},
    {'name':'ST vs CB profondeur','mode':'speed_long','note':'Appel entre CB et latéral, timing passe en profondeur.'},
    {'name':'CAM vs CDM entre lignes','mode':'pass_break','note':'Réception dos au jeu, contrôle orienté, passe cassante.'},
  ];
  final name=TextEditingController(), note=TextEditingController(); String mode='dribble_wing';
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14), children:[
    Header('Duel Visuals CRUD', 'Créer/modifier des scénarios de duel et templates'),
    ProBox(title:'Nouveau template', subtitle:'Sauvegarde locale écran', icon:Icons.add_rounded, child:Column(children:[TextField(controller:name, decoration:const InputDecoration(labelText:'Nom scénario')), const SizedBox(height:8), DropdownButtonFormField<String>(value:mode, items:modes.map((m)=>DropdownMenuItem(value:m.key, child:Text(m.label))).toList(), onChanged:(v)=>setState(()=>mode=v!), decoration:const InputDecoration(labelText:'Mode duel')), const SizedBox(height:8), TextField(controller:note, decoration:const InputDecoration(labelText:'Notes / animation')), const SizedBox(height:10), FilledButton.icon(onPressed:(){setState(()=>templates.insert(0, {'name':name.text.trim().isEmpty?'Nouveau duel':name.text.trim(),'mode':mode,'note':note.text.trim()})); name.clear(); note.clear();}, icon:const Icon(Icons.save), label:const Text('Ajouter'))])),
    ...templates.map((t)=>ProBox(title:t['name']!, subtitle:t['mode']!, icon:Icons.polyline_rounded, child:Row(children:[Expanded(child:Text(t['note']!, style:const TextStyle(height:1.35, fontWeight:FontWeight.w700))), IconButton(onPressed:()=>setState(()=>templates.remove(t)), icon:const Icon(Icons.delete_outline_rounded))]))),
  ]);
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
  final Map<String, Player> assigned = {};
  String selectedTeam = 'France';
  bool showWomen=false, showSoccerAid=false, showJson=false;

  @override void initState(){ super.initState(); spots=Map<String,Offset>.from(preset.spots); _autoFill(); }

  List<Player> get pool => cleanPlayerList(widget.players, showWomen:showWomen, showSoccerAid:showSoccerAid)
    .where((p)=>selectedTeam=='all'||p.team==selectedTeam).toList()..sort((a,b)=>b.ovr.compareTo(a.ovr));
  List<String> get teams => ['all', ...(cleanPlayerList(widget.players, showWomen:showWomen, showSoccerAid:showSoccerAid).map((p)=>p.team).where((t)=>t!='—').toSet().toList()..sort())];

  void _autoFill(){
    assigned.clear();
    final list=pool;
    for(final pos in spots.keys){
      final exact=list.where((p)=>_fits(pos,p)).toList();
      final pick=(exact.isNotEmpty?exact:list).where((p)=>!assigned.values.any((x)=>x.id==p.id)).cast<Player?>().firstWhere((p)=>p!=null, orElse:()=>null);
      if(pick!=null) assigned[pos]=pick;
    }
  }
  bool _fits(String role, Player p){
    final r=role.replaceAll(RegExp(r'\d'), '').toUpperCase();
    final txt='${p.pos} ${p.pos2}'.toUpperCase();
    if(r=='GK') return txt.contains('GK');
    if(r.contains('CB')) return txt.contains('CB');
    if(r.contains('LB')||r.contains('LWB')) return txt.contains('LB')||txt.contains('LWB');
    if(r.contains('RB')||r.contains('RWB')) return txt.contains('RB')||txt.contains('RWB');
    if(r.contains('CDM')) return txt.contains('CDM');
    if(r.contains('CM')) return txt.contains('CM')||txt.contains('CDM');
    if(r.contains('CAM')) return txt.contains('CAM')||txt.contains('CM');
    if(r.contains('LW')||r=='LF'||r=='LM') return txt.contains('LW')||txt.contains('LM')||txt.contains('LF');
    if(r.contains('RW')||r=='RF'||r=='RM') return txt.contains('RW')||txt.contains('RM')||txt.contains('RF');
    if(r.contains('ST')||r.contains('CF')) return txt.contains('ST')||txt.contains('CF');
    return true;
  }
  String _json(){
    return jsonEncode({
      'formation':preset.name,
      'team':selectedTeam,
      'spots':spots.map((k,v)=>MapEntry(k, {'x':double.parse(v.dx.toStringAsFixed(3)), 'y':double.parse(v.dy.toStringAsFixed(3)), 'playerid': assigned[k]?.id, 'name':assigned[k]?.name})),
    });
  }
  @override Widget build(BuildContext context){
    final bench=pool.where((p)=>!assigned.values.any((x)=>x.id==p.id)).take(18).toList();
    return ListView(padding:const EdgeInsets.all(16), children:[
      Header('Formation Builder Pro', 'Crée un XI, remplace les joueurs, déplace les postes et exporte la tactique'),
      ProBox(title:'Contrôles formation', subtitle:'Plus de systèmes + auto-fill + banc cliquable', icon:Icons.tune_rounded, child:Column(children:[
        LayoutBuilder(builder:(context,c){
          final f1=DropdownButtonFormField<String>(value:preset.name, isExpanded:true, decoration:const InputDecoration(labelText:'Formation'), items:formationPresets.map((f)=>DropdownMenuItem(value:f.name, child:Text(f.name))).toList(), onChanged:(v)=>setState((){preset=formationPresets.firstWhere((f)=>f.name==v); spots=Map<String,Offset>.from(preset.spots); _autoFill();}));
          final f2=DropdownButtonFormField<String>(value:teams.contains(selectedTeam)?selectedTeam:'all', isExpanded:true, decoration:const InputDecoration(labelText:'Équipe'), items:teams.take(450).map((t)=>DropdownMenuItem(value:t, child:Text(t, overflow:TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState((){selectedTeam=v!; _autoFill();}));
          return c.maxWidth<560?Column(children:[f1,const SizedBox(height:10),f2]):Row(children:[Expanded(child:f1),const SizedBox(width:10),Expanded(child:f2)]);
        }),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children:[
          ActionChip(label:const Text('Auto meilleur XI'), avatar:const Icon(Icons.auto_awesome), onPressed:()=>setState(_autoFill)),
          ActionChip(label:const Text('Reset positions'), avatar:const Icon(Icons.restart_alt), onPressed:()=>setState(()=>spots=Map<String,Offset>.from(preset.spots))),
          FilterChip(label:const Text('Afficher Female'), selected:showWomen, onSelected:(v)=>setState(()=>showWomen=v)),
          FilterChip(label:const Text('Afficher Soccer Aid'), selected:showSoccerAid, onSelected:(v)=>setState(()=>showSoccerAid=v)),
          FilterChip(label:const Text('Voir JSON'), selected:showJson, onSelected:(v)=>setState(()=>showJson=v)),
        ])
      ])),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(12), child:AspectRatio(aspectRatio:1.35, child:LayoutBuilder(builder:(context,c){
        return Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(28), gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF075E2F), Color(0xFF0A7A48)]), boxShadow:[BoxShadow(color:AppTheme.pitch.withOpacity(.22), blurRadius:28, offset:Offset(0,14))]), child:Stack(children:[
          Positioned.fill(child:CustomPaint(painter:PitchLinesPainter())),
          ...spots.entries.map((e){ final p=assigned[e.key]; return Positioned(left:e.value.dx*c.maxWidth-34, top:e.value.dy*c.maxHeight-38, child:GestureDetector(
            onPanUpdate:(d)=>setState(()=>spots[e.key]=Offset((spots[e.key]!.dx+d.delta.dx/c.maxWidth).clamp(.04,.96), (spots[e.key]!.dy+d.delta.dy/c.maxHeight).clamp(.06,.94))),
            onTap:() async { final pick=await showPlayerSearch(context, pool, p ?? (pool.isNotEmpty?pool.first:widget.players.first)); if(pick!=null) setState(()=>assigned[e.key]=pick); },
            child:DragTarget<Player>(onAccept:(pl)=>setState(()=>assigned[e.key]=pl), builder:(_,cand,rej)=>_formationPlayer(e.key,p, cand.isNotEmpty)),
          ));}),
        ]));
      })))),
      const SizedBox(height:12),
      ProBox(title:'Banc / remplaçants', subtitle:'Glisse un joueur sur un poste ou clique une pastille sur terrain', icon:Icons.swap_horiz_rounded, child:SizedBox(height:118, child:ListView(scrollDirection:Axis.horizontal, children:bench.map((p)=>Draggable<Player>(data:p, feedback:Material(color:Colors.transparent, child:_benchChip(p, true)), child:_benchChip(p,false))).toList()))),
      ProBox(title:'Analyse formation', subtitle:'Forces, faiblesses, utilisation et contre', icon:Icons.psychology_alt_rounded, child:Text(_formationReport(), style:const TextStyle(height:1.45, fontWeight:FontWeight.w700))),
      if(showJson) ProBox(title:'Export formation JSON', subtitle:'Structure complète postes + joueurs', icon:Icons.code_rounded, child:SelectableText(_json())),
    ]);
  }
  Widget _formationPlayer(String role, Player? p, bool active)=>Column(children:[
    Container(width:active?74:66, height:active?74:66, padding:const EdgeInsets.all(3), decoration:BoxDecoration(shape:BoxShape.circle, gradient:const LinearGradient(colors:[Color(0xFF24C6DC), Color(0xFF18C58F)]), border:Border.all(color:Colors.white, width:2), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.25), blurRadius:12)]), child:p==null?Center(child:Text(role, style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:12))):PlayerAvatar(p:p,size:60)),
    const SizedBox(height:3),
    Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration:BoxDecoration(color:Colors.black.withOpacity(.48), borderRadius:BorderRadius.circular(999)), child:Text(p==null?role:p.name.split(' ').last, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900))),
  ]);
  Widget _benchChip(Player p,bool big)=>Container(width:big?126:112, margin:const EdgeInsets.only(right:10), padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:AppTheme.surface, borderRadius:BorderRadius.circular(22), border:Border.all(color:AppTheme.line), boxShadow:big?[BoxShadow(color:Colors.black.withOpacity(.18), blurRadius:18)]:[]), child:Column(children:[PlayerAvatar(p:p,size:46), const SizedBox(height:4), Text(p.name, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w900,fontSize:12)), Text('${p.pos} • ${p.ovr}', style:const TextStyle(color:AppTheme.muted,fontSize:11))]));
  String _formationReport(){
    final ps=assigned.values.toList(); if(ps.isEmpty) return 'Aucun joueur assigné.';
    int avg(String k)=>ps.map((p)=>p.s[k]??0).fold(0,(a,b)=>a+b)~/max(1,ps.length);
    final pace=avg('pac'), pass=avg('pas'), def=avg('def'), phy=avg('phy');
    return 'Forces : ${pace>=80?'profondeur/vitesse, ':''}${pass>=80?'sortie de balle, ':''}${def>=78?'bloc solide, ':''}${phy>=78?'duels physiques, ':''}formation ${preset.name}.\nFaiblesses : ${pace<72?'manque de vitesse, ':''}${def<70?'exposition transition, ':''}${pass<72?'risque sous pressing, ':''}surveiller espaces entre lignes.\nComment profiter : isole tes profils les plus rapides, utilise cutback si les ailiers dominent, et renverse côté faible.\nComment contrer : ferme l’axe, presse le relanceur faible et attaque dans le dos des latéraux.';
  }
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



class SettingsPage extends StatefulWidget {
  final List<Player> players; final List<TeamInfo> teams; final List<TacticalIdea> ideas; final List<Map<String,dynamic>> history;
  const SettingsPage({super.key, required this.players, required this.teams, required this.ideas, required this.history});
  @override State<SettingsPage> createState()=>_SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage>{
  String export='';
  String buildExport()=>jsonEncode({
    'version':'fc24_coach_ai_v38_backup',
    'date':DateTime.now().toIso8601String(),
    'players':widget.players.map((p)=>p.toLocalJson()).toList(),
    'teams':widget.teams.map((t)=>t.toLocalJson()).toList(),
    'ideas':widget.ideas.map((i)=>i.toJson()).toList(),
    'history':widget.history,
  });
  @override Widget build(BuildContext context)=>DefaultTabController(length:4, child:Column(children:[
    const Header('Paramètres', 'Backup DB, affichage, mise à jour et maintenance'),
    const TabBar(isScrollable:true, tabs:[Tab(text:'Général'),Tab(text:'Export DB'),Tab(text:'Mise à jour'),Tab(text:'Infos')]),
    Expanded(child:TabBarView(children:[
      ListView(padding:const EdgeInsets.all(14), children:[
        ProBox(title:'Préférences affichage', subtitle:'Réduire les longues pages avec onglets', icon:Icons.tune_rounded, child:const Text('Les nouvelles sections lourdes utilisent des onglets : Managers, Formation Counter, Situations, Paramètres. Les détails s’ouvrent en modal pour éviter trop de scroll.')),
        ProBox(title:'Données locales', subtitle:'Changements conservés localement', icon:Icons.storage_rounded, child:Text('${widget.players.length} joueurs • ${widget.teams.length} équipes • ${widget.ideas.length} idées tactiques')),
      ]),
      ListView(padding:const EdgeInsets.all(14), children:[
        ProBox(title:'Exporter DB actuelle', subtitle:'À faire avant update/désinstallation', icon:Icons.download_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          const Text('Important : si tu dois désinstaller puis installer une nouvelle version, génère et copie cet export avant. Ensuite tu le réimportes dans Export / Import.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700)),
          const SizedBox(height:10),
          FilledButton.icon(onPressed:(){setState(()=>export=buildExport()); Clipboard.setData(ClipboardData(text:export)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Export DB copié')));}, icon:const Icon(Icons.copy_rounded), label:const Text('Générer + copier export DB')),
          const SizedBox(height:10),
          if(export.isNotEmpty) TextField(controller:TextEditingController(text:export), minLines:8, maxLines:16, readOnly:true, decoration:const InputDecoration(labelText:'Backup JSON')),
        ])),
      ]),
      ListView(padding:const EdgeInsets.all(14), children:[
        ProBox(title:'Workflow update sécurisé', subtitle:'Ne pas perdre transferts / XI / tactiques', icon:Icons.system_update_alt_rounded, child:const Text('1) Paramètres > Export DB > copier.\n2) Installer nouvelle version.\n3) Aller dans Export / Import.\n4) Coller le JSON et importer.\n5) Vérifier transferts, XI départ et formations provisoires.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ]),
      ListView(padding:const EdgeInsets.all(14), children:[
        ProBox(title:'Version', subtitle:'v38 UX + DB backup + coach detail', icon:Icons.info_rounded, child:const Text('Ajouts : bouton edit joueur, paramètres, backup DB, managers détaillés, formation counter enrichi depuis PJ, situations cliquables, onglets pour réduire le scroll.')),
      ]),
    ])),
  ]));
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


/* === v9 Pro modules: deeper analysis helpers === */
class ProDuelBreakdown extends StatelessWidget {
  final Player a;
  final Player b;
  final Mode mode;
  const ProDuelBreakdown({super.key, required this.a, required this.b, required this.mode});

  @override
  Widget build(BuildContext context) {
    final sa = score(a, mode);
    final sb = score(b, mode);
    final win = sa.total >= sb.total ? a : b;
    final lose = sa.total >= sb.total ? b : a;
    final gap = (sa.total - sb.total).abs();
    final reasons = _reasons(a, b, sa, sb);
    return ProBox(
      title: 'Duel Engine Pro',
      subtitle: '${mode.label} • gagnant prévu : ${win.name}',
      icon: Icons.psychology_alt_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: MiniScore(a.name, sa.total, 'Total')),
          const SizedBox(width: 8),
          Expanded(child: MiniScore(b.name, sb.total, 'Total')),
        ]),
        const SizedBox(height: 12),
        Text('Lecture coach', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        Text(gap <= 3
            ? 'Duel très serré. Le résultat peut changer selon angle, fatigue, première touche et soutien proche.'
            : '${win.name} a un avantage clair contre ${lose.name} dans cette situation.'),
        const SizedBox(height: 10),
        ...reasons.map((r) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.check_circle, color: Color(0xFF86EFAC)),
          title: Text(r),
          trailing: const Icon(Icons.open_in_new_rounded, size:18),
          onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppTheme.bg,builder:(_)=>DraggableScrollableSheet(expand:false,initialChildSize:.62,maxChildSize:.9,builder:(_,ctrl)=>ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[Header('Détail comparaison', mode.label), ProBox(title:'Pourquoi cette différence ?', subtitle:'Lecture IA du duel', icon:Icons.psychology_rounded, child:Text(r, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))), DetailCard(a:a,b:b,sa:sa,sb:sb,mode:mode)]))),
        )),
        const Divider(),
        Text('Plan avec ${win.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(_withAdvice(mode)),
        const SizedBox(height: 8),
        Text('Plan contre ${win.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(_againstAdvice(mode)),
      ]),
    );
  }

  List<String> _reasons(Player a, Player b, DuelScore sa, DuelScore sb) {
    final rows = <String>[];
    for (int i = 0; i < sa.factors.length && i < sb.factors.length; i++) {
      final fa = sa.factors[i], fb = sb.factors[i];
      final d = fa.points - fb.points;
      if (d.abs() >= 4) rows.add('${labelStat(fa.key)} : ${d > 0 ? a.name : b.name} +${d.abs()}');
    }
    final psA = mergedPlayStyles(a).where((x)=>x.contains('+')).take(3).join(', ');
    final psB = mergedPlayStyles(b).where((x)=>x.contains('+')).take(3).join(', ');
    if (psA.isNotEmpty) rows.add('PlayStyles+ ${a.name}: $psA');
    if (psB.isNotEmpty) rows.add('PlayStyles+ ${b.name}: $psB');
    if (rows.isEmpty) rows.add('Écart faible : aucune stat ne domine fortement.');
    return rows.take(7).toList();
  }

  String _withAdvice(Mode m) {
    if (m.key.contains('speed')) return 'Cherche l’espace dans le dos, joue tôt, évite les contacts inutiles.';
    if (m.key.contains('dribble')) return 'Isole le défenseur, attaque son mauvais appui et utilise changements de rythme.';
    if (m.key.contains('aerial')) return 'Centre tôt, attaque deuxième poteau et utilise son avantage taille/jumping.';
    if (m.key.contains('press')) return 'Déclenche pressing après contrôle orienté adverse ou passe latérale.';
    if (m.key.contains('pass')) return 'Cherche troisième homme, passe verticale et changement de côté.';
    return 'Provoque ce duel quand le joueur est isolé et avec soutien proche.';
  }

  String _againstAdvice(Mode m) {
    if (m.key.contains('speed')) return 'Recule avant le sprint, défends l’espace plutôt que le joueur.';
    if (m.key.contains('dribble')) return 'Contiens avec jockey, force côté faible et attends l’aide.';
    if (m.key.contains('aerial')) return 'Empêche le centre avant qu’il parte, ou place un défenseur devant + couverture.';
    if (m.key.contains('press')) return 'Joue en une touche, utilise le gardien ou le troisième homme.';
    if (m.key.contains('pass')) return 'Ferme la ligne verticale et force la passe latérale.';
    return 'Évite le duel direct, crée surnombre et ralentis le tempo.';
  }
}

class ProTeamWeaknessReport extends StatelessWidget {
  final TeamInfo team;
  final List<Player> players;
  const ProTeamWeaknessReport({super.key, required this.team, required this.players});

  @override
  Widget build(BuildContext context) {
    final squad = players.where((p)=>p.team == team.name).toList()..sort((a,b)=>b.ovr.compareTo(a.ovr));
    final slowDef = squad.where((p)=>(p.pos.contains('CB') || p.pos.contains('LB') || p.pos.contains('RB')) && ((p.s['sprint']??0) < 75)).take(5).toList();
    final weakPhys = squad.where((p)=>((p.s['str']??0) < 70) && !p.pos.contains('GK')).take(5).toList();
    final lowStam = squad.where((p)=>((p.s['stam']??0) < 75) && !p.pos.contains('GK')).take(5).toList();
    return ProBox(
      title: 'Rapport failles équipe',
      subtitle: team.name,
      icon: Icons.analytics_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _block('Défense lente à attaquer', slowDef, 'Utilise appels profondeur, passes dans le dos et ailiers rapides.'),
        _block('Joueurs faibles physiquement', weakPhys, 'Cherche épaule contre épaule, pressing agressif et duels au sol.'),
        _block('Endurance basse', lowStam, 'Accélère après 60e minute, pressing et changements de rythme.'),
        const Divider(),
        Text('Plan coach rapide', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        Text(_plan()),
      ]),
    );
  }

  Widget _block(String title, List<Player> list, String advice) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    if (list.isEmpty) const Text('Aucune faiblesse claire détectée.'),
    ...list.map((p)=>ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: PlayerAvatar(p: p, size: 34),
      title: Text(p.name),
      subtitle: Text('${p.pos} • PAC ${p.s['pac']??0} • STR ${p.s['str']??0} • STA ${p.s['stam']??0}'),
    )),
    Text(advice, style: const TextStyle(color: Color(0xFFB7C9E8))),
    const SizedBox(height: 10),
  ]);

  String _plan() {
    if (team.defense < 78) return 'Attaque vite dans l’axe et provoque les 1v1 autour de la surface.';
    if (team.midfield < 78) return 'Surcharge le milieu, joue triangles courts et récupère les deuxièmes ballons.';
    if (team.attack < 78) return 'Laisse moins d’espace derrière, force l’adversaire à construire lentement.';
    return 'Équipe équilibrée : cherche surtout les mismatchs individuels et les côtés faibles.';
  }
}

class ProContentHub extends StatelessWidget {
  final ValueChanged<int>? onGo;
  const ProContentHub({super.key, this.onGo});

  @override
  Widget build(BuildContext context) => ProBox(
    title: 'Coach Control Center',
    subtitle: 'UX V22 : 6 chemins rapides au lieu d’un long menu compliqué',
    icon: Icons.dashboard_customize_rounded,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hubTile(context, 'Comparer 2 joueurs', 'Tous les modes + poste vs poste + détail par clic', Icons.compare_arrows_rounded, 1),
      _hubTile(context, 'Trouver le meilleur profil', 'Classement par situation : vitesse, pressing, cutback, bloc bas…', Icons.manage_search_rounded, 2),
      _hubTile(context, 'Analyser une équipe', 'Forces/faiblesses, joueurs clés, comment profiter / contrer', Icons.analytics_rounded, 9),
      _hubTile(context, 'Team vs Team', 'Plan de match, weak links, zones fortes/faibles, prediction IA', Icons.ssid_chart_rounded, 10),
      _hubTile(context, 'Tactical Lab', 'Situation → animation → duel → lecture coach', Icons.sports_soccer_rounded, 18),
      _hubTile(context, 'Tactic Board Studio', 'Drag/drop, timeline, keyframes, groupes, export JSON', Icons.animation_rounded, 26),
    ]),
  );

  Widget _hubTile(BuildContext context, String title, String subtitle, IconData icon, int tab) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1B31),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF243B55)),
    ),
    child: ListTile(
      onTap: onGo == null ? null : () => onGo!(tab),
      leading: Container(width:42,height:42, decoration:BoxDecoration(shape:BoxShape.circle, gradient:const LinearGradient(colors:[Color(0xFF14B881), Color(0xFF2F80FF)])), child:Icon(icon, color:Colors.white)),
      title: Text(title, style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(color:Color(0xFFB7C9E8), height:1.25, fontWeight:FontWeight.w700)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size:16, color:Color(0xFF34D399)),
    ),
  );
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



class TacticalPage extends StatefulWidget {
  final Player a,b; final Mode mode; final List<Player> players;
  const TacticalPage({super.key, required this.a, required this.b, required this.mode, required this.players});
  @override State<TacticalPage> createState()=>_TacticalPageState();
}
class _TacticalPageState extends State<TacticalPage> {
  late Player a,b; late Mode mode;
  @override void initState(){ super.initState(); a=widget.a; b=widget.b; mode=widget.mode; }
  @override Widget build(BuildContext context) {
    final sa=score(a,mode), sb=score(b,mode), win=sa.total>=sb.total?a:b, lose=sa.total>=sb.total?b:a;
    return DefaultTabController(length:7, child:Column(children:[
      Header('Tactical Lab Pro', '${mode.label} • gagnant probable : ${win.name}'),
      const TabBar(isScrollable:true, tabs:[Tab(text:'Setup'),Tab(text:'Terrain'),Tab(text:'Stats'),Tab(text:'Plan'),Tab(text:'Détails'),Tab(text:'Scénarios'),Tab(text:'À éviter')]),
      Expanded(child:TabBarView(children:[
        ListView(padding:const EdgeInsets.all(16), children:[
          PlayerPicker(title:'Joueur A concerné', players: widget.players, value:a, onChanged:(p)=>setState(()=>a=p)),
          PlayerPicker(title:'Joueur B concerné', players: widget.players, value:b, onChanged:(p)=>setState(()=>b=p)),
          ModePicker(mode:mode, onChanged:(m)=>setState(()=>mode=m)),
        ]),
        ListView(padding:const EdgeInsets.all(16), children:[ProBox(title:'Terrain interactif de duel', subtitle:'Ligne de course, zone utile, angle et timing', icon:Icons.sports_soccer_rounded, child:Column(children:[AspectRatio(aspectRatio:1.36, child:CustomPaint(painter:PitchPainter(a.name,b.name,sa.total>=sb.total,mode.key))), const SizedBox(height:12), ScoreSummary(a:a,b:b,sa:sa,sb:sb)]))]),
        ListView(padding:const EdgeInsets.all(16), children:[ProDuelBreakdown(a:a,b:b,mode:mode)]),
        ListView(padding:const EdgeInsets.all(16), children:[ProBox(title:'Plan coach complet', subtitle:'Forces, faiblesses, profiter et contrer', icon:Icons.menu_book_rounded, child:Text('Forces ${win.name} : ${coachStrengths(win)}.\nFaiblesses ${lose.name} : ${coachWeaknesses(lose)}.\n\nComment profiter : crée ce duel en isolant ${win.name}, oriente son corps vers son pied fort et joue avant que le soutien adverse arrive.\nComment contrer : évite le duel direct, couvre la ligne de course, force ${win.name} vers la zone faible et déclenche le second défenseur seulement après contrôle.', style:const TextStyle(height:1.45, fontWeight:FontWeight.w700)))]),
        ListView(padding:const EdgeInsets.all(16), children:[
          ProBox(title:'Stats clés du mode', subtitle:'Clique une comparaison pour voir pourquoi', icon:Icons.tune_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Text('Mode actif : ${mode.label}', style:const TextStyle(fontWeight:FontWeight.w900)), const SizedBox(height:8),
            Wrap(spacing:8, runSpacing:8, children:mode.w.keys.map((k)=>ActionChip(label:Text('${labelStat(k)} ${(mode.w[k]! * 100).round()}%'), onPressed:()=>_showStatCompare(context,k))).toList()),
          ])),
        ]),
        ListView(padding:const EdgeInsets.all(16), children:[
          ProBox(title:'Scénarios coach', subtitle:'Choisis l’idée selon la phase de jeu', icon:Icons.account_tree_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            _labScenario(context,'1v1 couloir','Isole ${a.name} côté fort, attaque le pied faible de ${b.name}, puis cherche cutback ou passe retrait.'),
            _labScenario(context,'Transition rapide','Premier contrôle vers l’avant, passe avant contact, exploite la vitesse du gagnant probable.'),
            _labScenario(context,'Bloc bas','Patience : attire le défenseur, joue appui-remise, ne force pas le dribble si le tacle gagne.'),
            _labScenario(context,'Pressing','Déclenche sur mauvais contrôle, couvre la ligne de passe, évite pressing seul sans soutien.'),
          ])),
          const SizedBox(height:12),
          ProBox(title:'Joueurs concernés', subtitle:'Sélection rapide selon rôle', icon:Icons.groups_rounded, child:Wrap(spacing:8,runSpacing:8, children:[
            ActionChip(label:Text(a.name), onPressed:()=>showPlayerDetails(context,a)),
            ActionChip(label:Text(b.name), onPressed:()=>showPlayerDetails(context,b)),
            ActionChip(label:Text('Changer mode'), onPressed:()=>_openModeHelp(context)),
          ])),
        ]),
        ListView(padding:const EdgeInsets.all(16), children:[
          ProBox(title:'À éviter', subtitle:'Risques du duel et erreurs FC24', icon:Icons.warning_amber_rounded, child:Text(_labAvoidText(), style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
          const SizedBox(height:12),
          ProBox(title:'Alternative sûre', subtitle:'Si le duel est défavorable', icon:Icons.route_rounded, child:Text('Ne force pas le duel direct. Joue soutien proche, renversement, une-deux ou protection balle. Si ${b.name} gagne physique/tacle, attaque plutôt son dos ou son côté faible.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
        ]),
      ])),
    ]));
  }

  Widget _labScenario(BuildContext context, String title, String body)=>ListTile(
    contentPadding:EdgeInsets.zero,
    leading:const Icon(Icons.play_arrow_rounded,color:AppTheme.green),
    title:Text(title, style:const TextStyle(fontWeight:FontWeight.w900)),
    subtitle:Text(body, style:const TextStyle(color:AppTheme.muted,fontWeight:FontWeight.w700,height:1.25)),
    onTap:()=>showUxDetailModal(context, title, [ProBox(title:'Détail scénario', subtitle:mode.label, icon:Icons.sports_soccer_rounded, child:Text(body, style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))), ProDuelBreakdown(a:a,b:b,mode:mode)]),
  );
  void _openModeHelp(BuildContext context)=>showUxDetailModal(context, 'Mode ${mode.label}', [ProBox(title:'Stats du mode', subtitle:'Poids de calcul', icon:Icons.tune_rounded, child:Wrap(spacing:8,runSpacing:8,children:mode.w.keys.map((k)=>Chip(label:Text('${labelStat(k)} ${(mode.w[k]!*100).round()}%'))).toList())), ProBox(title:'Impact', subtitle:'Lecture coach', icon:Icons.psychology_rounded, child:Text('Ce mode compare les qualités réellement utiles dans la situation. Clique chaque stat pour comprendre son impact et éviter les mauvais duels.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))]);
  String _labAvoidText(){
    final bad=score(a,mode).total < score(b,mode).total;
    if(bad) return '${a.name} est défavorisé dans ${mode.label}. Évite le duel direct, ne dribble pas dans la zone de contact, cherche soutien ou changement d’angle.';
    return '${a.name} est favori, mais évite de répéter le même geste. Varie timing, angle, feinte et passe pour ne pas offrir un tacle facile.';
  }

  void _showStatCompare(BuildContext context, String k){
    final av=a.s[k]??0, bv=b.s[k]??0, diff=av-bv;
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppTheme.bg,builder:(_)=>DraggableScrollableSheet(expand:false,initialChildSize:.70,maxChildSize:.92,builder:(_,ctrl)=>ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
      Header('${labelStat(k)} : ${a.name} vs ${b.name}', mode.label),
      Row(children:[Expanded(child:MiniScore(a.name,av,labelStat(k))),const SizedBox(width:8),Expanded(child:MiniScore(b.name,bv,labelStat(k)))]),
      const SizedBox(height:12),
      ProBox(title:'Lecture IA', subtitle:'Pourquoi cette stat compte', icon:Icons.psychology_rounded, child:Text(diff==0?'Égalité parfaite : la décision dépend du timing, angle et soutien proche.': diff>0?'${a.name} gagne +$diff sur ${labelStat(k)}. Dans ce mode, cette stat pèse ${(mode.w[k]!*100).round()}%, donc elle influence fortement le résultat.':'${b.name} gagne +${diff.abs()} sur ${labelStat(k)}. Évite de jouer ce duel directement si cette stat est centrale.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
      ProBox(title:'Conseil terrain', subtitle:'Comment utiliser cette info', icon:Icons.sports_soccer_rounded, child:Text(diff>=0?'Crée le duel vite, avant que l’adversaire ait une couverture. Combine avec les autres stats fortes du mode.':'Change le type de duel : évite cette zone faible, joue soutien, feinte ou passe rapide.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
    ])));
  }
}

class PitchPainter extends CustomPainter {
  final String a,b,mode; final bool aWin;
  PitchPainter(this.a,this.b,this.aWin,this.mode);
  @override void paint(Canvas c, Size s) {
    final bg=Paint()..shader=const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF08743E),Color(0xFF0B162A)]).createShader(Offset.zero&s);
    final line=Paint()..color=Colors.white.withOpacity(.58)..style=PaintingStyle.stroke..strokeWidth=2;
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero&s, const Radius.circular(28)), bg);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18,18,s.width-36,s.height-36), const Radius.circular(18)), line);
    c.drawLine(Offset(s.width/2,18),Offset(s.width/2,s.height-18),line); c.drawCircle(Offset(s.width/2,s.height/2),48,line);
    Offset pa=Offset(s.width*.35,s.height*.55), pb=Offset(s.width*.62,s.height*.48), ball=Offset(s.width*.78,s.height*.38), zone=Offset(s.width*.67,s.height*.40);
    if(mode.contains('press')||mode.contains('shield')) {pa=Offset(s.width*.42,s.height*.53); pb=Offset(s.width*.58,s.height*.52); ball=Offset(s.width*.50,s.height*.53); zone=Offset(s.width*.50,s.height*.53);} 
    if(mode.contains('aerial')) {pa=Offset(s.width*.62,s.height*.38); pb=Offset(s.width*.70,s.height*.52); ball=Offset(s.width*.76,s.height*.45); zone=Offset(s.width*.72,s.height*.47);} 
    if(mode.contains('cross')||mode.contains('cutback')) {pa=Offset(s.width*.72,s.height*.22); pb=Offset(s.width*.64,s.height*.36); ball=Offset(s.width*.58,s.height*.55); zone=Offset(s.width*.58,s.height*.55);} 
    c.drawCircle(zone,44,Paint()..color=const Color(0xFF18C58F).withOpacity(.18));
    _arrow(c, pa, ball, const Color(0xFFFFD166), 4); _arrow(c, pb, ball, Colors.white.withOpacity(.75), 3);
    drawP(c,pa,a.substring(0,min(2,a.length)).toUpperCase(),aWin,const Color(0xFF24C6DC));
    drawP(c,pb,b.substring(0,min(2,b.length)).toUpperCase(),!aWin,const Color(0xFFFF5573));
    c.drawCircle(ball,9,Paint()..color=Colors.white);
  }
  void _arrow(Canvas c, Offset a, Offset b, Color col, double w){ final p=Paint()..color=col..strokeWidth=w..strokeCap=StrokeCap.round; c.drawLine(a,b,p); final ang=atan2(b.dy-a.dy,b.dx-a.dx); c.drawLine(b,b-Offset(cos(ang-.55)*13,sin(ang-.55)*13),p); c.drawLine(b,b-Offset(cos(ang+.55)*13,sin(ang+.55)*13),p); }
  void drawP(Canvas c, Offset o, String t, bool win, Color col){c.drawCircle(o,win?29:24,Paint()..color=col); if(win)c.drawCircle(o,42,Paint()..color=const Color(0xFF18C58F).withOpacity(.22)); final tp=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout(); tp.paint(c,o-Offset(tp.width/2,tp.height/2));}
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>true;
}


// === v41 UX ENTERPRISE: command center, global search, quick actions, workspaces ===
class GlobalCommandCenterPage extends StatefulWidget {
  final List<Player> players;
  final List<TeamInfo> teams;
  final ValueChanged<int> onGo;
  final ValueChanged<Player> onOpenPlayer;
  const GlobalCommandCenterPage({super.key, required this.players, required this.teams, required this.onGo, required this.onOpenPlayer});
  @override State<GlobalCommandCenterPage> createState()=>_GlobalCommandCenterPageState();
}

class _GlobalCommandCenterPageState extends State<GlobalCommandCenterPage> {
  String q='';
  final favs=<String>{'Haaland','Mbappé','4-3-3','Team vs Team','Tactical Lab'};
  @override Widget build(BuildContext context){
    final query=q.trim().toLowerCase();
    final ps=widget.players.where((p)=>query.isEmpty?false:('${p.name} ${p.team} ${p.pos} ${p.playstyles.join(' ')}').toLowerCase().contains(query)).take(12).toList();
    final ts=widget.teams.where((t)=>query.isEmpty?false:('${t.name} ${t.manager} ${t.strongTraits.join(' ')} ${t.weakTraits.join(' ')}').toLowerCase().contains(query)).take(8).toList();
    return ListView(padding:const EdgeInsets.all(16), children:[
      Header('Command Center', 'Recherche globale • favoris • actions rapides • workspaces'),
      ProBox(title:'Recherche globale', subtitle:'Joueur, équipe, manager, formation, playstyle, stat, situation...', icon:Icons.manage_search_rounded, child:Column(children:[
        TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded), hintText:'Ex: Rodri, PSG, 4-3-3, Rapid, cutback...'), onChanged:(v)=>setState(()=>q=v)),
        const SizedBox(height:10),
        Wrap(spacing:8,runSpacing:8,children:['Haaland','Walker','PSG','4-2-3-1','Pressing','Cutback','Rapid','Intercept'].map((x)=>ActionChip(label:Text(x), onPressed:()=>setState(()=>q=x))).toList()),
      ])),
      if(query.isNotEmpty) ...[
        const SizedBox(height:12),
        UxTabSection(tabs:const ['Joueurs','Équipes','Modules'], height:420, children:[
          Column(children:ps.isEmpty?[const ProBox(title:'Aucun joueur', subtitle:'Essaye un autre mot-clé', icon:Icons.search_off_rounded, child:Text(''))]:ps.map((p)=>PlayerTile(p:p,onTap:()=>showPlayerDetails(context,p))).toList()),
          Column(children:ts.isEmpty?[const ProBox(title:'Aucune équipe', subtitle:'Essaye ID, nom ou manager', icon:Icons.search_off_rounded, child:Text(''))]:ts.map((t)=>TeamCard(team:t,players:widget.players,onEdit:(){},onOpen:()=>showTeamDetails(context,t,widget.players))).toList()),
          Column(children:[
            _moduleTile('Comparer', 'Ouvrir comparateur pro avec modes', Icons.compare_arrows_rounded, 1),
            _moduleTile('Team vs Team', 'Analyse équipe contre équipe', Icons.shield_rounded, 10),
            _moduleTile('Tactical Lab', 'Scénarios, duels et lecture coach', Icons.sports_soccer_rounded, 18),
            _moduleTile('Football Knowledge', 'Stats, PlayStyles, traits', Icons.school_rounded, 14),
            _moduleTile('Formation Counter', 'Contres recommandés', Icons.account_tree_rounded, 12),
          ]),
        ]),
      ],
      const SizedBox(height:12),
      UxTabSection(tabs:const ['Workspaces','Favoris','Historique','Quick Actions'], height:480, children:[
        _workspaceGrid(),
        Column(crossAxisAlignment:CrossAxisAlignment.start, children:favs.map((f)=>ListTile(leading:const Icon(Icons.star_rounded,color:AppTheme.orange), title:Text(f,style:const TextStyle(fontWeight:FontWeight.w900)), subtitle:const Text('Favori rapide'), onTap:()=>setState(()=>q=f))).toList()),
        Column(children:['Dernière comparaison','Dernier Team vs Team','Dernier transfert','Dernière formation provisoire'].map((x)=>ListTile(leading:const Icon(Icons.history_rounded), title:Text(x,style:const TextStyle(fontWeight:FontWeight.w900)), subtitle:const Text('Reprendre rapidement'))).toList()),
        Column(children:[
          _actionButton('Comparer 2 joueurs', Icons.compare_arrows_rounded, 1),
          _actionButton('Analyser une équipe', Icons.analytics_rounded, 9),
          _actionButton('Simuler Team vs Team', Icons.auto_awesome_rounded, 10),
          _actionButton('Ouvrir Tactical Lab', Icons.sports_soccer_rounded, 18),
          _actionButton('Exporter DB', Icons.import_export_rounded, 23),
        ]),
      ]),
    ]);
  }
  Widget _moduleTile(String title,String sub,IconData icon,int tab)=>ListTile(leading:Icon(icon,color:AppTheme.green),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(sub),trailing:const Icon(Icons.arrow_forward_ios_rounded,size:16),onTap:()=>widget.onGo(tab));
  Widget _actionButton(String title,IconData icon,int tab)=>Padding(padding:const EdgeInsets.only(bottom:8),child:SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>widget.onGo(tab),icon:Icon(icon),label:Text(title))));
  Widget _workspaceGrid()=>Column(children:[
    Row(children:[Expanded(child:_ws('Scout','Players • Teams • Managers',Icons.travel_explore_rounded,3)),const SizedBox(width:10),Expanded(child:_ws('Analyse','Compare • Analyzer • Matchups',Icons.analytics_rounded,1))]),
    const SizedBox(height:10),
    Row(children:[Expanded(child:_ws('Coach','Tactical Lab • Situations',Icons.sports_soccer_rounded,18)),const SizedBox(width:10),Expanded(child:_ws('Simulation','Team vs Team • IA',Icons.auto_awesome_rounded,10))]),
    const SizedBox(height:10),
    Row(children:[Expanded(child:_ws('Database','CRUD • Transferts • XI',Icons.storage_rounded,5)),const SizedBox(width:10),Expanded(child:_ws('Settings','Backup • Export DB',Icons.settings_rounded,27))]),
  ]);
  Widget _ws(String title,String sub,IconData icon,int tab)=>InkWell(onTap:()=>widget.onGo(tab),borderRadius:BorderRadius.circular(22),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppTheme.surface,borderRadius:BorderRadius.circular(22),border:Border.all(color:AppTheme.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:AppTheme.green),const SizedBox(height:10),Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text(sub,style:const TextStyle(color:AppTheme.muted,fontWeight:FontWeight.w700))])));
}

void showQuickActions(BuildContext context, ValueChanged<int> onGo){
  showUxDetailModal(context,'Quick Actions',[ProBox(title:'Actions rapides', subtitle:'Accès direct sans chercher dans le menu', icon:Icons.bolt_rounded, child:Wrap(spacing:8,runSpacing:8, children:[
    _quickChip(context,'Comparer',Icons.compare_arrows_rounded,1,onGo),
    _quickChip(context,'Team vs Team',Icons.shield_rounded,10,onGo),
    _quickChip(context,'Tactical Lab',Icons.sports_soccer_rounded,18,onGo),
    _quickChip(context,'Formation Counter',Icons.account_tree_rounded,12,onGo),
    _quickChip(context,'Export DB',Icons.import_export_rounded,23,onGo),
    _quickChip(context,'Knowledge',Icons.school_rounded,14,onGo),
  ]))]);
}
Widget _quickChip(BuildContext context,String label,IconData icon,int tab,ValueChanged<int> onGo)=>ActionChip(avatar:Icon(icon,size:18),label:Text(label),onPressed:(){Navigator.maybePop(context);onGo(tab);});

void showGlobalCommandSearch(BuildContext context, List<Player> players, List<TeamInfo> teams, ValueChanged<int> onGo){
  showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>DraggableScrollableSheet(initialChildSize:.86,minChildSize:.55,maxChildSize:.96,builder:(context,ctrl){
    String localQ='';
    return StatefulBuilder(builder:(context,setLocal){
      final q=localQ.trim().toLowerCase();
      final ps=players.where((p)=>q.isNotEmpty&&('${p.name} ${p.team} ${p.pos} ${p.playstyles.join(' ')}').toLowerCase().contains(q)).take(10).toList();
      final ts=teams.where((t)=>q.isNotEmpty&&('${t.name} ${t.manager}').toLowerCase().contains(q)).take(8).toList();
      return Container(decoration:const BoxDecoration(color:AppTheme.bg,borderRadius:BorderRadius.vertical(top:Radius.circular(30))),child:ListView(controller:ctrl,padding:const EdgeInsets.all(16),children:[
        Header('Recherche globale','Trouve une info puis ouvre directement le bon module'),
        TextField(autofocus:true,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Joueur, équipe, manager, stat, playstyle...'),onChanged:(v)=>setLocal(()=>localQ=v)),
        const SizedBox(height:12),
        if(q.isEmpty) ProBox(title:'Suggestions', subtitle:'Tape ou choisis une action', icon:Icons.tips_and_updates_rounded, child:Wrap(spacing:8,runSpacing:8,children:[
          _quickChip(context,'Comparer',Icons.compare_arrows_rounded,1,onGo), _quickChip(context,'Team vs Team',Icons.shield_rounded,10,onGo), _quickChip(context,'Tactical Lab',Icons.sports_soccer_rounded,18,onGo), _quickChip(context,'Knowledge',Icons.school_rounded,14,onGo)
        ])),
        if(ps.isNotEmpty) ProBox(title:'Joueurs', subtitle:'Résultats rapides', icon:Icons.person_search_rounded, child:Column(children:ps.map((p)=>PlayerTile(p:p,onTap:()=>showPlayerDetails(context,p))).toList())),
        if(ts.isNotEmpty) ProBox(title:'Équipes', subtitle:'Résultats rapides', icon:Icons.shield_rounded, child:Column(children:ts.map((t)=>ListTile(title:Text(t.name,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(t.manager),onTap:()=>showTeamDetails(context,t,players))).toList())),
        if(q.isNotEmpty) ProBox(title:'Modules liés', subtitle:'Ouvrir avec cette recherche', icon:Icons.open_in_new_rounded, child:Wrap(spacing:8,runSpacing:8,children:[
          _quickChip(context,'Comparateur',Icons.compare_arrows_rounded,1,onGo),_quickChip(context,'Team vs Team',Icons.compare_rounded,10,onGo),_quickChip(context,'Matchups',Icons.hub_rounded,16,onGo),_quickChip(context,'Knowledge',Icons.school_rounded,14,onGo),
        ])),
      ]));
    });
  }));
}


/* === v8.2 build-fix minimal fallback classes === */

class TeamsPage extends StatefulWidget {
  final List<TeamInfo> teams;
  final List<Player> players;
  final ValueChanged<TeamInfo> onEditTeam;
  const TeamsPage({super.key, required this.teams, required this.players, required this.onEditTeam});
  @override State<TeamsPage> createState()=>_TeamsPageState();
}
class _TeamsPageState extends State<TeamsPage> {
  String q=''; bool showWomen=false; bool showSoccerAid=false;
  bool hiddenTeam(TeamInfo t){ final n=t.name.toLowerCase(); if(!showWomen && n.contains('women')) return true; if(!showSoccerAid && (n.contains('soccer aid')||n.contains('classic xi')||n.contains('adidas'))) return true; return false; }
  @override Widget build(BuildContext context){
    final rows=widget.teams.where((t)=>!hiddenTeam(t) && (q.trim().isEmpty || ('${t.name} ${t.manager}').toLowerCase().contains(q.toLowerCase()))).take(250).toList();
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('Teams Database Pro', '${rows.length} équipes affichées'),
      ProBox(title:'Filtres équipes', subtitle:'Female & Soccer Aid cachés par défaut', icon:Icons.filter_list_rounded, child:Column(children:[
        TextField(decoration: const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'Chercher équipe ou manager...'), onChanged:(v)=>setState(()=>q=v)),
        const SizedBox(height:8),
        Wrap(spacing:8, children:[
          FilterChip(label:const Text('Afficher Female'), selected:showWomen, onSelected:(v)=>setState(()=>showWomen=v)),
          FilterChip(label:const Text('Afficher Soccer Aid'), selected:showSoccerAid, onSelected:(v)=>setState(()=>showSoccerAid=v)),
        ]),
      ])),
      ...rows.map((t)=>TeamCard(team:t, players:widget.players, onEdit:()=>widget.onEditTeam(t), onOpen:()=>showTeamDetails(context,t,widget.players))),
    ]);
  }
}

class TeamCard extends StatelessWidget {
  final TeamInfo team;
  final List<Player> players;
  final VoidCallback onEdit;
  final VoidCallback? onOpen;
  const TeamCard({super.key, required this.team, required this.players, required this.onEdit, this.onOpen});
  @override Widget build(BuildContext context) {
    final squad = _teamSquad(team, players).take(5).toList();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: const Color(0xFF22C55E), child: Text(team.name.substring(0,1), style: const TextStyle(fontWeight:FontWeight.w900, color:Color(0xFF052E16)))),
              const SizedBox(width:10),
              Expanded(child: Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              IconButton.filledTonal(onPressed: onEdit, icon: const Icon(Icons.edit)),
              const Icon(Icons.chevron_right_rounded),
            ]),
            Text('Manager: ${team.manager}'),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: MiniScore('OVR', team.overall, 'team')), const SizedBox(width: 8), Expanded(child: MiniScore('ATT', team.attack, 'attack')), const SizedBox(width: 8), Expanded(child: MiniScore('DEF', team.defense, 'def'))]),
            if (squad.isNotEmpty) const Divider(),
            ...squad.map((p) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: PlayerAvatar(p: p, size: 36), title: Text(p.name), subtitle: Text('${p.pos} • OVR ${p.ovr}'), trailing: Text(p.accel, style: const TextStyle(fontSize:11, color:AppTheme.ink, fontWeight:FontWeight.w800)))),
          ]),
        ),
      ),
    );
  }
}

List<Player> _teamSquad(TeamInfo team, List<Player> players){
  final byId={for(final p in players) p.id:p};
  final xi=team.xi.map((id)=>byId[id]).whereType<Player>().toList();
  final teamLower=team.name.toLowerCase();
  bool allowExtra(Player p){
    if(isHiddenPlayer(p)) return false;
    final sameId = team.id.isNotEmpty && p.teamId.isNotEmpty && p.teamId == team.id;
    final sameName = p.team == team.name;
    if(!sameId && !sameName) return false;
    if(team.id.isNotEmpty && p.teamId.isNotEmpty && p.teamId != team.id) return false;
    if(xi.isNotEmpty && !teamLower.contains('women') && !teamLower.contains('female')){
      // Avoid mixing female club players when the DB uses same display name for men/women.
      if(p.gender != 0) return false;
      if(p.name.startsWith('Player ') && !xi.any((x)=>x.id==p.id)) return false;
    }
    return true;
  }
  final sameTeam=players.where(allowExtra).toList()..sort((a,b)=>b.ovr.compareTo(a.ovr));
  final out=<Player>[];
  for(final p in xi){ if(!out.any((x)=>x.id==p.id) && !isHiddenPlayer(p)) out.add(p); }
  for(final p in sameTeam){ if(!out.any((x)=>x.id==p.id)) out.add(p); }
  return out;
}

void showTeamDetails(BuildContext context, TeamInfo team, List<Player> players){
  showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor: AppTheme.bg, builder:(_)=>TeamDetailsSheet(team:team, players:players));
}

class TeamDetailsSheet extends StatelessWidget{
  final TeamInfo team; final List<Player> players;
  const TeamDetailsSheet({super.key, required this.team, required this.players});
  @override Widget build(BuildContext context){
    final squad=_teamSquad(team, players);
    return DraggableScrollableSheet(initialChildSize:.92, maxChildSize:.98, minChildSize:.45, expand:false, builder:(_,controller)=>ListView(controller:controller, padding:const EdgeInsets.all(16), children:[
      Container(padding:const EdgeInsets.all(18), decoration:BoxDecoration(borderRadius:BorderRadius.circular(30), gradient:const LinearGradient(colors:[Color(0xFF065F46), Color(0xFF2563EB)])), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(team.name, style:const TextStyle(fontSize:30, fontWeight:FontWeight.w900, color:Colors.white)),
        Text('Manager ${team.manager}', style:const TextStyle(color:Colors.white70)),
        const SizedBox(height:12),
        Row(children:[Expanded(child:_teamBadge('OVR',team.overall)), const SizedBox(width:8), Expanded(child:_teamBadge('ATT',team.attack)), const SizedBox(width:8), Expanded(child:_teamBadge('MID',team.midfield)), const SizedBox(width:8), Expanded(child:_teamBadge('DEF',team.defense))]),
      ])),
      const SizedBox(height:12),
      UxTabSection(tabs:const ['Overview','Terrain','XI','Bench','Traits','Tactics','Analysis','Counter'], height:720, children:[
        Column(children:[
          ProBox(title:'Résumé équipe', subtitle:'Vue rapide sans scroll long', icon:Icons.dashboard_rounded, child:Wrap(spacing:8,runSpacing:8,children:[Chip(label:Text('OVR ${team.overall}')),Chip(label:Text('ATT ${team.attack}')),Chip(label:Text('MID ${team.midfield}')),Chip(label:Text('DEF ${team.defense}')),Chip(label:Text('Manager ${team.manager}'))])),
          ProTeamWeaknessReport(team:team, players:players),
        ]),
        ProBox(title:'Formation terrain', subtitle:'XI détecté depuis la database quand disponible', icon:Icons.sports_soccer_rounded, child:SizedBox(height:520, child:TeamPitchView(players:squad.take(11).toList()))),
        ProBox(title:'XI titulaire', subtitle:'Les 11 joueurs sur terrain', icon:Icons.groups_rounded, child:Column(children:squad.take(11).map((p)=>PlayerTile(p:p, onTap:()=>showPlayerDetails(context,p))).toList())),
        ProBox(title:'Remplaçants', subtitle:'Banc détecté depuis les joueurs de la même équipe', icon:Icons.swap_horiz_rounded, child:Column(children:squad.skip(11).take(24).map((p)=>PlayerTile(p:p, onTap:()=>showPlayerDetails(context,p))).toList())),
        _traitsTeamBox(),
        _tacticsTeamBox(),
        ProBox(title:'Analyse tactique rapide', subtitle:'Ce que tu dois attaquer / éviter', icon:Icons.psychology_alt_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(_coachTip(team), style: const TextStyle(fontWeight:FontWeight.w800, color:Color(0xFF86EFAC))), const SizedBox(height:8), Text('Force principale : ${team.strongTraits.take(3).join(', ')}. Faiblesse principale : ${team.weakTraits.take(3).join(', ')}.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))])),
        ProBox(title:'Counters recommandés', subtitle:'Plans contre cette équipe', icon:Icons.alt_route_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(_counterPlan(team), style:const TextStyle(height:1.45,fontWeight:FontWeight.w800)), const SizedBox(height:8), Wrap(spacing:8,runSpacing:8,children:['Surcharge côté faible','Cutback','Pressing ciblé','Renversement','Bloc medium'].map((x)=>Chip(label:Text(x))).toList())])),
      ]),
    ]));
  }
  Widget _teamBadge(String l,int v)=>Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white.withOpacity(.15), borderRadius:BorderRadius.circular(16)), child:Column(children:[Text('$v', style:const TextStyle(color:Colors.white, fontSize:18, fontWeight:FontWeight.w900)), Text(l, style:const TextStyle(color:Colors.white70, fontSize:11))]));
  Widget _traitsTeamBox()=>ProBox(title:'Traits tactiques équipe', subtitle:'Fort / faible / égal', icon:Icons.psychology_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[_traitLine('Fort',team.strongTraits,AppTheme.green), const SizedBox(height:8), _traitLine('Faible',team.weakTraits,AppTheme.danger), const SizedBox(height:8), _traitLine('Égal',team.equalTraits,AppTheme.orange)]));
  Widget _traitLine(String title,List<String> xs,Color c)=>Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(title,style:TextStyle(color:c,fontWeight:FontWeight.w900)),Wrap(spacing:8,runSpacing:8,children:(xs.isEmpty?['—']:xs).map((x)=>Chip(label:Text(x))).toList())]);
  Widget _tacticsTeamBox()=>ProBox(title:'Tactics / style équipe', subtitle:'Lecture utile pour Team vs Team', icon:Icons.account_tree_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text('Build-up : ${team.midfield>=82?'construction forte, sortie propre':'construction fragile, presser les relais'}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('Attaque : ${team.attack>=82?'danger élevé dans les 30m':'attaque à isoler et forcer loin du but'}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('Défense : ${team.defense>=82?'duels directs difficiles':'attaquer profondeur et cutback'}',style:const TextStyle(fontWeight:FontWeight.w800))]));
  String _coachTip(TeamInfo t){ if(t.defense<78) return 'Plan : attaque la profondeur et vise les espaces LB-CB / RB-CB.'; if(t.midfield<78) return 'Plan : surcharge le milieu avec triangles courts puis renverse vite.'; if(t.attack<78) return 'Plan : bloc medium, ferme l’axe et force les centres faibles.'; return 'Plan : varie tempo, cutbacks et appels dans le dos après fixation.'; }
  String _counterPlan(TeamInfo t){ if(t.defense<80) return 'Cherche appels dans le dos, cutbacks et 1-2 rapides. Évite de temporiser dos au jeu.'; if(t.midfield<80) return 'Presse les milieux, coupe les lignes de passe et joue vertical après récupération.'; if(t.attack>84) return 'Ne donne pas d’espaces en transition. Garde un CDM en couverture et force l’adversaire sur les côtés.'; return 'Match équilibré : gagne par micro-duels, patience et changement d’aile.'; }
}

class TeamPitchView extends StatelessWidget{
  final List<Player> players;
  const TeamPitchView({super.key, required this.players});
  @override Widget build(BuildContext context){
    final pts=[const Offset(.50,.90), const Offset(.18,.72), const Offset(.38,.72), const Offset(.62,.72), const Offset(.82,.72), const Offset(.25,.50), const Offset(.50,.48), const Offset(.75,.50), const Offset(.22,.25), const Offset(.50,.20), const Offset(.78,.25)];
    return LayoutBuilder(builder:(context,c){
      return Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(26), gradient:const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFF166534), Color(0xFF22C55E)])), child:Stack(children:[
        Positioned.fill(child:CustomPaint(painter:_PitchLines())),
        for(int i=0;i<players.length && i<pts.length;i++) Positioned(left:pts[i].dx*c.maxWidth-34, top:pts[i].dy*c.maxHeight-34, child:Column(children:[PlayerAvatar(p:players[i], size:58), const SizedBox(height:2), Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration:BoxDecoration(color:Colors.black.withOpacity(.45), borderRadius:BorderRadius.circular(10)), child:Text(players[i].name.replaceFirst('Player ', '#'), style:const TextStyle(color:Colors.white, fontSize:11, fontWeight:FontWeight.w800)))])),
      ]));
    });
  }
}
class _PitchLines extends CustomPainter{ @override void paint(Canvas c, Size s){ final p=Paint()..color=Colors.white.withOpacity(.18)..style=PaintingStyle.stroke..strokeWidth=2; final r=RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(26)); c.drawRRect(r,p); c.drawLine(Offset(0,s.height/2), Offset(s.width,s.height/2), p); c.drawCircle(Offset(s.width/2,s.height/2), s.width*.16, p); c.drawRect(Rect.fromCenter(center:Offset(s.width/2,0), width:s.width*.42, height:s.height*.16), p); c.drawRect(Rect.fromCenter(center:Offset(s.width/2,s.height), width:s.width*.42, height:s.height*.16), p);} @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}




class AdvancedScenario {
  final String key, label, duel, advice;
  final List<String> focus;
  const AdvancedScenario(this.key, this.label, this.duel, this.focus, this.advice);
}

const advancedScenarios = <AdvancedScenario>[
  AdvancedScenario('pressing_1v1','Pressing 1v1 — attaquer le porteur','pressing',['Acceleration','Aggression','Stamina','Reactions','Def. Awareness','Strength'],'Le presseur doit fermer vite l’espace : Relentless+, Intercept+ et Bruiser+ sont très utiles.'),
  AdvancedScenario('counter_press','Contre-pressing après perte','pressing',['Stamina','Aggression','Acceleration','Reactions','Interceptions'],'Après perte, priorité à endurance + agressivité + accélération pour récupérer avant que l’adversaire respire.'),
  AdvancedScenario('pass_vs_interception','Passe vs Interception','interception',['Vision','Short Passing','Long Passing','Composure','Interceptions'],'Le passeur gagne avec vision/précision, le défenseur avec interceptions/awareness/réactions.'),
  AdvancedScenario('through_pass_vs_cb','Passe en profondeur vs CB','through_ball',['Vision','Long Passing','Sprint Speed','Acceleration','Def. Awareness'],'Analyse la passe + appel contre la vitesse/lecture du CB, surtout contre défense haute.'),
  AdvancedScenario('build_up_under_press','Sortie de balle sous pressing','shield',['Ball Control','Composure','Short Passing','Balance','Press Proven+'],'Sous pressing, Press Proven+, Tiki Taka+ et composure changent fortement les animations.'),
  AdvancedScenario('cutback_attack','Attaque cutback / passe en retrait','crossing',['Acceleration','Dribbling','Crossing','Vision','Short Passing'],'Gagner le côté puis passe en retrait : accélération, dribble, vision et centre court.'),
  AdvancedScenario('cutback_defense','Défendre cutback','cutback_def',['Def. Awareness','Interceptions','Reactions','Acceleration','Block+'],'Couper la passe en retrait, fermer le point de penalty, ne pas sortir trop tôt.'),
  AdvancedScenario('low_block_break','Casser bloc bas','low_block_break',['Vision','Short Passing','Long Passing','Composure','Incisive Pass+'],'Cherche le joueur capable de casser une ligne avec calme et passe incisive.'),
  AdvancedScenario('low_block_defend','Défendre bloc bas','low_block_defend',['Def. Awareness','Interceptions','Reactions','Strength','Block+'],'Fermer l’axe et bloquer la zone plutôt que courir vers le porteur.'),
  AdvancedScenario('transition_attack','Transition offensive rapide','transition_attack',['Sprint Speed','Acceleration','Ball Control','Long Passing','Rapid+'],'Après récupération, lance vite le joueur qui garde sa vitesse balle au pied.'),
  AdvancedScenario('transition_defense','Transition défensive / retour','transition_defense',['Sprint Speed','Acceleration','Stamina','Def. Awareness'],'Le retour défensif dépend autant de la course longue que de la lecture de trajectoire.'),
  AdvancedScenario('wing_cross','Centre depuis l’aile','wing_cross',['Crossing','Acceleration','Dribbling','Vision','Whipped Pass+'],'Forcer le bon pied, créer un angle de centre et viser deuxième poteau/cutback.'),
  AdvancedScenario('box_header','Centre surface / tête','box_header',['Heading','Jumping','Strength','Height','Aerial+'],'Timing + taille + Aerial/Power Header décident souvent l’animation.'),
  AdvancedScenario('hold_up_play','Pivot / jouer dos au but','hold_up_play',['Strength','Balance','Ball Control','Composure','Press Proven+'],'Fixer le CB, protéger, remise courte, puis appel du troisième homme.'),
  AdvancedScenario('first_touch_turn','Contrôle orienté + demi-tour','first_touch_turn',['First Touch+','Ball Control','Agility','Balance','Reactions'],'Premier contrôle propre sous pression puis sortie côté faible.'),
  AdvancedScenario('manual_jockey','Jockey défensif / contenir','jockey',['Def. Awareness','Agility','Balance','Standing Tackle','Reactions','Jockey+'],'Ne pas tacler trop tôt : contenir, fermer l’angle, attendre la mauvaise touche.'),
  AdvancedScenario('second_ball','Deuxième ballon / duel milieu','pressing',['Reactions','Aggression','Stamina','Interceptions','Strength','Balance'],'Après dégagement ou ballon repoussé, réactions + agressivité gagnent la deuxième action.'),
  AdvancedScenario('overlap_fullback','Overlap latéral / appel extérieur','speed_long',['Sprint Speed','Stamina','Crossing','Acceleration','Short Passing'],'Latéral qui double : course longue, répétition d’efforts, centre ou cutback.'),
  AdvancedScenario('inside_forward','Ailier inversé qui rentre intérieur','dribble_central',['Dribbling','Agility','Balance','Finishing','Finesse+','Technical+'],'Attaque l’espace entre latéral et CB : crochet intérieur, pied fort, finesse ou passe cassante.'),
];

class ScenarioTacticalBoard extends StatelessWidget {
  final AdvancedScenario scenario;
  final Player a, b;
  final List<Player> squad;
  const ScenarioTacticalBoard({super.key, required this.scenario, required this.a, required this.b, required this.squad});
  @override Widget build(BuildContext context){
    final attack = scenario.key.contains('cutback') || scenario.key.contains('transition') || scenario.key.contains('inside') || scenario.key.contains('overlap') || scenario.key.contains('low_block');
    final pts=[const Offset(.50,.86), const Offset(.20,.68), const Offset(.38,.69), const Offset(.62,.69), const Offset(.80,.68), const Offset(.30,.50), const Offset(.50,.48), const Offset(.70,.50), const Offset(.24,.27), const Offset(.50,.22), const Offset(.76,.27)];
    return LayoutBuilder(builder:(context,c){
      return Container(height: 360, decoration:BoxDecoration(borderRadius:BorderRadius.circular(30), gradient: const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF6C4CF6), Color(0xFF12152F)]), boxShadow:[BoxShadow(color:AppTheme.purple.withOpacity(.16), blurRadius:28, offset:Offset(0,14))]), child:Stack(children:[
        Positioned.fill(child:CustomPaint(painter:_PitchLines())),
        Positioned(left:22, top:20, child:_boardTag(scenario.label)),
        Positioned(right:22, top:20, child:_boardTag(attack?'Phase attaque':'Phase défense')),
        if(scenario.key.contains('cutback')) ...[
          _arrow(c, const Offset(.80,.35), const Offset(.62,.44), 'cutback'),
          _zone(c, const Offset(.58,.44), 'Point penalty'),
        ] else if(scenario.key.contains('press')) ...[
          _arrow(c, const Offset(.34,.48), const Offset(.50,.48), 'press'),
          _arrow(c, const Offset(.66,.48), const Offset(.50,.48), 'trap'),
        ] else if(scenario.key.contains('transition')) ...[
          _arrow(c, const Offset(.22,.65), const Offset(.78,.28), 'appel'),
          _arrow(c, const Offset(.42,.58), const Offset(.70,.30), 'passe'),
        ] else if(scenario.key.contains('low_block')) ...[
          _zone(c, const Offset(.50,.32), 'Bloc bas'),
          _arrow(c, const Offset(.40,.54), const Offset(.50,.34), 'passe cassante'),
        ] else ...[
          _arrow(c, const Offset(.36,.54), const Offset(.58,.42), 'duel'),
        ],
        for(int i=0;i<squad.length && i<pts.length;i++) Positioned(left:pts[i].dx*c.maxWidth-24, top:pts[i].dy*c.maxHeight-24, child:Column(children:[PlayerAvatar(p:squad[i],size:46), Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:2), decoration:BoxDecoration(color:Colors.white.withOpacity(.95), borderRadius:BorderRadius.circular(99)), child:Text(squad[i].name.replaceFirst('Player ','#'), maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:AppTheme.darkText)))])),
        Positioned(left:c.maxWidth*.22, bottom:18, child:_duelChip(a, 'A')),
        Positioned(right:c.maxWidth*.22, bottom:18, child:_duelChip(b, 'B')),
      ]));
    });
  }
  Widget _boardTag(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7), decoration:BoxDecoration(color:Colors.white.withOpacity(.90), borderRadius:BorderRadius.circular(99)), child:Text(t, style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:AppTheme.darkText)));
  Widget _duelChip(Player p, String side)=>Container(width:118, padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.white.withOpacity(.94), borderRadius:BorderRadius.circular(18)), child:Row(children:[PlayerAvatar(p:p,size:34), const SizedBox(width:6), Expanded(child:Text('$side • ${p.name}', maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:AppTheme.darkText)))]));
  Widget _zone(BoxConstraints c, Offset o, String text)=>Positioned(left:o.dx*c.maxWidth-55, top:o.dy*c.maxHeight-26, child:Container(width:110,height:52, decoration:BoxDecoration(color:AppTheme.pink.withOpacity(.26), borderRadius:BorderRadius.circular(18), border:Border.all(color:Colors.white.withOpacity(.55))), child:Center(child:Text(text, textAlign:TextAlign.center, style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:11)))));
  Widget _arrow(BoxConstraints c, Offset a, Offset b, String text)=>Positioned.fill(child:CustomPaint(painter:_ArrowPainter(Offset(a.dx*c.maxWidth,a.dy*c.maxHeight), Offset(b.dx*c.maxWidth,b.dy*c.maxHeight), text)));
}

class _ArrowPainter extends CustomPainter{
  final Offset a,b; final String label;
  _ArrowPainter(this.a,this.b,this.label);
  @override void paint(Canvas c, Size s){
    final p=Paint()..color=Colors.white.withOpacity(.85)..strokeWidth=3.2..strokeCap=StrokeCap.round;
    c.drawLine(a,b,p);
    final ang=atan2(b.dy-a.dy,b.dx-a.dx);
    final p1=b-Offset(cos(ang-.55)*12,sin(ang-.55)*12), p2=b-Offset(cos(ang+.55)*12,sin(ang+.55)*12);
    c.drawLine(b,p1,p); c.drawLine(b,p2,p);
    final tp=TextPainter(text:TextSpan(text:label, style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:11)), textDirection:TextDirection.ltr)..layout();
    tp.paint(c, Offset((a.dx+b.dx)/2-tp.width/2, (a.dy+b.dy)/2-20));
  }
  @override bool shouldRepaint(covariant _ArrowPainter old)=>old.a!=a||old.b!=b||old.label!=label;
}

class ScenarioStepCard extends StatelessWidget{
  final int n; final String title, body;
  const ScenarioStepCard(this.n,this.title,this.body,{super.key});
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10), padding:const EdgeInsets.all(14), decoration:BoxDecoration(color:AppTheme.surface, borderRadius:BorderRadius.circular(20), border:Border.all(color:AppTheme.line), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.035), blurRadius:18, offset:Offset(0,8))]), child:Row(crossAxisAlignment:CrossAxisAlignment.start, children:[Container(width:34,height:34, decoration:const BoxDecoration(shape:BoxShape.circle, gradient:LinearGradient(colors:[AppTheme.pink,AppTheme.purple])), child:Center(child:Text('$n', style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)))), const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(title, style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)), const SizedBox(height:3), Text(body, style:const TextStyle(color:AppTheme.muted,height:1.35))]))]));
}


class TacticBoardAnimationStudioPage extends StatefulWidget {
  final List<Player> players;
  final List<TeamInfo> teams;
  const TacticBoardAnimationStudioPage({super.key, required this.players, required this.teams});
  @override State<TacticBoardAnimationStudioPage> createState()=>_TacticBoardAnimationStudioPageState();
}

class _BoardPlayer {
  final String id;
  final bool own;
  Offset pos;
  Offset target;
  Player? player;
  _BoardPlayer(this.id, this.own, this.pos, {this.player}) : target = pos;
}
class _BoardFrame {
  final String name;
  final Map<String, Offset> pos;
  final Offset ball;
  const _BoardFrame(this.name, this.pos, this.ball);
}

class _TacticBoardAnimationStudioPageState extends State<TacticBoardAnimationStudioPage> with SingleTickerProviderStateMixin {
  late AnimationController ctrl;
  String preset='3v2', tool='move', selectedTeamName='';
  int ownCount=3, oppCount=2, currentFrame=0;
  bool showWomen=false, showSoccerAid=false, showJson=false;
  final List<_BoardPlayer> boardPlayers=[];
  final List<_BoardFrame> frames=[];
  Offset ball=const Offset(.45,.55), ballTarget=const Offset(.70,.38);

  @override void initState(){ super.initState(); ctrl=AnimationController(vsync:this, duration:const Duration(milliseconds:1100))..addListener(()=>setState((){})); _buildPreset(); _saveFrame('Frame 1 — départ'); _setTargets(); _saveFrame('Frame 2 — mouvement synchronisé'); }
  @override void dispose(){ ctrl.dispose(); super.dispose(); }
  List<TeamInfo> get cleanTeams => cleanTeamListForPlayers(widget.teams, widget.players, showWomen:showWomen, showSoccerAid:showSoccerAid);
  TeamInfo? get selectedTeam { final list=cleanTeams; if(list.isEmpty) return null; return list.firstWhere((t)=>t.name==selectedTeamName, orElse:()=>list.first); }
  List<Player> get squad => selectedTeam==null ? cleanPlayerList(widget.players, showWomen:showWomen, showSoccerAid:showSoccerAid).take(18).toList() : _teamSquad(selectedTeam!, widget.players).take(24).toList();

  void _buildPreset(){
    boardPlayers.clear();
    if(selectedTeamName.isEmpty && cleanTeams.isNotEmpty) selectedTeamName=cleanTeams.first.name;
    final sq=squad;
    final ownPts = preset=='rondo' ? [const Offset(.36,.34),const Offset(.64,.34),const Offset(.36,.66),const Offset(.64,.66)] : preset=='build' ? [const Offset(.18,.74),const Offset(.32,.60),const Offset(.32,.40),const Offset(.46,.50),const Offset(.60,.34),const Offset(.60,.66)] : [const Offset(.20,.70),const Offset(.42,.62),const Offset(.66,.50),const Offset(.80,.34),const Offset(.55,.26),const Offset(.28,.40),const Offset(.74,.72)];
    final oppPts = preset=='rondo' ? [const Offset(.50,.44),const Offset(.50,.56)] : [const Offset(.48,.50),const Offset(.62,.38),const Offset(.70,.64),const Offset(.35,.35),const Offset(.35,.65)];
    final oc = preset=='rondo' ? 4 : ownCount.clamp(1,11);
    final bc = preset=='rondo' ? 2 : oppCount.clamp(0,11);
    for(int i=0;i<oc;i++){ boardPlayers.add(_BoardPlayer('M${i+1}', true, ownPts[i%ownPts.length], player: sq.isNotEmpty ? sq[i%sq.length] : null)); }
    for(int i=0;i<bc;i++){ boardPlayers.add(_BoardPlayer('A${i+1}', false, oppPts[i%oppPts.length])); }
    ball= preset=='rondo'?const Offset(.50,.50):const Offset(.43,.58); ballTarget=const Offset(.72,.42); ctrl.value=0;
  }
  void _setTargets(){
    for(final p in boardPlayers){
      if(p.own){
        if(preset=='3v2'||preset=='counter') p.target=Offset((p.pos.dx+.16).clamp(.06,.94),(p.pos.dy+(p.id.endsWith('1')?-.10:(p.id.endsWith('2') ? .02 : .10))).clamp(.08,.92));
        else if(preset=='rondo') p.target=Offset((p.pos.dx+(((p.id.endsWith('1') || p.id.endsWith('3')) ? .07 : -.07))).clamp(.06,.94),(p.pos.dy+(((p.id.endsWith('1') || p.id.endsWith('2')) ? .05 : -.05))).clamp(.08,.92));
        else if(preset=='build') p.target=Offset((p.pos.dx+.10).clamp(.06,.94),(p.pos.dy+(p.id.endsWith('4')?-.10:(p.id.endsWith('5') ? .07 : 0))).clamp(.08,.92));
        else p.target=Offset((p.pos.dx+.12).clamp(.06,.94),p.pos.dy);
      } else { p.target=Offset((p.pos.dx-.04).clamp(.06,.94),(p.pos.dy+((p.id.endsWith('1') ? .08 : -.08))).clamp(.08,.92)); }
    }
    ballTarget = preset=='3v2' ? const Offset(.78,.38) : preset=='rondo' ? const Offset(.64,.34) : preset=='build' ? const Offset(.62,.34) : const Offset(.74,.50);
  }
  void _saveFrame(String name){ frames.add(_BoardFrame(name, {for(final p in boardPlayers) p.id:p.pos}, ball)); currentFrame=frames.length-1; }
  void _goFrame(int i){ if(i<0||i>=frames.length) return; final f=frames[i]; setState((){currentFrame=i; for(final p in boardPlayers){ if(f.pos[p.id]!=null){p.pos=f.pos[p.id]!; p.target=p.pos;} } ball=f.ball; ballTarget=ball; ctrl.value=0;}); }
  String _json()=>jsonEncode({'preset':preset,'own':ownCount,'opp':oppCount,'team':selectedTeamName,'tool':tool,'ball':{'x':ball.dx,'y':ball.dy},'players':boardPlayers.map((p)=>{'id':p.id,'own':p.own,'x':p.pos.dx,'y':p.pos.dy,'targetX':p.target.dx,'targetY':p.target.dy,'playerid':p.player?.id,'name':p.player?.name}).toList(),'frames':frames.map((f)=>{'name':f.name,'ball':{'x':f.ball.dx,'y':f.ball.dy},'pos':f.pos.map((k,v)=>MapEntry(k,{'x':v.dx,'y':v.dy}))}).toList()});

  @override Widget build(BuildContext context){
    final t=Curves.easeInOut.transform(ctrl.value);
    return ListView(padding:const EdgeInsets.all(16), children:[
      Header('Tactic Board Animation Studio Pro', 'Drag & drop réel, keyframes, groupes simultanés, passe/tir/dribble/pressing/zone/duel'),
      ProBox(title:'Studio controls', subtitle:'Presets + joueurs custom + équipe autocomplete', icon:Icons.tune_rounded, child:Column(children:[
        LayoutBuilder(builder:(context,c){
          final w=[DropdownButtonFormField<String>(value:preset, decoration:const InputDecoration(labelText:'Preset'), items:['3v2','4v3','5v4','rondo','counter','build'].map((x)=>DropdownMenuItem(value:x, child:Text(x))).toList(), onChanged:(v)=>setState((){preset=v!; _buildPreset(); frames.clear(); _saveFrame('Frame 1 — départ');})), TextFormField(initialValue:'$ownCount', keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Mes joueurs'), onChanged:(v)=>setState(()=>ownCount=int.tryParse(v)??ownCount)), TextFormField(initialValue:'$oppCount', keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Adversaires'), onChanged:(v)=>setState(()=>oppCount=int.tryParse(v)??oppCount))];
          return c.maxWidth<560?Column(children:[w[0],const SizedBox(height:8),Row(children:[Expanded(child:w[1]),const SizedBox(width:8),Expanded(child:w[2])])]):Row(children:[Expanded(child:w[0]),const SizedBox(width:8),Expanded(child:w[1]),const SizedBox(width:8),Expanded(child:w[2])]);
        }),
        const SizedBox(height:10),
        TeamAutocomplete(teams:cleanTeams, value:selectedTeamName, label:'Équipe hommes par défaut', onSelected:(name)=>setState((){selectedTeamName=name; _buildPreset(); frames.clear(); _saveFrame('Frame 1 — départ');})),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children:[
          for(final x in ['move','pass','shot','dribble','run','press','zone','duel','delete']) ChoiceChip(label:Text(x), selected:tool==x, onSelected:(_)=>setState(()=>tool=x)),
          FilterChip(label:const Text('Afficher Female'), selected:showWomen, onSelected:(v)=>setState(()=>showWomen=v)),
          FilterChip(label:const Text('Afficher Soccer Aid'), selected:showSoccerAid, onSelected:(v)=>setState(()=>showSoccerAid=v)),
        ])
      ])),
      Card(child:Padding(padding:const EdgeInsets.all(12), child:Column(children:[
        AspectRatio(aspectRatio:.76, child:LayoutBuilder(builder:(context,c){
          return Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(30), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.12), blurRadius:28, offset:Offset(0,16))]), child:ClipRRect(borderRadius:BorderRadius.circular(30), child:CustomPaint(painter:_TacticBoardPainter(boardPlayers,t,tool,preset, ball, ballTarget), child:Stack(children:[
            Positioned(left:Offset.lerp(ball,ballTarget,t)!.dx*c.maxWidth-10, top:Offset.lerp(ball,ballTarget,t)!.dy*c.maxHeight-10, child:GestureDetector(onPanUpdate:(d)=>setState(()=>ball=Offset((ball.dx+d.delta.dx/c.maxWidth).clamp(.04,.96),(ball.dy+d.delta.dy/c.maxHeight).clamp(.04,.96))), child:Container(width:20,height:20, decoration:BoxDecoration(color:Colors.white, shape:BoxShape.circle, border:Border.all(color:AppTheme.navy,width:2))))),
            for(final p in boardPlayers) AnimatedBuilder(animation:ctrl, builder:(context,_){ final o=Offset.lerp(p.pos,p.target,t)!; return Positioned(left:o.dx*c.maxWidth-29, top:o.dy*c.maxHeight-34, child:GestureDetector(onPanUpdate:(d)=>setState((){p.pos=Offset((p.pos.dx+d.delta.dx/c.maxWidth).clamp(.04,.96),(p.pos.dy+d.delta.dy/c.maxHeight).clamp(.04,.96)); p.target=p.pos;}), onTap:() async { if(p.own){ final pick=await showPlayerSearch(context, squad.isEmpty?widget.players:squad, p.player ?? (squad.isNotEmpty?squad.first:widget.players.first)); if(pick!=null) setState(()=>p.player=pick); }}, child:Column(children:[Container(padding:const EdgeInsets.all(3), decoration:BoxDecoration(shape:BoxShape.circle, color:p.own?const Color(0xFF24C6DC):const Color(0xFFFF5573), border:Border.all(color:Colors.white,width:2)), child:PlayerAvatar(p:p.player ?? _dummyPlayer(p), size:52)), Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration:BoxDecoration(color:Colors.black.withOpacity(.55), borderRadius:BorderRadius.circular(999)), child:Text(p.player?.name.split(' ').last ?? p.id, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)))])));}),
          ]))));
        })),
        const SizedBox(height:12),
        Wrap(spacing:8, runSpacing:8, children:[
          FilledButton.icon(onPressed:(){_setTargets(); ctrl.forward(from:0);}, icon:const Icon(Icons.play_arrow_rounded), label:const Text('Play')),
          OutlinedButton.icon(onPressed:()=>setState(()=>_saveFrame('Frame ${frames.length+1} — positions')), icon:const Icon(Icons.add), label:const Text('Keyframe')),
          OutlinedButton.icon(onPressed:()=>setState(()=>frames.add(_BoardFrame('Groupe ${frames.length+1} — simultané', {for(final p in boardPlayers) p.id:p.target}, ballTarget))), icon:const Icon(Icons.group_work_rounded), label:const Text('Groupe')),
          OutlinedButton.icon(onPressed:()=>setState(_buildPreset), icon:const Icon(Icons.restart_alt), label:const Text('Reset')),
        ])
      ]))),
      ProBox(title:'Timeline / export', subtitle:'Clique une frame pour revenir à l’état sauvegardé', icon:Icons.timeline_rounded, child:Column(children:[
        ...frames.asMap().entries.map((e)=>ListTile(selected:e.key==currentFrame, leading:CircleAvatar(child:Text('${e.key+1}')), title:Text(e.value.name), subtitle:Text(e.key==0?'Départ':e.value.name.contains('Groupe')?'Actions simultanées':'Keyframe'), trailing:e.key==currentFrame?const Icon(Icons.check_circle, color:AppTheme.green):null, onTap:()=>_goFrame(e.key))),
        Wrap(spacing:8, children:[FilterChip(label:const Text('Voir JSON'), selected:showJson, onSelected:(v)=>setState(()=>showJson=v)), ActionChip(label:const Text('Copier export'), onPressed:()=>Clipboard.setData(ClipboardData(text:_json())))]),
        if(showJson) Padding(padding:const EdgeInsets.only(top:10), child:SelectableText(_json(), style:const TextStyle(fontSize:12))),
      ])),
      ProBox(title:'Duel dans la situation', subtitle:'Lecture coach de la scène comme dans le plugin', icon:Icons.psychology_alt_rounded, child:Text(_studioAdvice(), style:const TextStyle(height:1.45, fontWeight:FontWeight.w700))),
    ]);
  }
  String _studioAdvice(){
    if(preset=='3v2') return '3v2 : fixe le premier défenseur, déclenche appel extérieur + passe en retrait. Profiter : attirer le CB avant de donner. Contrer : ne pas sortir avec les deux défenseurs, couper le cutback.';
    if(preset=='rondo') return 'Rondo 4v2 : angles constants, troisième homme et passe sécurité. Profiter : jouer en une touche. Contrer : fermer le joueur libre plutôt que courir vers le ballon.';
    if(preset=='counter') return 'Contre-attaque : première passe verticale puis appel dans le dos. Profiter : jouer avant replacement. Contrer : temporiser avec le CDM et protéger axe.';
    if(preset=='build') return 'Sortie de balle : attire pressing côté fort puis trouve le 6/8 libre. Profiter : passe courte + triangle. Contrer : marquer le pivot et forcer long ballon.';
    return 'Overload : crée supériorité, attire, renverse. Contrer : coulisser sans casser la ligne.';
  }
  Player _dummyPlayer(_BoardPlayer bp)=>Player(id:bp.id,name:bp.id,team:bp.own?'Moi':'Adversaire',teamId:'',pos:bp.own?'ATT':'DEF',pos2:'',image:'',ovr:70,pot:70,height:180,weight:75,body:'Average',accel:'Controlled',foot:'Right',attWr:'Medium',defWr:'Medium',skill:3,weakFoot:3,playstyles:const[],s:const{});
}

class _TacticBoardPainter extends CustomPainter{
  final List<_BoardPlayer> players; final double t; final String tool, preset; final Offset ball, ballTarget;
  _TacticBoardPainter(this.players,this.t,this.tool,this.preset,this.ball,this.ballTarget);
  @override void paint(Canvas canvas, Size size){
    final bg=Paint()..shader=const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFF08743E),Color(0xFF064D30)]).createShader(Offset.zero & size);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(30)),bg);
    final line=Paint()..color=Colors.white.withOpacity(.30)..style=PaintingStyle.stroke..strokeWidth=2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18,18,size.width-36,size.height-36), const Radius.circular(22)), line);
    canvas.drawLine(Offset(18,size.height/2), Offset(size.width-18,size.height/2), line);
    canvas.drawCircle(Offset(size.width/2,size.height/2), 58, line);
    canvas.drawRect(Rect.fromCenter(center:Offset(size.width/2,18), width:size.width*.42, height:92), line);
    canvas.drawRect(Rect.fromCenter(center:Offset(size.width/2,size.height-18), width:size.width*.42, height:92), line);
    if(tool=='zone' || preset=='3v2' || preset=='build') canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(size.width*.68,size.height*.36), width:140, height:78), const Radius.circular(18)), Paint()..color=AppTheme.blue.withOpacity(.18));
    for(final p in players){ final a=Offset(p.pos.dx*size.width,p.pos.dy*size.height); final b=Offset.lerp(a,Offset(p.target.dx*size.width,p.target.dy*size.height),max(t,.14))!; final col=p.own?const Color(0xFFFFD166):Colors.white.withOpacity(.75); _arrow(canvas,a,b,col,p.own?3.6:2.4); }
    _arrow(canvas, Offset(ball.dx*size.width, ball.dy*size.height), Offset(ballTarget.dx*size.width, ballTarget.dy*size.height), const Color(0xFFFFFFFF), 3.4, dashed:true);
  }
  void _arrow(Canvas c, Offset a, Offset b, Color col, double w,{bool dashed=false}){ final p=Paint()..color=col..strokeWidth=w..strokeCap=StrokeCap.round; if(!dashed){c.drawLine(a,b,p);} else { const n=12; for(int i=0;i<n;i+=2){ final s=i/n, e=(i+1)/n; c.drawLine(Offset.lerp(a,b,s)!,Offset.lerp(a,b,e)!,p);} } final ang=atan2(b.dy-a.dy,b.dx-a.dx); c.drawLine(b,b-Offset(cos(ang-.55)*12,sin(ang-.55)*12),p); c.drawLine(b,b-Offset(cos(ang+.55)*12,sin(ang+.55)*12),p); }
  @override bool shouldRepaint(covariant _TacticBoardPainter old)=>true;
}

class TeamAutocomplete extends StatelessWidget{
  final List<TeamInfo> teams; final String value; final String label; final ValueChanged<String> onSelected;
  const TeamAutocomplete({super.key, required this.teams, required this.value, required this.label, required this.onSelected});
  @override Widget build(BuildContext context){
    final counts=<String,int>{};
    for(final t in teams){ counts[t.name]=(counts[t.name]??0)+1; }
    String labelOf(TeamInfo t)=> (counts[t.name]??0)>1 ? '${t.name}  • ID ${t.id}' : t.name;
    final opts=teams.map(labelOf).toList();
    return Autocomplete<String>(
      initialValue: TextEditingValue(text:value),
      optionsBuilder:(text){ final q=text.text.toLowerCase(); if(q.isEmpty) return opts.take(25); return opts.where((n)=>n.toLowerCase().contains(q)).take(30); },
      onSelected:(v)=>onSelected(v),
      fieldViewBuilder:(context,ctrl,focus,onSubmit)=>TextField(controller:ctrl, focusNode:focus, decoration:InputDecoration(labelText:label, prefixIcon:const Icon(Icons.shield_rounded), suffixIcon:IconButton(icon:const Icon(Icons.check), onPressed:()=>onSelected(ctrl.text)))),
    );
  }
}

TeamInfo? findTeamByAutocomplete(List<TeamInfo> teams, String value){
  final idMatch=RegExp(r'ID\s+([^\s]+)').firstMatch(value);
  if(idMatch!=null){
    final id=idMatch.group(1)!;
    for(final t in teams){ if(t.id==id) return t; }
  }
  final clean=value.split('•').first.trim().toLowerCase();
  final exact=teams.where((t)=>t.name.toLowerCase()==clean).toList();
  if(exact.isNotEmpty) return exact.first;
  final idExact=teams.where((t)=>t.id==value.trim()).toList();
  if(idExact.isNotEmpty) return idExact.first;
  return null;
}

class AiSimulatorPage extends StatefulWidget {
  final List<Player> players;
  final List<TeamInfo> teams;
  const AiSimulatorPage({super.key, required this.players, required this.teams});
  @override State<AiSimulatorPage> createState()=>_AiSimulatorPageState();
}

class _AiSimulatorPageState extends State<AiSimulatorPage> {
  String scenarioKey='build_up_under_press';
  TeamInfo? team;
  Player? a,b;
  bool showGuide=false;

  @override Widget build(BuildContext context) {
    final cleanTeams = cleanTeamListForPlayers(widget.teams, widget.players);
    team ??= cleanTeams.isNotEmpty ? cleanTeams.first : (widget.teams.isNotEmpty ? widget.teams.first : null);
    final simPlayers=cleanPlayerList(widget.players);
    a ??= simPlayers.firstWhere((p)=>p.name.toLowerCase().contains('mbapp'), orElse:()=>simPlayers.first);
    b ??= simPlayers.firstWhere((p)=>p.name.toLowerCase().contains('walker'), orElse:()=>simPlayers.length>1 ? simPlayers[1] : simPlayers.first);
    final sc=advancedScenarios.firstWhere((x)=>x.key==scenarioKey);
    final mode=modes.firstWhere((m)=>m.key==sc.duel, orElse:()=>modes.first);
    final sa=score(a!, mode), sb=score(b!, mode);
    final squad=team==null ? <Player>[] : _teamSquad(team!, widget.players);
    final winner=sa.total>=sb.total?a!:b!;
    return ListView(padding: const EdgeInsets.all(14), children:[
      Header('IA Simulator Pro', 'Même logique que le plugin : situation → duel → critères → lecture coach'),
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white, border: Border.all(color:AppTheme.line), boxShadow:[BoxShadow(color:Colors.black.withOpacity(.04), blurRadius:24, offset:Offset(0,10))]), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Row(children:[Container(width:50,height:50, decoration:const BoxDecoration(shape:BoxShape.circle, gradient:LinearGradient(colors:[AppTheme.pink,AppTheme.purple])), child:const Icon(Icons.auto_awesome_rounded,color:Colors.white)), const SizedBox(width:12), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('Simulation tactique', style: TextStyle(fontSize:24, fontWeight:FontWeight.w900, color:AppTheme.ink)), Text(sc.label, style: const TextStyle(color:AppTheme.muted, fontWeight:FontWeight.w700))]))]),
        const SizedBox(height:14),
        DropdownButtonFormField<String>(value:scenarioKey, isExpanded:true, decoration: const InputDecoration(labelText:'Mode IA avancé du plugin'), items:advancedScenarios.map((x)=>DropdownMenuItem(value:x.key, child:Text(x.label, overflow:TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>scenarioKey=v!)),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children:[Chip(label:Text('Duel moteur : ${mode.label}')), Chip(label:Text('Gagnant profil : ${winner.name}')), ActionChip(label:Text(showGuide?'Masquer guide':'Afficher guide complet'), onPressed:()=>setState(()=>showGuide=!showGuide))]),
      ])),
      const SizedBox(height:12),
      if(showGuide) ProBox(title:'Guide modes IA du plugin', subtitle:'Tous les scénarios disponibles et leurs conseils', icon:Icons.menu_book_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:advancedScenarios.map((x)=>Padding(padding:const EdgeInsets.only(bottom:10), child:Text('• ${x.label}\n${x.advice}', style:const TextStyle(height:1.35)))).toList())),
      ProBox(title:'Terrain tactique interactif', subtitle:'Zone, flèches, joueurs, duel et intention de jeu', icon:Icons.sports_soccer_rounded, child:Column(children:[
        if(team!=null) TeamAutocomplete(teams: cleanTeams, value: team?.name ?? '', label: 'Équipe homme par défaut — autocomplete', onSelected: (name){
          final matches = cleanTeams.where((t)=>t.name.toLowerCase()==name.toLowerCase()).toList();
          if(matches.isNotEmpty) setState(()=>team=matches.first);
        }),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children:[
          const Chip(label:Text('Mode hommes par défaut')),
          ActionChip(label:const Text('Changer équipe'), onPressed:()=>setState(()=>team=cleanTeams.isNotEmpty?cleanTeams[(cleanTeams.indexOf(team!) + 1) % cleanTeams.length]:team)),
        ]),
        const SizedBox(height:10),
        ScenarioTacticalBoard(scenario:sc, a:a!, b:b!, squad:squad.take(11).toList()),
        const SizedBox(height:10),
        Align(alignment:Alignment.centerLeft, child:Text('Banc / remplaçants', style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900))),
        const SizedBox(height:6),
        SizedBox(height:96, child:ListView(scrollDirection:Axis.horizontal, children:squad.skip(11).take(18).map((p)=>Container(width:108, margin:const EdgeInsets.only(right:8), child:Column(children:[PlayerAvatar(p:p,size:52), Text(p.name, maxLines:1, overflow:TextOverflow.ellipsis, textAlign:TextAlign.center, style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)), Text('${p.pos} • ${p.ovr}', style:const TextStyle(fontSize:11,color:AppTheme.muted))]))).toList())),
      ])),
      ProBox(title:'Duel du scénario', subtitle:'Compare exactement comme le Duel Engine Pro Plus', icon:Icons.compare_arrows_rounded, child:Column(children:[
        PlayerPicker(title:'Joueur A', players:simPlayers, value:a!, onChanged:(p)=>setState(()=>a=p)),
        PlayerPicker(title:'Joueur B', players:simPlayers, value:b!, onChanged:(p)=>setState(()=>b=p)),
        ScoreSummary(a:a!, b:b!, sa:sa, sb:sb),
      ])),
      ProBox(title:'Lecture IA Coach', subtitle:'Critères, PlayStyles utiles, décision terrain', icon:Icons.psychology_alt_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(sc.advice, style: const TextStyle(fontWeight:FontWeight.w900, height:1.35)),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children:sc.focus.map((x)=>Chip(label:Text(x))).toList()),
        const Divider(height:22),
        ScenarioStepCard(1, 'Déclencheur', _trigger(sc)),
        ScenarioStepCard(2, 'Action recommandée', _action(sc, winner)),
        ScenarioStepCard(3, 'Risque à éviter', _risk(sc)),
      ])),
      ProDuelBreakdown(a:a!, b:b!, mode:mode),
    ]);
  }

  String _trigger(AdvancedScenario sc){
    if(sc.key.contains('press')) return 'Première touche longue, joueur dos au jeu, passe latérale faible ou contrôle orienté mauvais.';
    if(sc.key.contains('cutback')) return 'Ailier/latéral entre dans la surface côté ligne, défense attire vers le but.';
    if(sc.key.contains('transition')) return 'Récupération au milieu, défense adverse haute ou latéral sorti.';
    if(sc.key.contains('low_block')) return 'Bloc regroupé dans l’axe, peu d’espace entre CB et CDM.';
    return 'Situation de duel où l’angle du corps et le timing décident l’animation.';
  }
  String _action(AdvancedScenario sc, Player win){
    if(sc.key.contains('press')) return 'Utilise ${win.name} pour fermer l’axe, puis force la passe côté faible.';
    if(sc.key.contains('cutback')) return 'Cherche la zone point de penalty ; en défense, coupe la ligne de passe avant le tacle.';
    if(sc.key.contains('transition')) return 'Joue vite dans l’espace et évite les touches inutiles. La première passe doit casser la ligne.';
    if(sc.key.contains('low_block')) return 'Attire un joueur, joue court, puis passe cassante ou troisième homme.';
    return 'Joue sur le point fort de ${win.name} et évite le type de duel qui active les PlayStyles adverses.';
  }
  String _risk(AdvancedScenario sc){
    if(sc.key.contains('press')) return 'Se jeter trop tôt ouvre la passe dans le dos du pressing.';
    if(sc.key.contains('cutback')) return 'Courir vers le porteur laisse libre la passe en retrait.';
    if(sc.key.contains('transition')) return 'Temporiser trop longtemps permet au bloc adverse de se replacer.';
    if(sc.key.contains('low_block')) return 'Forcer le dribble central déclenche souvent interception ou contre.';
    return 'Mauvais angle de corps, fatigue et timing tardif changent le résultat.';
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
      'Global cards': ['pac','sho','pas','dri','def','phy'],
      'Pace / Dribble': ['acc','sprint','agi','bal','react','ball','drib'],
      'Attack / Shooting': ['attpos','finish','shot','longshot','volleys','penalties','comp','head'],
      'Passing / Creation': ['cross','shortp','longp','vision','curve','fk'],
      'Physical / Defense': ['str','agg','stam','jump','defaw','marking','tackle','slide','inter','block'],
      'Goalkeeper': ['gkdiv','gkhan','gkkick','gkpos','gkref'],
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
  final Player? initial;
  final ValueChanged<Player> onSave;
  const PlayerCrudPage({super.key, required this.players, this.initial, required this.onSave});
  @override State<PlayerCrudPage> createState()=>_PlayerCrudPageState();
}
class _PlayerCrudPageState extends State<PlayerCrudPage> {
  Player? editing;
  String q = '';

  @override void initState(){ super.initState(); editing = widget.initial; }
  @override void didUpdateWidget(covariant PlayerCrudPage oldWidget){ super.didUpdateWidget(oldWidget); if(widget.initial?.id != oldWidget.initial?.id){ editing = widget.initial; } }

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

  @override void initState(){super.initState(); for(final k in ['pac','sho','pas','dri','def','phy','acc','sprint','str','agg','bal','agi','react','ball','drib','attpos','defaw','marking','tackle','slide','inter','block','finish','shot','longshot','volleys','penalties','comp','stam','jump','head','cross','shortp','longp','vision','curve','fk','gkdiv','gkhan','gkkick','gkpos','gkref']){statCtrls[k]=TextEditingController();} fill();}
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
      teamId: base?.teamId ?? '',
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
      gender: base?.gender ?? 0,
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

// ===============================
// V42 — Professional Workflow Edition
// UX goal: less scrolling, more workspace flow, bottom-sheet details, richer Tactical Lab/Team vs Team.
// ===============================

class V42ProfessionalWorkflowPage extends StatefulWidget {
  final List<Player> players;
  final List<TeamInfo> teams;
  final ValueChanged<int> onGo;
  final ValueChanged<Player> onOpenPlayer;
  const V42ProfessionalWorkflowPage({super.key, required this.players, required this.teams, required this.onGo, required this.onOpenPlayer});
  @override State<V42ProfessionalWorkflowPage> createState()=>_V42ProfessionalWorkflowPageState();
}

class _V42ProfessionalWorkflowPageState extends State<V42ProfessionalWorkflowPage> {
  String q='';
  final favs=<String>{'Team vs Team','Tactical Lab','Football Knowledge','Formation Counter'};
  final recent=<String>['Dernier Team vs Team','Dernière comparaison','Dernier Tactical Lab','Dernier transfert'];
  @override Widget build(BuildContext context){
    final query=q.trim().toLowerCase();
    final ps=query.isEmpty?<Player>[]:widget.players.where((p)=>('${p.name} ${p.team} ${p.pos} ${p.playstyles.join(' ')}').toLowerCase().contains(query)).take(8).toList();
    final ts=query.isEmpty?<TeamInfo>[]:widget.teams.where((t)=>('${t.name} ${t.manager} ${t.strongTraits.join(' ')}').toLowerCase().contains(query)).take(8).toList();
    return ListView(padding:const EdgeInsets.all(14), children:[
      Header('Command Center Pro', 'Recherche globale • workflows • favoris • historique • actions rapides'),
      TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.manage_search_rounded), hintText:'Chercher joueur, équipe, manager, formation, stat, PlayStyle...'), onChanged:(v)=>setState(()=>q=v)),
      const SizedBox(height:12),
      if(query.isNotEmpty) ProBox(title:'Résultats intelligents', subtitle:'Clique pour ouvrir un détail sans perdre le contexte', icon:Icons.manage_search_rounded, child:Column(children:[
        ...ps.map((p)=>ListTile(leading:PlayerAvatar(p:p,size:42), title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w900)), subtitle:Text('${p.team} • ${p.pos} • OVR ${p.ovr}'), trailing:const Icon(Icons.open_in_new_rounded), onTap:(){recent.insert(0,p.name); widget.onOpenPlayer(p); setState((){});})),
        ...ts.map((t)=>ListTile(leading:const Icon(Icons.shield_rounded,color:AppTheme.green), title:Text(t.name,style:const TextStyle(fontWeight:FontWeight.w900)), subtitle:Text('${t.manager} • OVR ${t.overall}'), trailing:const Icon(Icons.compare_rounded), onTap:(){recent.insert(0,t.name); _openTeamSheet(t);})),
        Wrap(spacing:8,runSpacing:8,children:[
          _goChip('Comparer',Icons.compare_arrows_rounded,1),_goChip('Team vs Team',Icons.shield_rounded,10),_goChip('Tactical Lab',Icons.sports_soccer_rounded,18),_goChip('Formation Counter',Icons.account_tree_rounded,12),_goChip('Knowledge',Icons.school_rounded,14),
        ]),
      ])),
      UxTabSection(tabs:const ['Dashboard','Workspaces','Workflow Coach','Favoris','Historique'], height:620, children:[
        _dash(), _workspaces(), _coachFlow(), _favorites(), _history(),
      ]),
    ]);
  }
  Widget _goChip(String label, IconData icon, int i)=>ActionChip(avatar:Icon(icon,size:18), label:Text(label), onPressed:()=>widget.onGo(i));
  Widget _dash()=>Column(children:[
    ProBox(title:'Résumé rapide', subtitle:'Accès aux tâches les plus fréquentes', icon:Icons.dashboard_rounded, child:Wrap(spacing:8,runSpacing:8,children:[
      _goChip('Scout joueurs',Icons.people_alt_rounded,3), _goChip('Analyse équipe',Icons.analytics_rounded,9), _goChip('Simuler match',Icons.auto_awesome_rounded,10), _goChip('Créer tactique',Icons.sports_soccer_rounded,18), _goChip('Backup DB',Icons.cloud_download_rounded,27),
    ])),
    ProBox(title:'Insights IA rapides', subtitle:'Cartes compactes pour décider vite', icon:Icons.psychology_rounded, child:Column(children:[
      _insight('⚠ Évite les duels physiques si ton ST perd force/agressivité.', 'Ouvre Team vs Team → Duels → À éviter.'),
      _insight('✓ Utilise Formation Counter avant de lancer le match.', 'Compare forme adverse + forces joueurs.'),
      _insight('⭐ Tactical Lab sert maintenant à transformer une analyse en situation terrain.', 'Choisis 2 joueurs + mode + scénario.'),
    ])),
  ]);
  Widget _workspaces()=>Column(children:[
    _workspace('Scout','Players • Teams • Managers • Knowledge',Icons.travel_explore_rounded,[('Base joueurs',3),('Teams',4),('Managers',11),('Knowledge',14)]),
    _workspace('Analyse','Comparateur • Team Analyzer • Matchups',Icons.analytics_rounded,[('Comparateur',1),('Team Analyzer',9),('Matchup Finder',16),('Guide modes',24)]),
    _workspace('Coach','Tactical Lab • Situations • Formations',Icons.sports_soccer_rounded,[('Tactical Lab',18),('Situations',13),('Formation Counter',12),('Tactic Board',26)]),
    _workspace('Database','CRUD • Transfert • Backup',Icons.storage_rounded,[('CRUD Players',5),('Transfert',7),('XI départ',8),('Export DB',27)]),
  ]);
  Widget _workspace(String title,String sub,IconData icon,List<(String,int)> links)=>ProBox(title:title,subtitle:sub,icon:icon,child:Wrap(spacing:8,runSpacing:8,children:links.map((e)=>_goChip(e.$1,Icons.arrow_forward_rounded,e.$2)).toList()));
  Widget _coachFlow()=>ProBox(title:'Workflow Coach lié', subtitle:'Recherche → Analyse → Simulation → Tactical Lab → Rapport', icon:Icons.route_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _flowStep('1. Scout','Trouver joueur/équipe/formation',3),
    _flowStep('2. Comparer','Lire les duels et stats clés',1),
    _flowStep('3. Simuler','Team vs Team + IA Simulator',10),
    _flowStep('4. Préparer','Tactical Lab + situations coach',18),
    _flowStep('5. Sauvegarder','Backup DB / historique',27),
  ]));
  Widget _flowStep(String a,String b,int i)=>ListTile(leading:const Icon(Icons.check_circle_rounded,color:AppTheme.green),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(b),trailing:const Icon(Icons.arrow_forward_ios_rounded,size:16),onTap:()=>widget.onGo(i));
  Widget _favorites()=>ProBox(title:'Favoris intelligents',subtitle:'Joueurs, équipes, formations, simulations et comparaisons',icon:Icons.star_rounded,child:Wrap(spacing:8,runSpacing:8,children:favs.map((x)=>ActionChip(avatar:const Icon(Icons.star_rounded,size:18),label:Text(x),onPressed:()=>_openSmartFavorite(x))).toList()));
  Widget _history()=>ProBox(title:'Historique de travail',subtitle:'Reprendre sans rechercher',icon:Icons.history_rounded,child:Column(children:recent.take(10).map((x)=>ListTile(leading:const Icon(Icons.history_rounded),title:Text(x,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('Reprendre ce workflow'),onTap:()=>showUxDetailModal(context,x,[ProBox(title:'Reprise rapide',subtitle:'Workflow sauvegardé localement',icon:Icons.restore_rounded,child:const Text('Ouvre le module lié puis continue ton analyse sans repartir de zéro.'))]))).toList()));
  Widget _insight(String a,String b)=>ListTile(leading:const Icon(Icons.bolt_rounded,color:AppTheme.orange),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(b));
  void _openSmartFavorite(String x)=>showUxDetailModal(context,x,[ProBox(title:'Actions disponibles',subtitle:'Favori intelligent',icon:Icons.bolt_rounded,child:Wrap(spacing:8,runSpacing:8,children:[_goChip('Comparer',Icons.compare_arrows_rounded,1),_goChip('Simuler',Icons.auto_awesome_rounded,10),_goChip('Tactical Lab',Icons.sports_soccer_rounded,18),_goChip('Exporter',Icons.import_export_rounded,27)]))]);
  void _openTeamSheet(TeamInfo t)=>showUxDetailModal(context,t.name,[ProBox(title:'Profil équipe',subtitle:t.manager,icon:Icons.shield_rounded,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('OVR ${t.overall} • ATT ${t.attack} • MID ${t.midfield} • DEF ${t.defense}',style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:[...t.strongTraits.map((x)=>Chip(label:Text('Fort: $x'))),...t.weakTraits.map((x)=>Chip(label:Text('Faible: $x')))]),]))]);
}

class V42TacticalLabFullPage extends StatefulWidget {
  final Player initialA, initialB; final Mode initialMode; final List<Player> players;
  const V42TacticalLabFullPage({super.key, required this.initialA, required this.initialB, required this.initialMode, required this.players});
  @override State<V42TacticalLabFullPage> createState()=>_V42TacticalLabFullPageState();
}
class _V42TacticalLabFullPageState extends State<V42TacticalLabFullPage> {
  late Player a,b; late Mode mode; final selected=<String>{}; double speed=1; int frame=1;
  final scenarios=['1v1 couloir','Cutback','Bloc bas','Pressing haut','Transition rapide','Centre second poteau','Pivot dos au but','Sortie sous pressing'];
  String scenario='1v1 couloir';
  @override void initState(){super.initState(); a=widget.initialA; b=widget.initialB; mode=widget.initialMode; selected.add(a.id); selected.add(b.id);}
  @override Widget build(BuildContext context){
    final sa=score(a,mode), sb=score(b,mode); final win=sa.total>=sb.total?a:b;
    return ListView(padding:const EdgeInsets.all(14),children:[
      Header('Tactical Lab 2.0', 'Éditeur situation • joueurs concernés • timeline • simulation IA'),
      UxTabSection(tabs:const ['Setup','Terrain','Timeline','Duels','Conseils','Bibliothèque','Export'],height:650,children:[
        _setup(), _pitch(sa,sb), _timeline(), ProDuelBreakdown(a:a,b:b,mode:mode), _advice(win), _library(), _exports(),
      ]),
    ]);
  }
  Widget _setup()=>Column(children:[
    PlayerPicker(title:'Joueur offensif / porteur',players:widget.players,value:a,onChanged:(p)=>setState((){a=p;selected.add(p.id);})),
    PlayerPicker(title:'Joueur défensif / opposant',players:widget.players,value:b,onChanged:(p)=>setState((){b=p;selected.add(p.id);})),
    ModePicker(mode:mode,onChanged:(m)=>setState(()=>mode=m)),
    ProBox(title:'Joueurs concernés',subtitle:'Multi-sélection pour préparer une animation',icon:Icons.group_rounded,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Wrap(spacing:8,runSpacing:8,children:widget.players.take(18).map((p)=>FilterChip(label:Text('${p.pos} ${p.name}',overflow:TextOverflow.ellipsis),selected:selected.contains(p.id),onSelected:(v)=>setState(()=>v?selected.add(p.id):selected.remove(p.id)))).toList()),
      const SizedBox(height:8),Text('${selected.length} joueurs sélectionnés',style:const TextStyle(fontWeight:FontWeight.w900,color:AppTheme.green)),
    ])),
  ]);
  Widget _pitch(DuelScore sa,DuelScore sb)=>Column(children:[
    ProBox(title:'Terrain interactif compact',subtitle:'Clique les zones/cartes pour voir le détail',icon:Icons.sports_soccer_rounded,child:Column(children:[
      AspectRatio(aspectRatio:1.35,child:CustomPaint(painter:PitchPainter(a.name,b.name,sa.total>=sb.total,mode.key))),
      const SizedBox(height:10), ScoreSummary(a:a,b:b,sa:sa,sb:sb),
      Wrap(spacing:8,runSpacing:8,children:[
        ActionChip(label:const Text('Zone forte'),avatar:const Icon(Icons.check_circle_rounded),onPressed:()=>_modal('Zone forte','Crée le duel dans la zone où ton joueur gagne vitesse/dribble/physique selon le mode.')),
        ActionChip(label:const Text('Zone à éviter'),avatar:const Icon(Icons.warning_amber_rounded),onPressed:()=>_modal('Zone à éviter','Évite la zone où le défenseur gagne tacle, interception ou physique.')),
        ActionChip(label:const Text('Passe alternative'),avatar:const Icon(Icons.route_rounded),onPressed:()=>_modal('Passe alternative','Si le duel est négatif, joue appui-remise, renversement ou passe dans le dos.')),
      ]),
    ])),
  ]);
  Widget _timeline()=>ProBox(title:'Timeline animation',subtitle:'Image par image : départ, appel, passe, duel, finition',icon:Icons.timeline_rounded,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Slider(value:frame.toDouble(),min:1,max:5,divisions:4,label:'Frame $frame',onChanged:(v)=>setState(()=>frame=v.round())),
    Slider(value:speed,min:.5,max:2,divisions:3,label:'Vitesse ${speed.toStringAsFixed(1)}x',onChanged:(v)=>setState(()=>speed=v)),
    Wrap(spacing:8,runSpacing:8,children:['Départ','Appel','Passe','Duel','Finition'].asMap().entries.map((e)=>ActionChip(label:Text('${e.key+1}. ${e.value}'),onPressed:()=>_modal(e.value,_timelineText(e.key+1)))).toList()),
  ]));
  String _timelineText(int f)=>['Positionne les joueurs et fixe la zone de départ.','Crée l’appel selon accélération et attacking positioning.','Choisis passe courte, longue, centre ou cutback selon stats.','Compare le vrai duel : mode + stats pondérées.','Décision finale : tir, passe, protection ou temporisation.'][f-1];
  Widget _advice(Player win)=>Column(children:[
    ProBox(title:'Lecture coach',subtitle:'Pourquoi le scénario fonctionne',icon:Icons.psychology_rounded,child:Text('${win.name} est favori dans ${mode.label}. Le résultat dépend surtout de ${mode.w.keys.map(labelStat).take(4).join(', ')}. Utilise ce duel seulement si tu peux l’isoler sans couverture adverse.',style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),
    ProBox(title:'À éviter',subtitle:'Erreurs fréquentes FC24',icon:Icons.warning_amber_rounded,child:Column(children:[
      _avoidTile('Forcer le duel négatif','Si ${b.name} gagne tacle/physique, cherche un soutien.'),
      _avoidTile('Dribbler sans angle','Un bon défenseur gagne si tu pars droit sur lui.'),
      _avoidTile('Presser seul','Le pressing sans second joueur ouvre une passe facile.'),
    ])),
  ]);
  Widget _avoidTile(String t,String s)=>ListTile(leading:const Icon(Icons.close_rounded,color:AppTheme.danger),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(s),onTap:()=>_modal(t,s));
  Widget _library()=>ProBox(title:'Bibliothèque tactique',subtitle:'Templates prêts à recharger',icon:Icons.folder_special_rounded,child:Column(children:scenarios.map((x)=>ListTile(leading:Icon(x==scenario?Icons.radio_button_checked:Icons.radio_button_off,color:AppTheme.green),title:Text(x,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(_scenarioHint(x)),onTap:()=>setState(()=>scenario=x))).toList()));
  String _scenarioHint(String x){
    if(x.contains('Cutback')) return 'Ailier/latéral → passe retrait → finition sous pression.';
    if(x.contains('Bloc')) return 'Patience, attirer, troisième homme, frappe ou cutback.';
    if(x.contains('Pressing')) return 'Déclenchement, couverture ligne de passe, récupération.';
    if(x.contains('Transition')) return 'Premier contrôle vers l’avant, passe rapide, course profondeur.';
    if(x.contains('Centre')) return 'Largeur, centre, duel aérien, deuxième ballon.';
    if(x.contains('Pivot')) return 'Protection, remise, entrée du milieu.';
    return 'Isolation, 1v1, changement de rythme.';
  }
  Widget _exports()=>ProBox(title:'Export & rapport',subtitle:'Préparer une fiche coach partageable',icon:Icons.ios_share_rounded,child:Wrap(spacing:8,runSpacing:8,children:[
    ActionChip(label:const Text('Rapport texte'),avatar:const Icon(Icons.article_rounded),onPressed:()=>_modal('Rapport coach','${scenario} : ${a.name} vs ${b.name}, mode ${mode.label}. Gagnant probable selon score IA et stats clés.')),
    ActionChip(label:const Text('Sauvegarder template'),avatar:const Icon(Icons.save_rounded),onPressed:()=>_modal('Template sauvegardé','Structure prête pour rechargement dans Tactical Lab.')),
    ActionChip(label:const Text('Export GIF/vidéo'),avatar:const Icon(Icons.movie_creation_rounded),onPressed:()=>_modal('Export GIF/vidéo','Prévu comme sortie de workflow : timeline + terrain + consignes.')),
  ]));
  void _modal(String title,String body)=>showUxDetailModal(context,title,[ProBox(title:title,subtitle:scenario,icon:Icons.info_rounded,child:Text(body,style:const TextStyle(height:1.45,fontWeight:FontWeight.w700))),ProDuelBreakdown(a:a,b:b,mode:mode)]);
}

class V42TeamVsTeamProPage extends StatefulWidget {
  final List<TeamInfo> teams; final List<Player> players;
  const V42TeamVsTeamProPage({super.key, required this.teams, required this.players});
  @override State<V42TeamVsTeamProPage> createState()=>_V42TeamVsTeamProPageState();
}
class _V42TeamVsTeamProPageState extends State<V42TeamVsTeamProPage>{
  TeamInfo? ta,tb; String q='';
  @override void initState(){super.initState(); if(widget.teams.isNotEmpty){ta=widget.teams.first; tb=widget.teams.length>1?widget.teams[1]:widget.teams.first;}}
  List<Player> _teamPlayers(TeamInfo? t){ if(t==null)return []; final byId=widget.players.where((p)=>p.teamId==t.id && p.gender==0).toList(); final list=byId.isNotEmpty?byId:widget.players.where((p)=>p.team.toLowerCase()==t.name.toLowerCase() && p.gender==0).toList(); list.sort((a,b)=>b.ovr.compareTo(a.ovr)); return list; }
  @override Widget build(BuildContext context){
    final aPlayers=_teamPlayers(ta), bPlayers=_teamPlayers(tb);
    return ListView(padding:const EdgeInsets.all(14),children:[
      Header('Team vs Team 2.0', 'Onglets courts • duels intelligents • terrain • heatmaps • conseils'),
      Row(children:[Expanded(child:_teamDrop('Équipe A',ta,(v)=>setState(()=>ta=v))),const SizedBox(width:8),Expanded(child:_teamDrop('Équipe B',tb,(v)=>setState(()=>tb=v)))]),
      const SizedBox(height:10),
      TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Filtrer joueur, poste, duel, conseil...'),onChanged:(v)=>setState(()=>q=v.toLowerCase())),
      const SizedBox(height:12),
      UxTabSection(tabs:const ['Overview','Terrain','Duels','Attack','Defense','Midfield','Pressing','Counters','Advice','Bench'],height:680,children:[
        _overview(aPlayers,bPlayers), _terrain(aPlayers,bPlayers), _duels(aPlayers,bPlayers), _phase('Attack',aPlayers,bPlayers), _phase('Defense',aPlayers,bPlayers), _phase('Midfield',aPlayers,bPlayers), _phase('Pressing',aPlayers,bPlayers), _counters(), _advice(aPlayers,bPlayers), _bench(aPlayers,bPlayers),
      ]),
    ]);
  }
  Widget _teamDrop(String label,TeamInfo? val,ValueChanged<TeamInfo?> onChanged)=>DropdownButtonFormField<TeamInfo>(value:val,isExpanded:true,decoration:InputDecoration(labelText:label),items:widget.teams.map((t)=>DropdownMenuItem(value:t,child:Text(t.name,overflow:TextOverflow.ellipsis))).toList(),onChanged:onChanged);
  Widget _overview(List<Player>a,List<Player>b)=>Column(children:[
    ProBox(title:'Score lignes',subtitle:'Vue rapide avant détail',icon:Icons.scoreboard_rounded,child:Column(children:[
      Row(children:[Expanded(child:MiniScore(ta?.name??'A',ta?.overall??0,'OVR')),const SizedBox(width:8),Expanded(child:MiniScore(tb?.name??'B',tb?.overall??0,'OVR'))]),
      const SizedBox(height:8),Row(children:[Expanded(child:MiniScore('Attack',ta?.attack??0,ta?.name??'')),const SizedBox(width:8),Expanded(child:MiniScore('Defense',tb?.defense??0,tb?.name??''))]),
      const SizedBox(height:8),Row(children:[Expanded(child:MiniScore('Midfield',ta?.midfield??0,ta?.name??'')),const SizedBox(width:8),Expanded(child:MiniScore('Midfield',tb?.midfield??0,tb?.name??''))]),
    ])),
    _traitBox('Traits équipe A',ta), _traitBox('Traits équipe B',tb),
  ]);
  Widget _traitBox(String title,TeamInfo? t)=>ProBox(title:title,subtitle:t?.manager??'Manager',icon:Icons.psychology_rounded,child:Wrap(spacing:8,runSpacing:8,children:[...(t?.strongTraits??[]).map((x)=>Chip(label:Text('Fort $x'))),...(t?.weakTraits??[]).map((x)=>Chip(label:Text('Faible $x'))),...(t?.equalTraits??[]).map((x)=>Chip(label:Text('Égal $x')))]));
  Widget _terrain(List<Player>a,List<Player>b)=>ProBox(title:'Terrain + sélection duel',subtitle:'Clique un joueur pour détail / comparaison rapide',icon:Icons.map_rounded,child:Column(children:[
    AspectRatio(aspectRatio:1.35,child:CustomPaint(painter:V42TeamPitchPainter(a.take(11).toList(),b.take(11).toList()))),
    const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:[...a.take(11).map((p)=>ActionChip(label:Text('${p.pos} ${p.name}'),onPressed:()=>showPlayerDetails(context,p))),...b.take(11).map((p)=>ActionChip(label:Text('${p.pos} ${p.name}'),onPressed:()=>showPlayerDetails(context,p)))]),
  ]));
  Widget _duels(List<Player>a,List<Player>b){ final rows=_smartPairs(a,b); return Column(children:[
    ProBox(title:'Duels qui se font vraiment face',subtitle:'Pas seulement poste vs poste : couloir, axe, ligne et mode adapté',icon:Icons.hub_rounded,child:Column(children:rows.take(12).map((e)=>_duelTile(e.$1,e.$2,e.$3)).toList())),
  ]);}
  List<(Player,Player,Mode)> _smartPairs(List<Player>a,List<Player>b){
    final out=<(Player,Player,Mode)>[]; if(a.isEmpty||b.isEmpty)return out;
    Player best(List<Player> ps,bool Function(Player)p)=>ps.where(p).fold<Player?>(null,(m,x)=>m==null||x.ovr>m.ovr?x:m)??ps.first;
    final la=best(a,(p)=>p.pos.contains('LW')||p.pos.contains('LM')||p.pos.contains('RW')||p.pos.contains('RM'));
    final rb=best(b,(p)=>p.pos.contains('RB')||p.pos.contains('LB')||p.pos.contains('RWB')||p.pos.contains('LWB'));
    final st=best(a,(p)=>p.pos.contains('ST')||p.pos.contains('CF'));
    final cb=best(b,(p)=>p.pos.contains('CB'));
    final cam=best(a,(p)=>p.pos.contains('CAM')||p.pos.contains('CM'));
    final cdm=best(b,(p)=>p.pos.contains('CDM')||p.pos.contains('CM'));
    out.add((la,rb,modes.firstWhere((m)=>m.key=='dribble_wing'))); out.add((st,cb,modes.firstWhere((m)=>m.key=='through_ball'))); out.add((cam,cdm,modes.firstWhere((m)=>m.key=='pass_break')));
    for(final p in a.take(6)){ final op=b.reduce((x,y)=>(x.ovr-p.ovr).abs()<(y.ovr-p.ovr).abs()?x:y); out.add((p,op,_modeForPositions(p,op))); }
    return out;
  }
  Mode _modeForPositions(Player p,Player o){ if(p.pos.contains('W')||o.pos.contains('B'))return modes.firstWhere((m)=>m.key=='dribble_wing'); if(p.pos.contains('ST')&&o.pos.contains('CB'))return modes.firstWhere((m)=>m.key=='finish_pressure'); if(p.pos.contains('CM')||p.pos.contains('CAM'))return modes.firstWhere((m)=>m.key=='pass_break'); return modes.firstWhere((m)=>m.key=='physical'); }
  Widget _duelTile(Player p,Player o,Mode m){ final sp=score(p,m), so=score(o,m); return ListTile(leading:PlayerAvatar(p:p,size:38),title:Text('${p.name} vs ${o.name}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${m.label} • ${sp.total}-${so.total}'),trailing:Icon(sp.total>=so.total?Icons.trending_up_rounded:Icons.warning_amber_rounded,color:sp.total>=so.total?AppTheme.green:AppTheme.orange),onTap:()=>showUxDetailModal(context,'${p.name} vs ${o.name}',[ScoreSummary(a:p,b:o,sa:sp,sb:so),ProDuelBreakdown(a:p,b:o,mode:m),ProBox(title:'À éviter',subtitle:'Plan joueur par joueur',icon:Icons.warning_amber_rounded,child:Text(sp.total>=so.total?'Tu peux créer ce duel, mais évite de répéter le même angle.':'Évite ce duel direct. Cherche soutien, renversement ou autre mode de duel.',style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))])); }
  Widget _phase(String phase,List<Player>a,List<Player>b)=>ProBox(title:phase,subtitle:'Comparaisons off/def et conseils courts',icon:Icons.analytics_rounded,child:Column(children:_smartPairs(a,b).take(8).map((e){final m=phase=='Defense'?modes.firstWhere((x)=>x.key=='defense'):e.$3;return _duelTile(e.$1,e.$2,m);}).toList()));
  Widget _counters()=>ProBox(title:'Counters recommandés',subtitle:'Selon formation, traits et joueurs clés',icon:Icons.account_tree_rounded,child:Column(children:[_counterTile('Si bloc bas','Passe verticale + troisième homme + cutback'),_counterTile('Si pressing haut','Une-deux rapide + ballon dans le dos'),_counterTile('Si latéraux montent','Attaque le couloir faible derrière le latéral'),_counterTile('Si 5 défenseurs','Renversement + surcharge côté opposé')]));
  Widget _counterTile(String t,String s)=>ListTile(leading:const Icon(Icons.tips_and_updates_rounded,color:AppTheme.green),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(s),onTap:()=>showUxDetailModal(context,t,[ProBox(title:t,subtitle:'Counter detail',icon:Icons.account_tree_rounded,child:Text(s,style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))]));
  Widget _advice(List<Player>a,List<Player>b)=>ProBox(title:'Advice coach',subtitle:'Cartes intelligentes compactes',icon:Icons.psychology_rounded,child:Column(children:[
    _adviceTile('À éviter','Ne force pas les duels où ton joueur perd physique/tacle/def awareness.'),
    _adviceTile('À chercher','Crée les duels où ton joueur gagne accélération, agilité, composure ou vision.'),
    _adviceTile('Changement match','Si tu perds, augmente risques côté fort ; si tu gagnes, sécurise axe + transitions.'),
  ]));
  Widget _adviceTile(String t,String s)=>ListTile(leading:const Icon(Icons.bolt_rounded,color:AppTheme.orange),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(s),onTap:()=>showUxDetailModal(context,t,[ProBox(title:t,subtitle:'Conseil IA',icon:Icons.psychology_rounded,child:Text(s,style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))]));
  Widget _bench(List<Player>a,List<Player>b)=>ProBox(title:'Bench impact',subtitle:'Remplaçants utiles selon scénario',icon:Icons.chair_rounded,child:Column(children:[
    ...a.skip(11).take(8).map((p)=>ListTile(leading:PlayerAvatar(p:p,size:36),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('Entrée possible : ${p.pos} • OVR ${p.ovr}'),onTap:()=>showPlayerDetails(context,p))),
    const Divider(),
    ...b.skip(11).take(8).map((p)=>ListTile(leading:PlayerAvatar(p:p,size:36),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('Adversaire banc : ${p.pos} • OVR ${p.ovr}'),onTap:()=>showPlayerDetails(context,p))),
  ]));
}

class V42TeamPitchPainter extends CustomPainter{
  final List<Player> a,b; V42TeamPitchPainter(this.a,this.b);
  @override void paint(Canvas c,Size s){
    final bg=Paint()..shader=const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF08743E),Color(0xFF04111F)]).createShader(Offset.zero&s);
    final line=Paint()..color=Colors.white.withOpacity(.55)..style=PaintingStyle.stroke..strokeWidth=2;
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero&s,const Radius.circular(28)),bg); c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18,18,s.width-36,s.height-36),const Radius.circular(18)),line); c.drawLine(Offset(s.width/2,18),Offset(s.width/2,s.height-18),line); c.drawCircle(Offset(s.width/2,s.height/2),44,line);
    for(int i=0;i<a.length;i++){_p(c,Offset(s.width*(.18+(.18*(i%4))),s.height*(.18+(.18*(i~/4)))),a[i].pos,const Color(0xFF24C6DC));}
    for(int i=0;i<b.length;i++){_p(c,Offset(s.width*(.82-(.18*(i%4))),s.height*(.18+(.18*(i~/4)))),b[i].pos,const Color(0xFFFF5573));}
  }
  void _p(Canvas c,Offset o,String t,Color col){c.drawCircle(o,18,Paint()..color=col); final tp=TextPainter(text:TextSpan(text:t.length>3?t.substring(0,3):t,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout(); tp.paint(c,o-Offset(tp.width/2,tp.height/2));}
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>true;
}


// ======================= V45 FINAL VIP PREMIUM POLISH =======================
// Goal: final pro UX layer with linked workflow, heatmaps, reports, smart history/favorites,
// contextual quick actions and compact information discovery.
class V45FinalVipPolishPage extends StatefulWidget {
  final List<Player> players;
  final List<TeamInfo> teams;
  final List<TacticalIdea> ideas;
  final List<Map<String,dynamic>> history;
  final ValueChanged<int> onGo;
  final ValueChanged<Player> onOpenPlayer;
  const V45FinalVipPolishPage({super.key, required this.players, required this.teams, required this.ideas, required this.history, required this.onGo, required this.onOpenPlayer});
  @override State<V45FinalVipPolishPage> createState()=>_V45FinalVipPolishPageState();
}

class _V45FinalVipPolishPageState extends State<V45FinalVipPolishPage> {
  final Set<String> favPlayers = {};
  final Set<String> favTeams = {};
  final List<String> sessionLog = [];
  String q = '';

  List<Player> get filteredPlayers {
    final term=q.toLowerCase().trim();
    final src=widget.players.where((p)=>p.gender==0).toList();
    if(term.isEmpty) return src.take(12).toList();
    return src.where((p)=>('${p.name} ${p.team} ${p.pos} ${p.playstyles.join(' ')}').toLowerCase().contains(term)).take(20).toList();
  }
  List<TeamInfo> get filteredTeams {
    final term=q.toLowerCase().trim();
    if(term.isEmpty) return widget.teams.take(8).toList();
    return widget.teams.where((t)=>('${t.name} ${t.manager} ${t.strongTraits.join(' ')} ${t.weakTraits.join(' ')}').toLowerCase().contains(term)).take(12).toList();
  }

  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Header('V45 Final VIP Premium', 'Workflow final • recherche rapide • heatmaps • rapports • favoris • performance'),
    QuickSearchHeader(hint:'Chercher joueur, team, manager, formation, playstyle...', onChanged:(v)=>setState(()=>q=v), onFilter:()=>_openCommandCenter()),
    const SizedBox(height:12),
    UxTabSection(
      height: 660,
      tabs: const ['Command', 'Workflow', 'Heatmaps', 'Rapports', 'Favoris', 'Performance'],
      children: [_commandTab(), _workflowTab(), _heatmapsTab(), _reportsTab(), _favoritesTab(), _performanceTab()],
    ),
  ]);

  Widget _commandTab()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    ProBox(title:'Command Center VIP', subtitle:'Un seul endroit pour trouver et lancer l’action', icon:Icons.manage_search_rounded, child:Column(children:[
      ...filteredPlayers.map((p)=>_playerCommandTile(p)),
      if(filteredTeams.isNotEmpty) const Divider(),
      ...filteredTeams.map((t)=>_teamCommandTile(t)),
      const SizedBox(height:10),
      Wrap(spacing:8,runSpacing:8,children:[
        _goChip('Comparateur',Icons.compare_arrows_rounded,1),_goChip('Team vs Team',Icons.compare_rounded,10),_goChip('Tactical Lab',Icons.sports_soccer_rounded,18),_goChip('Export DB',Icons.import_export_rounded,23),_goChip('Settings',Icons.settings_rounded,27),
      ]),
    ])),
    _insight('Astuce VIP', 'Tape un nom puis lance directement comparer, simuler, exporter ou ouvrir le hub sans repasser par le menu.'),
  ]);

  Widget _workflowTab()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    ProBox(title:'Workflow Coach lié', subtitle:'Scouting → Analyse → Simulation → Lab → Rapport', icon:Icons.route_rounded, child:Column(children:[
      _flowTile('1. Scout', 'Trouver joueur/team/manager', Icons.manage_search_rounded, 28),
      _flowTile('2. Comparer', 'Duel détaillé et stats clés', Icons.compare_arrows_rounded, 1),
      _flowTile('3. Simuler', 'Team vs Team + IA Simulator', Icons.auto_awesome_rounded, 10),
      _flowTile('4. Préparer', 'Tactical Lab + Formation Counter', Icons.sports_soccer_rounded, 18),
      _flowTile('5. Exporter', 'Rapport coach + backup DB', Icons.picture_as_pdf_rounded, 23),
    ])),
    ProBox(title:'Actions rapides contextuelles', subtitle:'Moins de navigation, plus d’action', icon:Icons.bolt_rounded, child:Wrap(spacing:8,runSpacing:8,children:[
      ActionChip(label:const Text('Créer session'), avatar:const Icon(Icons.add_rounded), onPressed:()=>_addSession('Session coach créée')),
      ActionChip(label:const Text('Sauvegarder analyse'), avatar:const Icon(Icons.save_rounded), onPressed:()=>_addSession('Analyse sauvegardée')),
      ActionChip(label:const Text('Reprendre dernier flow'), avatar:const Icon(Icons.restore_rounded), onPressed:()=>_modal('Dernier flow','Reprend la dernière recherche, comparaison ou simulation depuis l’historique.')),
    ])),
    ...sessionLog.take(6).map((x)=>ListTile(leading:const Icon(Icons.check_circle_rounded,color:AppTheme.green),title:Text(x,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:const Text('Session locale'))),
  ]);

  Widget _heatmapsTab()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    ProBox(title:'Heatmaps VIP', subtitle:'Lecture visuelle des zones fortes/faibles', icon:Icons.local_fire_department_rounded, child:Column(children:[
      _miniPitch('Zones fortes équipe', widget.teams.isNotEmpty ? widget.teams.first : null, true),
      const SizedBox(height:12),
      _miniPitch('Zones faibles adverses', widget.teams.length>1 ? widget.teams[1] : null, false),
    ])),
    ProBox(title:'Interprétation IA', subtitle:'Comment lire la carte', icon:Icons.psychology_rounded, child:const Text('Les zones vertes indiquent où créer le duel. Les zones orange/rouge signalent les couloirs à éviter ou à couvrir. Utilise ces cartes dans Team vs Team et Tactical Lab pour choisir les bons joueurs.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
  ]);

  Widget _reportsTab()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    ProBox(title:'Rapports coach', subtitle:'Export lisible avant update, match ou session', icon:Icons.picture_as_pdf_rounded, child:Column(children:[
      _reportTile('Rapport Team vs Team', 'Résumé terrain, duels, zones, conseils'),
      _reportTile('Rapport joueur', 'Stats, playstyles, traits, counters, similaires'),
      _reportTile('Rapport tactique', 'Situation coach, animation, timeline, plan'),
      _reportTile('Backup DB actuel', 'Joueurs, équipes, tactiques, historique'),
    ])),
    ProBox(title:'Format recommandé', subtitle:'VIP final', icon:Icons.description_rounded, child:const Text('Le ZIP garde une logique sans dépendance lourde: export JSON/texte prêt à copier. Pour un vrai PDF natif, ajoute plus tard une dépendance Flutter PDF dans pubspec.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700))),
  ]);

  Widget _favoritesTab()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    ProBox(title:'Favoris intelligents', subtitle:'Joueurs, teams, simulations et tactiques', icon:Icons.star_rounded, child:Column(children:[
      if(favPlayers.isEmpty && favTeams.isEmpty) const ListTile(leading:Icon(Icons.info_outline), title:Text('Aucun favori encore'), subtitle:Text('Ajoute depuis Command Center ou détails joueur/team.')),
      ...favPlayers.map((id){ final p=widget.players.firstWhere((x)=>x.id==id, orElse:()=>widget.players.first); return _playerCommandTile(p); }),
      ...favTeams.map((id){ final t=widget.teams.firstWhere((x)=>x.id==id, orElse:()=>widget.teams.first); return _teamCommandTile(t); }),
    ])),
    ProBox(title:'Historique avancé', subtitle:'Reprendre les dernières actions', icon:Icons.history_rounded, child:Column(children:[
      ...widget.history.take(8).map((h)=>ListTile(leading:const Icon(Icons.history_rounded),title:Text('${h['type'] ?? 'Historique'}',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(h.toString(), maxLines:2, overflow:TextOverflow.ellipsis),onTap:()=>_modal('Historique', h.toString()))),
      ...sessionLog.take(8).map((x)=>ListTile(leading:const Icon(Icons.restore_rounded),title:Text(x,style:const TextStyle(fontWeight:FontWeight.w800))))
    ])),
  ]);

  Widget _performanceTab()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    ProBox(title:'Performance DB', subtitle:'Lecture rapide et moins de scroll', icon:Icons.speed_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _metric('Joueurs chargés', widget.players.length),
      _metric('Équipes chargées', widget.teams.length),
      _metric('Tactiques sauvegardées', widget.ideas.length),
      _metric('Historique', widget.history.length),
      const SizedBox(height:8),
      const Text('Optimisations UX: filtres cachés, résultats limités, détails en bottom sheet, onglets, actions rapides.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700)),
    ])),
    ProBox(title:'Checklist final VIP', subtitle:'Ce qui est couvert', icon:Icons.verified_rounded, child:Wrap(spacing:8,runSpacing:8,children:const [
      Chip(label:Text('Command Center')), Chip(label:Text('Workflow lié')), Chip(label:Text('Heatmaps')), Chip(label:Text('Rapports')), Chip(label:Text('Favoris')), Chip(label:Text('Historique')), Chip(label:Text('Quick Actions')), Chip(label:Text('Backup DB')),
    ])),
  ]);

  Widget _playerCommandTile(Player p)=>ListTile(
    leading: PlayerAvatar(p:p,size:42),
    title: Text(p.name, style:const TextStyle(fontWeight:FontWeight.w900)),
    subtitle: Text('${p.team} • ${p.pos} • OVR ${p.ovr} • ${p.playstyles.take(2).join(', ')}'),
    trailing: Wrap(spacing:4,children:[
      IconButton(icon:Icon(favPlayers.contains(p.id)?Icons.star_rounded:Icons.star_border_rounded,color:AppTheme.orange),onPressed:()=>setState(()=>favPlayers.contains(p.id)?favPlayers.remove(p.id):favPlayers.add(p.id))),
      IconButton(icon:const Icon(Icons.open_in_new_rounded),onPressed:()=>widget.onOpenPlayer(p)),
    ]),
    onTap:()=>showUxDetailModal(context,p.name,[_playerActionBox(p),_playerVipBox(p)]),
  );

  Widget _teamCommandTile(TeamInfo t)=>ListTile(
    leading:const CircleAvatar(backgroundColor:AppTheme.surface, child:Icon(Icons.shield_rounded,color:AppTheme.green)),
    title:Text(t.name,style:const TextStyle(fontWeight:FontWeight.w900)),
    subtitle:Text('${t.manager} • OVR ${t.overall} • ATT ${t.attack} MID ${t.midfield} DEF ${t.defense}'),
    trailing:IconButton(icon:Icon(favTeams.contains(t.id)?Icons.star_rounded:Icons.star_border_rounded,color:AppTheme.orange),onPressed:()=>setState(()=>favTeams.contains(t.id)?favTeams.remove(t.id):favTeams.add(t.id))),
    onTap:()=>showUxDetailModal(context,t.name,[_teamVipBox(t)]),
  );

  Widget _playerActionBox(Player p)=>ProBox(title:'Actions joueur', subtitle:'Hub → comparer → lab → rapport', icon:Icons.bolt_rounded, child:Wrap(spacing:8,runSpacing:8,children:[
    ActionChip(label:const Text('Ouvrir hub'),avatar:const Icon(Icons.person_rounded),onPressed:()=>widget.onOpenPlayer(p)),
    ActionChip(label:const Text('Comparer'),avatar:const Icon(Icons.compare_arrows_rounded),onPressed:()=>widget.onGo(1)),
    ActionChip(label:const Text('Team vs Team'),avatar:const Icon(Icons.compare_rounded),onPressed:()=>widget.onGo(10)),
    ActionChip(label:const Text('Tactical Lab'),avatar:const Icon(Icons.sports_soccer_rounded),onPressed:()=>widget.onGo(18)),
    ActionChip(label:const Text('Rapport'),avatar:const Icon(Icons.description_rounded),onPressed:()=>_modal('Rapport ${p.name}', _playerReport(p))),
  ]));

  Widget _playerVipBox(Player p)=>ProBox(title:'Analyse VIP rapide', subtitle:'Résumé utile sans scroller', icon:Icons.psychology_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Profil: ${p.pos} • ${p.body} • ${p.accel} • pied ${p.foot}', style:const TextStyle(fontWeight:FontWeight.w900)),
    const SizedBox(height:8),
    Wrap(spacing:8,runSpacing:8,children:p.playstyles.take(8).map((x)=>Chip(label:Text(x))).toList()),
    const SizedBox(height:8),
    ..._topStatsEntries(p, 6).map((e)=>StatBar(label:labelStat(e.key), value:e.value)),
    const SizedBox(height:8),
    const Text('Conseil: utilise ses meilleures stats pour créer un duel favorable et évite les modes où ses stats clés sont sous 75.', style:TextStyle(height:1.45,fontWeight:FontWeight.w700)),
  ]));

  Widget _teamVipBox(TeamInfo t)=>ProBox(title:'Team traits & tactics', subtitle:'Forces/faiblesses affichées partout', icon:Icons.analytics_rounded, child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Manager: ${t.manager}', style:const TextStyle(fontWeight:FontWeight.w900)),
    const SizedBox(height:8),
    Wrap(spacing:8,runSpacing:8,children:[
      ...t.strongTraits.map((x)=>Chip(label:Text('Fort: $x'))),
      ...t.equalTraits.map((x)=>Chip(label:Text('Égal: $x'))),
      ...t.weakTraits.map((x)=>Chip(label:Text('Faible: $x'))),
    ]),
    const SizedBox(height:8),
    Text('Plan: attaque la zone faible, protège la zone forte adverse, et compare les joueurs réellement proches sur le terrain.', style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)),
  ]));

  Widget _miniPitch(String title, TeamInfo? t, bool strong)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontWeight:FontWeight.w900)), const SizedBox(height:8),
    Container(height:180,decoration:BoxDecoration(color:AppTheme.pitch,borderRadius:BorderRadius.circular(22),border:Border.all(color:Colors.white24)),child:Stack(children:[
      Positioned.fill(child:CustomPaint(painter:VipPitchPainter(strong:strong))),
      Positioned(left:16,top:14,child:_zoneChip(strong?'Left build-up':'Zone à éviter')),
      Positioned(right:16,top:70,child:_zoneChip(strong?'Right overload':'Duel physique')),
      Positioned(left:120,bottom:18,child:_zoneChip(t?.name ?? 'Team')),
    ])),
  ]);

  Widget _zoneChip(String x)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.black.withOpacity(.42),borderRadius:BorderRadius.circular(999),border:Border.all(color:Colors.white24)),child:Text(x,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:11)));
  Widget _flowTile(String t,String s,IconData ic,int idx)=>ListTile(leading:Icon(ic,color:AppTheme.green),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(s),trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>widget.onGo(idx));
  Widget _goChip(String t,IconData ic,int idx)=>ActionChip(label:Text(t),avatar:Icon(ic),onPressed:()=>widget.onGo(idx));
  Widget _insight(String t,String s)=>ProBox(title:t,subtitle:'Insight IA',icon:Icons.lightbulb_rounded,child:Text(s,style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)));
  Widget _reportTile(String t,String s)=>ListTile(leading:const Icon(Icons.description_rounded,color:AppTheme.green),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(s),trailing:const Icon(Icons.download_rounded),onTap:()=>_modal(t,'$s\n\nExport prêt: copie ce rapport ou utilise Export / Import pour sauvegarder la DB.'));
  Widget _metric(String label,int value)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w800))),Text('$value',style:const TextStyle(fontWeight:FontWeight.w900,color:AppTheme.green))]));
  void _addSession(String x)=>setState(()=>sessionLog.insert(0,'$x • ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2,'0')}'));
  List<MapEntry<String,int>> _topStatsEntries(Player p,int n){ final items=p.s.entries.where((e)=>e.value>0).toList()..sort((a,b)=>b.value.compareTo(a.value)); return items.take(n).toList(); }
  void _openCommandCenter()=>showUxDetailModal(context,'Command Center VIP',[_commandTab()]);
  void _modal(String title,String body)=>showUxDetailModal(context,title,[ProBox(title:title,subtitle:'V45 VIP',icon:Icons.workspace_premium_rounded,child:Text(body,style:const TextStyle(height:1.45,fontWeight:FontWeight.w700)))]);
  String _playerReport(Player p){ final ts=_topStatsEntries(p,8).map((e)=>'${labelStat(e.key)} ${e.value}').join(' / '); return 'Rapport joueur: ${p.name}\nTeam: ${p.team}\nPoste: ${p.pos}\nOVR: ${p.ovr}\nPlayStyles: ${p.playstyles.join(', ')}\nTop stats: $ts'; }
}

class VipPitchPainter extends CustomPainter {
  final bool strong;
  VipPitchPainter({required this.strong});
  @override void paint(Canvas canvas, Size size){
    final line=Paint()..color=Colors.white.withOpacity(.35)..style=PaintingStyle.stroke..strokeWidth=1.2;
    canvas.drawRect(Rect.fromLTWH(10,10,size.width-20,size.height-20), line);
    canvas.drawLine(Offset(size.width/2,10),Offset(size.width/2,size.height-10),line);
    canvas.drawCircle(Offset(size.width/2,size.height/2),26,line);
    final p=Paint()..shader=RadialGradient(colors:[(strong?AppTheme.green:AppTheme.danger).withOpacity(.62), Colors.transparent]).createShader(Rect.fromCircle(center:Offset(strong?size.width*.25:size.width*.75,size.height*.45),radius:90));
    canvas.drawCircle(Offset(strong?size.width*.25:size.width*.75,size.height*.45),90,p);
    final p2=Paint()..shader=RadialGradient(colors:[AppTheme.orange.withOpacity(.48), Colors.transparent]).createShader(Rect.fromCircle(center:Offset(size.width*.55,size.height*.72),radius:70));
    canvas.drawCircle(Offset(size.width*.55,size.height*.72),70,p2);
  }
  @override bool shouldRepaint(covariant VipPitchPainter oldDelegate)=>oldDelegate.strong!=strong;
}
