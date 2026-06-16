class Player {
  final String id;
  final String name;
  final String team;
  final String pos;
  final int ovr;
  final int height;
  final int weight;
  final String bodyType;
  final String accelerate;
  final String foot;
  final List<String> playStyles;
  final Map<String, int> s;

  const Player({
    required this.id,
    required this.name,
    required this.team,
    required this.pos,
    required this.ovr,
    required this.height,
    required this.weight,
    required this.bodyType,
    required this.accelerate,
    required this.foot,
    required this.playStyles,
    required this.s,
  });

  factory Player.fromJson(Map<String, dynamic> j) {
    int n(dynamic v, [int fallback = 0]) => int.tryParse('${v ?? ''}') ?? (v is num ? v.round() : fallback);
    String str(dynamic v, [String fallback = '']) => (v ?? fallback).toString();
    List<String> listFrom(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).where((x) => x.trim().isNotEmpty && x != 'null').toList();
      final t = str(v);
      if (t.isEmpty || t == 'null') return <String>[];
      return [t];
    }
    final decoded = <String>[
      ...listFrom(j['playstyles']),
      ...listFrom(j['trait1Decoded']),
      ...listFrom(j['trait2Decoded']),
      ...listFrom(j['icontrait1']),
      ...listFrom(j['icontrait2']),
    ].where((x) => x.trim().isNotEmpty && x != 'null' && x != '0').toSet().toList();
    final nestedStats = j['stats'] is Map ? (j['stats'] as Map) : const {};
    int stat(String key, String original, [int fallback = 0]) => n(j[original] ?? nestedStats[key], fallback);
    final s = <String, int>{
       'pac': stat('pac','PAC'),  'sho': stat('sho','SHO'),  'pas': stat('pas','PAS'),  'dri': stat('dri','DRI'),  'def': stat('def','DEF'),  'phy': stat('phy','PHY'),
       'acc': stat('acc','acceleration'),  'sprint': stat('sprint','sprintspeed'),  'str': stat('str','strength'),  'agg': stat('agg','aggression'),
       'bal': stat('bal','balance'),  'agi': stat('agi','agility'),  'react': stat('react','reactions'),  'ball': stat('ball','ballcontrol'),  'drib': stat('drib','dribbling'),
       'defaw': stat('defaw','defaw'),  'tackle': stat('tackle','standtackle'),  'inter': stat('inter','interceptions'),
       'finish': stat('finish','finishing'),  'shot': stat('shot','shotpower'),  'comp': stat('comp','composure'),  'stam': stat('stam','stamina'),
       'jump': stat('jump','jumping'),  'head': stat('head','heading'),  'cross': stat('cross','crossing'),  'shortp': stat('shortp','shortpass'),  'longp': stat('longp','longpass'),  'vision': stat('vision','vision'),
       'gkdiv': stat('gkdiv','gkdiving'),  'gkhan': stat('gkhan','gkhandling'),  'gkkick': stat('gkkick','gkkicking'),  'gkpos': stat('gkpos','gkpositioning'),  'gkref': stat('gkref','gkreflexes'),
    };
    return Player(
      id: str(j['id']), name: str(j['name'], 'Player'), team: str(j['team'], '—'), pos: str(j['pos'], 'N/A'), ovr: n(j['ovr']),
      height: n(j['height'], 180), weight: n(j['weight'], 75), bodyType: str(j['bodytype'], 'Average'), accelerate: str(j['accelerate'], 'Controlled'),
      foot: str(j['foot'], 'Right'), playStyles: decoded, s: s,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'team': team, 'pos': pos, 'ovr': ovr, 'height': height, 'weight': weight,
    'bodytype': bodyType, 'accelerate': accelerate, 'foot': foot, 'playstyles': playStyles, 'stats': s,
  };
}
