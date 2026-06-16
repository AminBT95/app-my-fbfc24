import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  final String id, name, team, pos, pos2, body, accel, foot, attWr, defWr;
  final int ovr, pot, height, weight, skill, weakFoot;
  final List<String> playstyles;
  final Map<String, int> s;

  const Player({
    required this.id, required this.name, required this.team, required this.pos, required this.pos2,
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
  final all = p.playstyles.isEmpty ? ['Aucun PlayStyle'] : p.playstyles;
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
  Player? a,b;
  Mode mode = modes[3];

  @override void initState() {
    super.initState();
    customPlayers = [];
    customTeams = [];
    Future.delayed(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    try {
      final loaded = await GameDb.load();
      setState(() {
        db = loaded;
        customPlayers = List<Player>.from(loaded.players);
        customTeams = List<TeamInfo>.from(loaded.teams);
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
      ComparePage(players: customPlayers, a: a!, b: b!, mode: mode, onA:(p)=>setState(()=>a=p), onB:(p)=>setState(()=>b=p), onMode:(m)=>setState(()=>mode=m)),
      DetectorPage(players: customPlayers, ref: a!, mode: mode),
      DatabasePage(players: customPlayers),
      TeamsPage(teams: customTeams, players: customPlayers, onEditTeam: (t)=>showTeamEditor(context, t)),
      PlayerCrudPage(players: customPlayers, onSave: (p){
        setState(() {
          final i = customPlayers.indexWhere((x)=>x.id==p.id);
          if (i >= 0) customPlayers[i] = p; else customPlayers.insert(0,p);
          a ??= p;
        });
      }),
      TeamCrudPage(teams: customTeams, onSave: (t){
        setState(() {
          final i = customTeams.indexWhere((x)=>x.id==t.id);
          if (i >= 0) customTeams[i]=t; else customTeams.insert(0,t);
        });
      }),
      TacticalPage(a: a!, b: b!, mode: mode),
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
        selectedIndex: tab > 4 ? 4 : tab,
        onDestinationSelected: (i)=>setState(()=>tab=i),
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
      (7, Icons.sports_soccer_rounded, 'Tactical Lab'),
      (8, Icons.menu_book_rounded, 'Guide modes'),
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
  final ValueChanged<Player> onA,onB; final ValueChanged<Mode> onMode;
  const ComparePage({super.key, required this.players, required this.a, required this.b, required this.mode, required this.onA, required this.onB, required this.onMode});
  @override Widget build(BuildContext context) {
    final sa=score(a,mode), sb=score(b,mode), win=sa.total>=sb.total?a:b;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Comparateur', 'Gagnant prévu : ${win.name}'),
      PlayerPicker(title:'Joueur A', players:players, value:a, onChanged:onA),
      PlayerPicker(title:'Joueur B', players:players, value:b, onChanged:onB),
      ModePicker(mode: mode, onChanged: onMode),
      ScoreSummary(a:a,b:b,sa:sa,sb:sb),
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
      Text(value.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Text('${value.team} • ${value.pos}${value.pos2.isNotEmpty ? " / ${value.pos2}" : ""} • OVR ${value.ovr}'),
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
  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF06111F), builder: (_) {
    final stats = ['acc','sprint','str','agg','bal','agi','react','ball','drib','defaw','tackle','inter','finish','shot','comp','stam','jump','head','cross','shortp','longp','vision'];
    return DraggableScrollableSheet(initialChildSize: .88, maxChildSize: .95, minChildSize: .45, expand: false, builder: (_, controller) => ListView(controller: controller, padding: const EdgeInsets.all(16), children: [
      Text(p.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      Text('${p.team} • ${p.pos} • OVR ${p.ovr} • POT ${p.pot}'),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        Chip(label: Text('${p.height}cm')), Chip(label: Text('${p.weight}kg')), Chip(label: Text(p.body)), Chip(label: Text(p.accel)),
        Chip(label: Text('Foot ${p.foot}')), Chip(label: Text('SM ${p.skill}')), Chip(label: Text('WF ${p.weakFoot}')), Chip(label: Text('WR ${p.attWr}/${p.defWr}')),
      ]),
      const Divider(),
      Text('PlayStyles', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      Wrap(spacing: 8, runSpacing: 8, children: p.playstyles.isEmpty ? [const Chip(label: Text('Aucun'))] : p.playstyles.map((x)=>Chip(label: Text(x))).toList()),
      const Divider(),
      Text('Stats détaillées', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      ...stats.map((k)=>ListTile(dense:true, title: Text(labelStat(k)), trailing: Text('${p.s[k]??0}', style: const TextStyle(fontWeight: FontWeight.w900)))),
    ]);
  });
}

class PlayerTile extends StatelessWidget {
  final Player p; final VoidCallback? onTap;
  const PlayerTile({super.key, required this.p, this.onTap});
  @override Widget build(BuildContext context)=>Card(child: ListTile(onTap:onTap, title: Text(p.name, maxLines:1, overflow:TextOverflow.ellipsis), subtitle: Text('${p.team} • ${p.pos} • ${p.height}cm ${p.weight}kg'), trailing: Column(mainAxisAlignment:MainAxisAlignment.center, children:[Text('OVR ${p.ovr}', style: const TextStyle(fontWeight:FontWeight.w900, color: Color(0xFF86EFAC))), Text(p.accel, style: const TextStyle(fontSize:11))])));
}


class TeamsPage extends StatefulWidget {
  final List<TeamInfo> teams;
  final List<Player> players;
  final ValueChanged<TeamInfo> onEditTeam;
  const TeamsPage({super.key, required this.teams, required this.players, required this.onEditTeam});
  @override State<TeamsPage> createState()=>_TeamsPageState();
}
class _TeamsPageState extends State<TeamsPage> {
  String q='';
  @override Widget build(BuildContext context) {
    final query=q.toLowerCase().trim();
    final rows=widget.teams.where((t)=>query.isEmpty || ('${t.name} ${t.manager}').toLowerCase().contains(query)).take(200).toList();
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('Teams Database', '${widget.teams.length} équipes • détails tactiques'),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Recherche équipe...'), onChanged:(v)=>setState(()=>q=v)),
      const SizedBox(height: 10),
      ...rows.map((t)=>TeamCard(team:t, players: widget.players, onEdit: ()=>widget.onEditTeam(t))),
    ]);
  }
}

class TeamCard extends StatelessWidget {
  final TeamInfo team;
  final List<Player> players;
  final VoidCallback onEdit;
  const TeamCard({super.key, required this.team, required this.players, required this.onEdit});
  @override Widget build(BuildContext context) {
    final squad = players.where((p)=>p.team==team.name).take(8).toList();
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        IconButton.filledTonal(onPressed:onEdit, icon: const Icon(Icons.edit)),
      ]),
      Text('Manager: ${team.manager}'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: MiniScore('OVR', team.overall, 'team')),
        const SizedBox(width: 8), Expanded(child: MiniScore('ATT', team.attack, 'attack')),
        const SizedBox(width: 8), Expanded(child: MiniScore('MID', team.midfield, 'mid')),
        const SizedBox(width: 8), Expanded(child: MiniScore('DEF', team.defense, 'def')),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        ...team.strongTraits.take(4).map((x)=>Chip(label: Text('Strong: $x'))),
        ...team.weakTraits.take(3).map((x)=>Chip(label: Text('Weak: $x'))),
      ]),
      if(squad.isNotEmpty) ...[
        const Divider(),
        Text('Joueurs clés', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        ...squad.map((p)=>ListTile(contentPadding: EdgeInsets.zero, dense:true, title: Text(p.name), subtitle: Text('${p.pos} • OVR ${p.ovr}')))
      ],
    ])));
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
  @override Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children: [
      Header('CRUD Players', 'Créer/modifier un joueur local pour les comparaisons'),
      FilledButton.icon(onPressed: ()=>setState(()=>editing = null), icon: const Icon(Icons.add), label: const Text('Nouveau joueur')),
      const SizedBox(height: 10),
      PlayerForm(initial: editing, onSave: (p){ widget.onSave(p); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joueur sauvegardé localement'))); }),
      const SizedBox(height: 14),
      Text('Modifier depuis la DB', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      ...widget.players.take(25).map((p)=>PlayerTile(p:p, onTap:()=>setState(()=>editing=p))),
    ]);
  }
}

class PlayerForm extends StatefulWidget {
  final Player? initial;
  final ValueChanged<Player> onSave;
  const PlayerForm({super.key, required this.initial, required this.onSave});
  @override State<PlayerForm> createState()=>_PlayerFormState();
}
class _PlayerFormState extends State<PlayerForm> {
  final name=TextEditingController(), team=TextEditingController(), pos=TextEditingController(), ovr=TextEditingController(), h=TextEditingController(), w=TextEditingController(), ps=TextEditingController();
  String body='Average', accel='Controlled';
  @override void didUpdateWidget(covariant PlayerForm oldWidget){super.didUpdateWidget(oldWidget); _fill();}
  @override void initState(){super.initState(); _fill();}
  void _fill(){
    final p=widget.initial;
    name.text=p?.name ?? ''; team.text=p?.team ?? ''; pos.text=p?.pos ?? 'ST'; ovr.text='${p?.ovr ?? 80}'; h.text='${p?.height ?? 180}'; w.text='${p?.weight ?? 75}';
    body=p?.body ?? 'Average'; accel=p?.accel ?? 'Controlled'; ps.text=(p?.playstyles ?? []).join(', ');
  }
  @override Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children:[
      TextField(controller:name, decoration: const InputDecoration(labelText:'Nom joueur')),
      const SizedBox(height:8),
      Row(children:[Expanded(child: TextField(controller:team, decoration: const InputDecoration(labelText:'Équipe'))), const SizedBox(width:8), Expanded(child: TextField(controller:pos, decoration: const InputDecoration(labelText:'Poste')))]),
      const SizedBox(height:8),
      Row(children:[Expanded(child: TextField(controller:ovr, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'OVR'))), const SizedBox(width:8), Expanded(child: TextField(controller:h, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Taille cm'))), const SizedBox(width:8), Expanded(child: TextField(controller:w, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Poids kg')))]),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child: DropdownButtonFormField<String>(value:body, items:['Lean','Average','Stocky','High & Lean','High & Average','High & Stocky','Unique'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>body=v!), decoration: const InputDecoration(labelText:'Body Type'))),
        const SizedBox(width:8),
        Expanded(child: DropdownButtonFormField<String>(value:accel, items:['Explosive','Mostly Explosive','Controlled','Controlled Lengthy','Lengthy'].map((x)=>DropdownMenuItem(value:x, child: Text(x))).toList(), onChanged:(v)=>setState(()=>accel=v!), decoration: const InputDecoration(labelText:'AcceleRATE'))),
      ]),
      const SizedBox(height:8),
      TextField(controller:ps, decoration: const InputDecoration(labelText:'PlayStyles séparés par virgule')),
      const SizedBox(height:10),
      Wrap(spacing: 6, children: ['Rapid+','Quick Step+','Technical+','Bruiser+','Anticipate+','Block+','Aerial+','Finesse+','Power Shot+','Incisive Pass+'].map((x)=>ActionChip(label: Text(x), onPressed:(){ if(!ps.text.contains(x)){ps.text = ps.text.trim().isEmpty ? x : '${ps.text}, $x';}})).toList()),
      const SizedBox(height:12),
      FilledButton.icon(onPressed: (){
        final base=widget.initial;
        final stats=Map<String,int>.from(base?.s ?? {'acc':75,'sprint':75,'str':75,'agg':70,'bal':75,'agi':75,'react':75,'ball':75,'drib':75,'defaw':60,'tackle':60,'inter':60,'finish':75,'shot':75,'comp':75,'stam':75,'jump':75,'head':70,'cross':70,'shortp':70,'longp':70,'vision':70});
        widget.onSave(Player(
          id: base?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: name.text.trim().isEmpty ? 'Custom Player' : name.text.trim(),
          team: team.text.trim().isEmpty ? 'Custom' : team.text.trim(),
          pos: pos.text.trim().isEmpty ? 'ST' : pos.text.trim(),
          pos2: base?.pos2 ?? '',
          ovr: int.tryParse(ovr.text) ?? 80, pot: base?.pot ?? int.tryParse(ovr.text) ?? 80,
          height: int.tryParse(h.text) ?? 180, weight: int.tryParse(w.text) ?? 75,
          body: body, accel: accel, foot: base?.foot ?? 'Right', attWr: base?.attWr ?? 'Medium', defWr: base?.defWr ?? 'Medium',
          skill: base?.skill ?? 3, weakFoot: base?.weakFoot ?? 3,
          playstyles: ps.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),
          s: stats,
        ));
      }, icon: const Icon(Icons.save), label: const Text('Sauvegarder joueur')),
    ])));
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
  @override Widget build(BuildContext context)=>ListView(padding: const EdgeInsets.all(14), children:[
    Header('CRUD Teams', 'Créer/modifier une équipe localement'),
    TeamForm(initial: editing, onSave: widget.onSave),
    const SizedBox(height:14),
    ...widget.teams.take(30).map((t)=>Card(child: ListTile(title:Text(t.name), subtitle:Text('OVR ${t.overall} • ${t.manager}'), trailing: const Icon(Icons.edit), onTap:()=>setState(()=>editing=t)))),
  ]);
}

Future<void> showTeamEditor(BuildContext context, TeamInfo team) async {
  await showDialog(context: context, builder: (_) => AlertDialog(title: Text(team.name), content: SingleChildScrollView(child: TeamForm(initial: team, onSave: (_){Navigator.pop(context);})), actions:[TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Fermer'))]));
}

class TeamForm extends StatefulWidget {
  final TeamInfo? initial;
  final ValueChanged<TeamInfo> onSave;
  const TeamForm({super.key, required this.initial, required this.onSave});
  @override State<TeamForm> createState()=>_TeamFormState();
}
class _TeamFormState extends State<TeamForm> {
  final name=TextEditingController(), manager=TextEditingController(), ovr=TextEditingController(), att=TextEditingController(), mid=TextEditingController(), def=TextEditingController(), strong=TextEditingController(), weak=TextEditingController();
  @override void initState(){super.initState(); fill();}
  @override void didUpdateWidget(covariant TeamForm oldWidget){super.didUpdateWidget(oldWidget); fill();}
  void fill(){final t=widget.initial; name.text=t?.name??''; manager.text=t?.manager??''; ovr.text='${t?.overall??80}'; att.text='${t?.attack??80}'; mid.text='${t?.midfield??80}'; def.text='${t?.defense??80}'; strong.text=(t?.strongTraits??[]).join(', '); weak.text=(t?.weakTraits??[]).join(', ');}
  @override Widget build(BuildContext context)=>Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children:[
    TextField(controller:name, decoration: const InputDecoration(labelText:'Nom équipe')),
    const SizedBox(height:8), TextField(controller:manager, decoration: const InputDecoration(labelText:'Manager')),
    const SizedBox(height:8),
    Row(children:[Expanded(child:TextField(controller:ovr, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'OVR'))), const SizedBox(width:8), Expanded(child:TextField(controller:att, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'ATT'))), const SizedBox(width:8), Expanded(child:TextField(controller:mid, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'MID'))), const SizedBox(width:8), Expanded(child:TextField(controller:def, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'DEF')))]),
    const SizedBox(height:8), TextField(controller:strong, decoration: const InputDecoration(labelText:'Forces séparées par virgule')),
    const SizedBox(height:8), TextField(controller:weak, decoration: const InputDecoration(labelText:'Faiblesses séparées par virgule')),
    const SizedBox(height:12),
    FilledButton.icon(onPressed:()=>widget.onSave(TeamInfo(id: widget.initial?.id ?? 'custom_team_${DateTime.now().millisecondsSinceEpoch}', name: name.text.trim().isEmpty?'Custom Team':name.text.trim(), manager: manager.text.trim().isEmpty?'—':manager.text.trim(), overall:int.tryParse(ovr.text)??80, attack:int.tryParse(att.text)??80, midfield:int.tryParse(mid.text)??80, defense:int.tryParse(def.text)??80, citylikeScore: widget.initial?.citylikeScore??0, weakTraits:weak.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(), equalTraits: widget.initial?.equalTraits??[], strongTraits:strong.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(), xi: widget.initial?.xi??[])), icon: const Icon(Icons.save), label: const Text('Sauvegarder team')),
  ])));
}

class ModesGuidePage extends StatelessWidget {
  const ModesGuidePage({super.key});
  @override Widget build(BuildContext context)=>ListView(padding: const EdgeInsets.all(14), children:[
    Header('Guide modes & matchups', 'Explication des situations utilisées par le moteur'),
    ...modes.map((m)=>Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(m.label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      Text(m.desc),
      const SizedBox(height:8),
      Wrap(spacing:6, runSpacing:6, children:m.w.entries.map((e)=>Chip(label: Text('${labelStat(e.key)} ${(e.value*100).round()}%'))).toList()),
    ])))),
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