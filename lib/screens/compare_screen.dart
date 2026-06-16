import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/duel_engine.dart';
import '../widgets/player_picker.dart';
import '../widgets/tactical_pitch.dart';

class CompareScreen extends StatefulWidget { final List<Player> players; const CompareScreen({super.key, required this.players}); @override State<CompareScreen> createState()=>_CompareScreenState(); }
class _CompareScreenState extends State<CompareScreen> {
  late Player a,b; String mode='physical'; String query='';
  @override void initState(){ super.initState(); a=widget.players.firstWhere((p)=>p.name.toLowerCase().contains('haaland'), orElse:()=>widget.players.first); b=widget.players.firstWhere((p)=>p.name.toLowerCase().contains('van dijk'), orElse:()=>widget.players[1]); mode=DuelEngine.autoModeForPositions(a,b); }
  @override Widget build(BuildContext context){
    final filtered=query.isEmpty?widget.players:widget.players.where((p)=>(p.name+p.team+p.pos).toLowerCase().contains(query.toLowerCase())).toList();
    final result=DuelEngine.compare(a,b,mode);
    return ListView(padding:const EdgeInsets.all(14), children:[
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Recherche joueur...', border: OutlineInputBorder()), onChanged:(v)=>setState(()=>query=v)),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:mode, decoration:const InputDecoration(labelText:'Mode / duel', border:OutlineInputBorder()), items:DuelEngine.modes.values.map((m)=>DropdownMenuItem(value:m.key,child:Text(m.label))).toList(), onChanged:(v)=>setState(()=>mode=v!)),
      const SizedBox(height:12),
      PlayerPicker(title:'Joueur A', players: filtered, value:a, onChanged:(p)=>setState(()=>a=p)),
      PlayerPicker(title:'Joueur B', players: filtered, value:b, onChanged:(p)=>setState(()=>b=p)),
      Card(child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text('Résultat', style:Theme.of(context).textTheme.titleLarge), const SizedBox(height:10),
        Text('Gagnant probable : ${result.winner}', style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:Color(0xFF86EFAC))),
        const SizedBox(height:10), LinearProgressIndicator(value:result.percentA, minHeight:12), const SizedBox(height:8),
        Text('${a.name}: ${result.scoreA} pts   |   ${b.name}: ${result.scoreB} pts'),
        const Divider(), Text('Stats pondérées: ${result.coreA} vs ${result.coreB}'), Text('Bonus profil/playstyles: ${result.bonusA} vs ${result.bonusB}'),
        const SizedBox(height:8), ...result.reasons.map((r)=>Text('• $r')),
      ]))),
      TacticalPitch(a:a,b:b,result:result,modeKey:mode),
    ]);
  }
}
