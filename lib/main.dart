import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  runApp(const Fc24CoachSafeApp());
}

class Player {
  final String id;
  final String name;
  final String team;
  final String pos;
  final int ovr;
  final int height;
  final int weight;
  final String body;
  final String accel;
  final List<String> playstyles;
  final Map<String, int> s;

  const Player({
    required this.id,
    required this.name,
    required this.team,
    required this.pos,
    required this.ovr,
    required this.height,
    required this.weight,
    required this.body,
    required this.accel,
    required this.playstyles,
    required this.s,
  });
}

const players = <Player>[
  Player(id:'mbappe', name:'Kylian Mbappé', team:'PSG', pos:'ST/LW', ovr:91, height:182, weight:75, body:'Unique', accel:'Mostly Explosive', playstyles:['Quick Step+','Rapid+','Finesse+'], s:{'acc':97,'sprint':97,'str':77,'agg':64,'bal':83,'agi':92,'react':93,'ball':92,'drib':93,'defaw':36,'tackle':34,'inter':38,'finish':94,'shot':90,'comp':92,'stam':88,'jump':82,'head':76,'cross':78,'shortp':84,'longp':74,'vision':83}),
  Player(id:'walker', name:'Kyle Walker', team:'Manchester City', pos:'RB/CB', ovr:84, height:183, weight:83, body:'Average', accel:'Controlled', playstyles:['Rapid+','Block+'], s:{'acc':85,'sprint':94,'str':82,'agg':81,'bal':76,'agi':75,'react':84,'ball':78,'drib':77,'defaw':82,'tackle':84,'inter':82,'finish':63,'shot':78,'comp':80,'stam':86,'jump':83,'head':73,'cross':81,'shortp':82,'longp':77,'vision':72}),
  Player(id:'haaland', name:'Erling Haaland', team:'Manchester City', pos:'ST', ovr:91, height:195, weight:94, body:'Unique', accel:'Lengthy', playstyles:['Power Shot+','Aerial+','Bruiser+'], s:{'acc':82,'sprint':94,'str':93,'agg':88,'bal':72,'agi':78,'react':94,'ball':82,'drib':80,'defaw':45,'tackle':40,'inter':38,'finish':96,'shot':94,'comp':88,'stam':85,'jump':94,'head':90,'cross':45,'shortp':77,'longp':65,'vision':74}),
  Player(id:'vvd', name:'Virgil van Dijk', team:'Liverpool', pos:'CB', ovr:89, height:193, weight:92, body:'Unique', accel:'Lengthy', playstyles:['Anticipate+','Aerial+','Bruiser+'], s:{'acc':74,'sprint':84,'str':93,'agg':85,'bal':65,'agi':61,'react':88,'ball':76,'drib':72,'defaw':91,'tackle':92,'inter':91,'finish':52,'shot':81,'comp':89,'stam':75,'jump':90,'head':89,'cross':55,'shortp':79,'longp':76,'vision':65}),
  Player(id:'messi', name:'Lionel Messi', team:'Inter Miami/Custom', pos:'CAM/RW', ovr:90, height:170, weight:72, body:'Unique', accel:'Explosive', playstyles:['Technical+','Finesse+','Incisive Pass+'], s:{'acc':87,'sprint':78,'str':68,'agg':44,'bal':95,'agi':91,'react':88,'ball':93,'drib':96,'defaw':35,'tackle':35,'inter':40,'finish':90,'shot':86,'comp':96,'stam':70,'jump':68,'head':70,'cross':85,'shortp':91,'longp':90,'vision':94}),
  Player(id:'kdb', name:'Kevin De Bruyne', team:'Manchester City', pos:'CM/CAM', ovr:91, height:181, weight:75, body:'Unique', accel:'Controlled', playstyles:['Incisive Pass+','Dead Ball+','Long Ball Pass+'], s:{'acc':76,'sprint':68,'str':74,'agg':76,'bal':78,'agi':79,'react':92,'ball':92,'drib':88,'defaw':66,'tackle':66,'inter':68,'finish':85,'shot':92,'comp':91,'stam':88,'jump':64,'head':55,'cross':94,'shortp':94,'longp':93,'vision':95}),
  Player(id:'griezmann', name:'Antoine Griezmann', team:'Atlético Madrid', pos:'CF/ST/CAM', ovr:88, height:176, weight:73, body:'Unique', accel:'Controlled', playstyles:['Finesse+','Technical+','Incisive Pass+'], s:{'acc':82,'sprint':78,'str':74,'agg':76,'bal':88,'agi':88,'react':90,'ball':90,'drib':89,'defaw':60,'tackle':58,'inter':62,'finish':90,'shot':88,'comp':91,'stam':84,'jump':85,'head':86,'cross':84,'shortp':89,'longp':86,'vision':90}),
  Player(id:'hojlund', name:'Rasmus Højlund', team:'Manchester United', pos:'ST', ovr:76, height:191, weight:86, body:'High & Average', accel:'Lengthy', playstyles:['Rapid+','Bruiser+','Aerial+'], s:{'acc':82,'sprint':88,'str':84,'agg':78,'bal':74,'agi':76,'react':80,'ball':79,'drib':78,'defaw':34,'tackle':32,'inter':28,'finish':82,'shot':84,'comp':78,'stam':79,'jump':86,'head':82,'cross':50,'shortp':70,'longp':62,'vision':68}),
];

class Mode {
  final String key;
  final String label;
  final Map<String,double> w;
  const Mode(this.key, this.label, this.w);
}

const modes = <Mode>[
  Mode('physical','Duel physique', {'str':.34,'agg':.18,'bal':.15,'sprint':.10,'react':.10,'stam':.08,'jump':.05}),
  Mode('speed_short','Vitesse courte 0-10m', {'acc':.42,'sprint':.20,'agi':.14,'react':.12,'bal':.07,'stam':.05}),
  Mode('speed_long','Course longue', {'sprint':.42,'acc':.22,'stam':.14,'str':.08,'react':.08,'agi':.06}),
  Mode('dribble','Dribble 1v1', {'agi':.24,'drib':.22,'acc':.18,'bal':.14,'ball':.12,'react':.10}),
  Mode('defense','Tacle/récupération', {'tackle':.28,'defaw':.24,'inter':.16,'react':.12,'str':.10,'agg':.10}),
  Mode('pass','Passe vs interception', {'vision':.26,'shortp':.22,'longp':.20,'comp':.12,'react':.08,'ball':.08,'drib':.04}),
  Mode('aerial','Duel aérien', {'head':.28,'jump':.24,'str':.18,'react':.10,'agg':.08,'defaw':.06,'finish':.06}),
  Mode('finish','Finition sous pression', {'finish':.28,'comp':.22,'shot':.18,'react':.12,'ball':.08,'str':.06,'bal':.06}),
  Mode('pressing','Pressing', {'stam':.22,'agg':.20,'acc':.18,'react':.14,'defaw':.10,'str':.08,'agi':.08}),
];

int score(Player p, Mode m) {
  double core = 0;
  for (final e in m.w.entries) {
    core += (p.s[e.key] ?? 0) * e.value;
  }
  double bonus = 0;
  if (m.key.contains('speed')) {
    if (p.accel.contains('Explosive')) bonus += m.key == 'speed_short' ? 8 : 3;
    if (p.accel.contains('Lengthy')) bonus += m.key == 'speed_long' ? 8 : -2;
    if (p.playstyles.contains('Rapid+')) bonus += m.key == 'speed_long' ? 6 : 2;
    if (p.playstyles.contains('Quick Step+')) bonus += m.key == 'speed_short' ? 8 : 2;
  }
  if (m.key == 'dribble') {
    if (p.body == 'Lean') bonus += 8;
    if (p.body == 'Unique') bonus += 6;
    if (p.playstyles.contains('Technical+')) bonus += 8;
    if (p.playstyles.contains('Trickster+')) bonus += 6;
  }
  if (m.key == 'physical') {
    if (p.weight >= 85) bonus += 7;
    if (p.height >= 188) bonus += 5;
    if (p.body.contains('Stocky') || p.body == 'Unique') bonus += 6;
    if (p.playstyles.contains('Bruiser+')) bonus += 8;
  }
  if (m.key == 'defense') {
    if (p.playstyles.contains('Anticipate+')) bonus += 9;
    if (p.playstyles.contains('Block+')) bonus += 7;
  }
  if (m.key == 'aerial') {
    if (p.height >= 190) bonus += 8;
    if (p.playstyles.contains('Aerial+')) bonus += 10;
  }
  if (m.key == 'finish') {
    if (p.playstyles.contains('Finesse+')) bonus += 8;
    if (p.playstyles.contains('Power Shot+')) bonus += 8;
  }
  if (m.key == 'pass') {
    if (p.playstyles.contains('Incisive Pass+')) bonus += 9;
    if (p.playstyles.contains('Long Ball Pass+')) bonus += 8;
  }
  if (m.key == 'pressing') {
    if (p.playstyles.contains('Relentless+')) bonus += 9;
    if (p.playstyles.contains('Intercept+')) bonus += 7;
  }
  return (core + bonus).round();
}

class Fc24CoachSafeApp extends StatelessWidget {
  const Fc24CoachSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FC24 Coach AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF06111F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E), brightness: Brightness.dark),
        cardTheme: CardTheme(color: const Color(0xFF0B1728), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      ),
      home: const SafeHome(),
    );
  }
}

class SafeHome extends StatefulWidget {
  const SafeHome({super.key});

  @override
  State<SafeHome> createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  int tab = 0;
  Player a = players[0];
  Player b = players[1];
  Mode mode = modes[3];

  @override
  Widget build(BuildContext context) {
    final pages = [
      ComparePage(a: a, b: b, mode: mode, onA: (p)=>setState(()=>a=p), onB: (p)=>setState(()=>b=p), onMode: (m)=>setState(()=>mode=m)),
      DetectorPage(mode: mode),
      TacticalPage(a: a, b: b, mode: mode),
      const AboutPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('FC24 Coach AI'), centerTitle: false),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(()=>tab=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.compare_arrows), label: 'Comparer'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Détecter'),
          NavigationDestination(icon: Icon(Icons.sports_soccer), label: 'Terrain'),
          NavigationDestination(icon: Icon(Icons.info), label: 'Info'),
        ],
      ),
    );
  }
}

class ComparePage extends StatelessWidget {
  final Player a,b;
  final Mode mode;
  final ValueChanged<Player> onA,onB;
  final ValueChanged<Mode> onMode;
  const ComparePage({super.key, required this.a, required this.b, required this.mode, required this.onA, required this.onB, required this.onMode});

  @override
  Widget build(BuildContext context) {
    final sa = score(a, mode), sb = score(b, mode);
    final winner = sa >= sb ? a : b;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text('Comparateur duel', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      PlayerSelect(title:'Joueur A', value:a, onChanged:onA),
      PlayerSelect(title:'Joueur B', value:b, onChanged:onB),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: DropdownButtonFormField<String>(
        value: mode.key,
        decoration: const InputDecoration(labelText:'Mode duel', border: OutlineInputBorder()),
        items: modes.map((m)=>DropdownMenuItem(value:m.key, child: Text(m.label))).toList(),
        onChanged: (v)=>onMode(modes.firstWhere((m)=>m.key==v)),
      ))),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gagnant prévu : ${winner.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ScoreBox(name:a.name, score:sa)),
          const SizedBox(width: 10),
          Expanded(child: ScoreBox(name:b.name, score:sb)),
        ]),
        const SizedBox(height: 14),
        Text('Détail pondéré', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...mode.w.entries.map((e){
          final av=a.s[e.key]??0, bv=b.s[e.key]??0;
          final ap=(av*e.value).round(), bp=(bv*e.value).round();
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(e.key),
            subtitle: Text('poids ${(e.value*100).round()}%'),
            trailing: Text('$av → $ap   |   $bv → $bp', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }),
        const Divider(),
        Text('PlayStyles ${a.name}: ${a.playstyles.join(", ")}'),
        Text('PlayStyles ${b.name}: ${b.playstyles.join(", ")}'),
      ]))),
    ]);
  }
}

class ScoreBox extends StatelessWidget {
  final String name;
  final int score;
  const ScoreBox({super.key, required this.name, required this.score});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0xFF101F35)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text('$score', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF86EFAC))),
    ]),
  );
}

class PlayerSelect extends StatelessWidget {
  final String title;
  final Player value;
  final ValueChanged<Player> onChanged;
  const PlayerSelect({super.key, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(value.name),
        subtitle: Text('${value.team} • ${value.pos} • OVR ${value.ovr} • ${value.height}cm ${value.weight}kg'),
        trailing: IconButton.filledTonal(icon: const Icon(Icons.search), onPressed: () async {
          final p = await showDialog<Player>(context: context, builder: (_) => PlayerSearch(current: value));
          if (p != null) onChanged(p);
        }),
      ),
      Wrap(spacing: 8, children: [
        Chip(label: Text(value.body)),
        Chip(label: Text(value.accel)),
        ...value.playstyles.take(3).map((x)=>Chip(label: Text(x))),
      ])
    ])));
  }
}

class PlayerSearch extends StatefulWidget {
  final Player current;
  const PlayerSearch({super.key, required this.current});
  @override
  State<PlayerSearch> createState() => _PlayerSearchState();
}

class _PlayerSearchState extends State<PlayerSearch> {
  String q='';
  @override
  Widget build(BuildContext context) {
    final res = players.where((p)=>('${p.name} ${p.team} ${p.pos}').toLowerCase().contains(q.toLowerCase())).toList();
    return AlertDialog(
      title: const Text('Choisir joueur'),
      content: SizedBox(width: double.maxFinite, height: 440, child: Column(children: [
        TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Recherche', border: OutlineInputBorder()), onChanged: (v)=>setState(()=>q=v)),
        const SizedBox(height: 10),
        Expanded(child: ListView(children: res.map((p)=>ListTile(
          title: Text(p.name),
          subtitle: Text('${p.team} • ${p.pos} • OVR ${p.ovr}'),
          onTap: ()=>Navigator.pop(context,p),
        )).toList())),
      ])),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Fermer'))],
    );
  }
}

class DetectorPage extends StatefulWidget {
  final Mode mode;
  const DetectorPage({super.key, required this.mode});
  @override
  State<DetectorPage> createState() => _DetectorPageState();
}

class _DetectorPageState extends State<DetectorPage> {
  Player ref = players[0];
  Mode mode = modes[3];

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
  }

  @override
  Widget build(BuildContext context) {
    final refScore = score(ref, mode);
    final rows = players.where((p)=>p.id!=ref.id).map((p)=>(p:p, sc:score(p,mode))).where((x)=>x.sc>refScore).toList()
      ..sort((x,y)=>y.sc.compareTo(x.sc));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text('Détection joueurs plus forts', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      PlayerSelect(title:'Référence', value: ref, onChanged: (p)=>setState(()=>ref=p)),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: DropdownButtonFormField<String>(
        value: mode.key,
        decoration: const InputDecoration(labelText:'Mode', border: OutlineInputBorder()),
        items: modes.map((m)=>DropdownMenuItem(value:m.key, child: Text(m.label))).toList(),
        onChanged: (v)=>setState(()=>mode=modes.firstWhere((m)=>m.key==v)),
      ))),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('${rows.length} joueurs plus forts que ${ref.name} — score référence $refScore'))),
      ...rows.map((x)=>Card(child: ListTile(
        title: Text(x.p.name),
        subtitle: Text('${x.p.team} • ${x.p.pos} • ${x.p.body} • ${x.p.accel}'),
        trailing: Text('${x.sc}  +${x.sc-refScore}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF86EFAC))),
      ))),
    ]);
  }
}

class TacticalPage extends StatelessWidget {
  final Player a,b;
  final Mode mode;
  const TacticalPage({super.key, required this.a, required this.b, required this.mode});

  @override
  Widget build(BuildContext context) {
    final sa=score(a,mode), sb=score(b,mode);
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text('Terrain tactique', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('Mode : ${mode.label}\nGagnant prévu : ${sa>=sb?a.name:b.name}'))),
      AspectRatio(
        aspectRatio: 1.55,
        child: CustomPaint(
          painter: PitchPainter(aName:a.name, bName:b.name, winnerA: sa>=sb),
        ),
      ),
    ]);
  }
}

class PitchPainter extends CustomPainter {
  final String aName,bName;
  final bool winnerA;
  PitchPainter({required this.aName, required this.bName, required this.winnerA});

  @override
  void paint(Canvas canvas, Size size) {
    final field = Paint()..color = const Color(0xFF146C43);
    final line = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 2;
    final run = Paint()..color = const Color(0xFFFACC15)..strokeWidth = 4..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)), field);
    canvas.drawRect(Rect.fromLTWH(18,18,size.width-36,size.height-36), line);
    canvas.drawLine(Offset(size.width/2,18), Offset(size.width/2,size.height-18), line);
    canvas.drawCircle(Offset(size.width/2,size.height/2), 42, line);
    final a = Offset(size.width*.35,size.height*.55);
    final b = Offset(size.width*.65,size.height*.48);
    canvas.drawLine(a,b,run);
    drawPlayer(canvas,a,aName.substring(0,min(2,aName.length)).toUpperCase(), winnerA, const Color(0xFF38BDF8));
    drawPlayer(canvas,b,bName.substring(0,min(2,bName.length)).toUpperCase(), !winnerA, const Color(0xFFFB7185));
    canvas.drawCircle(Offset(size.width*.50,size.height*.50), 8, Paint()..color=Colors.white);
  }

  void drawPlayer(Canvas canvas, Offset c, String label, bool win, Color color) {
    final p = Paint()..color=color;
    canvas.drawCircle(c, win ? 25 : 22, p);
    if (win) canvas.drawCircle(c, 32, Paint()..color=const Color(0xFF22C55E).withOpacity(.25));
    final tp = TextPainter(text: TextSpan(text: label, style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w900,fontSize: 14)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, c-Offset(tp.width/2,tp.height/2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: const [
    Card(child: Padding(padding: EdgeInsets.all(16), child: Text('FC24 Coach AI — version safe start.\n\nCette version démarre sans assets externes ni JSON au lancement pour éviter les crashs. Après validation APK, on peut réintégrer la grosse base joueurs progressivement.'))),
  ]);
}
