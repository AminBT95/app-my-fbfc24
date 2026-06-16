import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/data_service.dart';

class PlayersScreen extends StatefulWidget { final List<Player> players; const PlayersScreen({super.key, required this.players}); @override State<PlayersScreen> createState()=>_PlayersScreenState(); }
class _PlayersScreenState extends State<PlayersScreen> { String q=''; final url=TextEditingController();
  @override Widget build(BuildContext context){ final list=widget.players.where((p)=>(p.name+p.team+p.pos).toLowerCase().contains(q.toLowerCase())).take(80).toList(); return ListView(padding:const EdgeInsets.all(14), children:[
    TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'Chercher joueur...', border:OutlineInputBorder()), onChanged:(v)=>setState(()=>q=v)),
    const SizedBox(height:12),
    Card(child:Padding(padding:const EdgeInsets.all(14), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text('Import SoFIFA / FIFAIndex', style:Theme.of(context).textTheme.titleMedium), const SizedBox(height:8),
      TextField(controller:url, decoration:const InputDecoration(hintText:'Colle URL SoFIFA ou FIFAIndex', border:OutlineInputBorder())), const SizedBox(height:8),
      ElevatedButton.icon(onPressed:() async { final p=DataService().importFromUrlNameOnly(url.text); await DataService().saveCustomPlayer(p); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${p.name} ajouté. Redémarre l’app pour recharger la liste.'))); }, icon:const Icon(Icons.add), label:const Text('Importer nom + fiche rapide')),
      const Text('Note : SoFIFA/FIFAIndex peuvent bloquer les stats auto. L’app crée la fiche, puis tu peux compléter stats/playstyles dans le code ou future édition CRUD.'),
    ]))),
    ...list.map((p)=>Card(child:ListTile(title:Text('${p.name}  ${p.ovr}'), subtitle:Text('${p.team} • ${p.pos} • ${p.height}cm ${p.weight}kg • ${p.bodyType} • ${p.playStyles.join(', ')}'))))
  ]); }
}
