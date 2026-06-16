import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerPicker extends StatelessWidget {
  final String title;
  final List<Player> players;
  final Player value;
  final ValueChanged<Player> onChanged;
  const PlayerPicker({super.key, required this.title, required this.players, required this.value, required this.onChanged});

  @override Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value.id,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Joueur'),
          items: players.take(600).map((p)=>DropdownMenuItem(value:p.id, child: Text('${p.name} — ${p.team} — ${p.pos} — ${p.ovr}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (id){ final p = players.firstWhere((x)=>x.id==id); onChanged(p); },
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip('OVR', '${value.ovr}'), _chip('Pos', value.pos), _chip('Taille', '${value.height}cm'), _chip('Poids', '${value.weight}kg'), _chip('Body', value.bodyType), _chip('Accel', value.accelerate),
        ]),
      ]),
    ));
  }
  Widget _chip(String a, String b)=>Chip(label: Text('$a: $b'));
}
