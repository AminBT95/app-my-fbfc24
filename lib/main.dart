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

class GameDb {
  final List<Player> players;
  final int teamCount;
  const GameDb(this.players, this.teamCount);

  static Future<GameDb> load() async {
    final raw = await rootBundle.loadString('assets/data/fc24-real-data.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['players'] as List).cast<dynamic>();
    final players = <Player>[];
    for (final item in list) {
      try {
        players.add(Player.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    players.sort((a, b) => b.ovr.compareTo(a.ovr));
    return GameDb(players, (decoded['teams'] as List?)?.length ?? 0);
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
  Player? a,b;
  Mode mode = modes[3];
  String q = '';

  @override void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    try {
      final loaded = await GameDb.load();
      setState(() {
        db = loaded;
        a = loaded.players.firstWhere((p)=>p.name.toLowerCase().contains('mbapp'), orElse: ()=>loaded.players.first);
        b = loaded.players.firstWhere((p)=>p.name.toLowerCase().contains('walker'), orElse: ()=>loaded.players.skip(1).first);
      });
    } catch (e) { setState(()=>error=e); }
  }

  @override Widget build(BuildContext context) {
    final loaded = db;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FC24 Coach AI Pro'),
        actions: [
          if (loaded != null) Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: Text('${loaded.players.length} joueurs', style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w900)))),
        ],
      ),
      body: SafeArea(
        child: loaded == null
          ? StartLoader(error: error, onRetry: _load)
          : IndexedStack(index: tab, children: [
              DashboardPage(db: loaded, onStart: ()=>setState(()=>tab=1)),
              ComparePage(players: loaded.players, a: a!, b: b!, mode: mode, onA:(p)=>setState(()=>a=p), onB:(p)=>setState(()=>b=p), onMode:(m)=>setState(()=>mode=m)),
              DetectorPage(players: loaded.players, ref: a!, mode: mode),
              DatabasePage(players: loaded.players),
              TacticalPage(a: a!, b: b!, mode: mode),
            ]),
      ),
      bottomNavigationBar: loaded == null ? null : NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i)=>setState(()=>tab=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.compare_arrows_rounded), label: 'Comparer'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Détecter'),
          NavigationDestination(icon: Icon(Icons.storage_rounded), label: 'DB'),
          NavigationDestination(icon: Icon(Icons.sports_soccer_rounded), label: 'Terrain'),
        ],
      ),
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
      ...rows.map((p)=>PlayerTile(p:p)),
    ]);
  }
}

class PlayerTile extends StatelessWidget {
  final Player p; final VoidCallback? onTap;
  const PlayerTile({super.key, required this.p, this.onTap});
  @override Widget build(BuildContext context)=>Card(child: ListTile(onTap:onTap, title: Text(p.name, maxLines:1, overflow:TextOverflow.ellipsis), subtitle: Text('${p.team} • ${p.pos} • ${p.height}cm ${p.weight}kg'), trailing: Column(mainAxisAlignment:MainAxisAlignment.center, children:[Text('OVR ${p.ovr}', style: const TextStyle(fontWeight:FontWeight.w900, color: Color(0xFF86EFAC))), Text(p.accel, style: const TextStyle(fontSize:11))])));
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