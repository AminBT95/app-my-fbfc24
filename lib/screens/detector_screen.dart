import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/duel_engine.dart';
import '../widgets/player_picker.dart';

class DetectorScreen extends StatefulWidget {
  final List<Player> players;
  const DetectorScreen({super.key, required this.players});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  late Player ref;
  String mode = 'physical';
  String pos = 'all';
  String team = 'all';
  int minGap = 1;

  @override
  void initState() {
    super.initState();
    ref = widget.players.first;
  }

  @override
  Widget build(BuildContext context) {
    final refScore = DuelEngine.compare(ref, ref, mode).scoreA;
    final teams = ['all', ...widget.players.map((p) => p.team).where((t) => t.trim().isNotEmpty).toSet().take(200)];

    final rows = widget.players
        .where((p) => p.id != ref.id)
        .where((p) => team == 'all' || p.team == team)
        .where((p) => pos == 'all' || p.pos.toUpperCase().contains(pos))
        .map((p) {
          final sc = DuelEngine.compare(p, ref, mode).scoreA;
          return (p: p, score: sc, gap: sc - refScore);
        })
        .where((x) => x.gap >= minGap)
        .toList()
      ..sort((a, b) => b.gap.compareTo(a.gap));

    return ListView(padding: const EdgeInsets.all(14), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Joueur référence', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ref.name),
              subtitle: Text('${ref.team} • ${ref.pos} • OVR ${ref.ovr}'),
              trailing: IconButton.filledTonal(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final picked = await showPlayerSearchDialog(context, widget.players, ref);
                  if (picked != null) setState(() => ref = picked);
                },
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: mode,
        decoration: const InputDecoration(labelText: 'Mode', border: OutlineInputBorder()),
        items: DuelEngine.modes.values.map((m) => DropdownMenuItem(value: m.key, child: Text(m.label))).toList(),
        onChanged: (v) => setState(() => mode = v!),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: pos,
            decoration: const InputDecoration(labelText: 'Poste', border: OutlineInputBorder()),
            items: ['all', 'ST', 'LW', 'RW', 'CAM', 'CM', 'CDM', 'LB', 'RB', 'CB', 'GK']
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: (v) => setState(() => pos = v!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: teams.contains(team) ? team : 'all',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Équipe', border: OutlineInputBorder()),
            items: teams.map((x) => DropdownMenuItem(value: x, child: Text(x, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => team = v!),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('${rows.length} joueurs plus forts que ${ref.name} dans ce mode. Score référence : $refScore'),
        ),
      ),
      ...rows.take(40).map((x) => Card(
            child: ListTile(
              title: Text(x.p.name),
              subtitle: Text('${x.p.team} • ${x.p.pos} • ${x.p.height}cm ${x.p.weight}kg • ${x.p.bodyType} • ${x.p.accelerate}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${x.score}', style: const TextStyle(fontWeight: FontWeight.w900)),
                Text('+${x.gap}', style: const TextStyle(color: Color(0xFF86EFAC))),
              ]),
            ),
          )),
    ]);
  }
}
