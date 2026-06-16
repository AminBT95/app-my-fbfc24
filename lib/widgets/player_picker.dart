import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerPicker extends StatelessWidget {
  final String title;
  final List<Player> players;
  final Player value;
  final ValueChanged<Player> onChanged;

  const PlayerPicker({
    super.key,
    required this.title,
    required this.players,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final exists = players.any((p) => p.id == value.id);
    final safeValue = exists ? value : (players.isNotEmpty ? players.first : value);

    final list = <Player>[safeValue];
    for (final p in players.take(80)) {
      if (!list.any((x) => x.id == p.id)) list.add(p);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: safeValue.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Joueur',
                ),
                items: list.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} — ${p.team} — ${p.pos} — ${p.ovr}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (id) {
                  final p = players.firstWhere((x) => x.id == id, orElse: () => safeValue);
                  onChanged(p);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Recherche complète',
              onPressed: () async {
                final picked = await showPlayerSearchDialog(context, players, safeValue);
                if (picked != null) onChanged(picked);
              },
              icon: const Icon(Icons.search),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('OVR', '${safeValue.ovr}'),
            _chip('Pos', safeValue.pos),
            _chip('Taille', '${safeValue.height}cm'),
            _chip('Poids', '${safeValue.weight}kg'),
            _chip('Body', safeValue.bodyType),
            _chip('Accel', safeValue.accelerate),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String a, String b) => Chip(label: Text('$a: $b'));
}

Future<Player?> showPlayerSearchDialog(BuildContext context, List<Player> players, Player current) {
  return showDialog<Player>(
    context: context,
    builder: (context) => _PlayerSearchDialog(players: players, current: current),
  );
}

class _PlayerSearchDialog extends StatefulWidget {
  final List<Player> players;
  final Player current;
  const _PlayerSearchDialog({required this.players, required this.current});

  @override
  State<_PlayerSearchDialog> createState() => _PlayerSearchDialogState();
}

class _PlayerSearchDialogState extends State<_PlayerSearchDialog> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final query = q.trim().toLowerCase();
    final results = query.isEmpty
        ? widget.players.take(80).toList()
        : widget.players.where((p) =>
            ('${p.name} ${p.team} ${p.pos} ${p.ovr}').toLowerCase().contains(query)
          ).take(120).toList();

    return AlertDialog(
      title: const Text('Choisir un joueur'),
      content: SizedBox(
        width: double.maxFinite,
        height: 520,
        child: Column(children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nom, équipe, poste...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => q = v),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final p = results[i];
                return ListTile(
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${p.team} • ${p.pos} • OVR ${p.ovr} • ${p.height}cm ${p.weight}kg'),
                  trailing: p.id == widget.current.id ? const Icon(Icons.check_circle) : null,
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ],
    );
  }
}
