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
    final decoded = <String>[
      str(j['trait1Decoded']),
      str(j['trait2Decoded']),
      str(j['icontrait1']),
      str(j['icontrait2']),
    ].where((x) => x.trim().isNotEmpty && x != 'null').toSet().toList();
    final s = <String, int>{
      'pac': n(j['PAC']), 'sho': n(j['SHO']), 'pas': n(j['PAS']), 'dri': n(j['DRI']), 'def': n(j['DEF']), 'phy': n(j['PHY']),
      'acc': n(j['acceleration']), 'sprint': n(j['sprintspeed']), 'str': n(j['strength']), 'agg': n(j['aggression']),
      'bal': n(j['balance']), 'agi': n(j['agility']), 'react': n(j['reactions']), 'ball': n(j['ballcontrol']), 'drib': n(j['dribbling']),
      'defaw': n(j['defaw']), 'tackle': n(j['standtackle']), 'inter': n(j['interceptions']),
      'finish': n(j['finishing']), 'shot': n(j['shotpower']), 'comp': n(j['composure']), 'stam': n(j['stamina']),
      'jump': n(j['jumping']), 'head': n(j['heading']), 'cross': n(j['crossing']), 'shortp': n(j['shortpass']), 'longp': n(j['longpass']), 'vision': n(j['vision']),
      'gkdiv': n(j['gkdiving']), 'gkhan': n(j['gkhandling']), 'gkkick': n(j['gkkicking']), 'gkpos': n(j['gkpositioning']), 'gkref': n(j['gkreflexes']),
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
