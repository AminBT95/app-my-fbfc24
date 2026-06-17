import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/duel_engine.dart';
import '../widgets/player_picker.dart';
import '../widgets/tactical_pitch.dart';

class CompareScreen extends StatefulWidget {
  final List<Player> players;
  const CompareScreen({super.key, required this.players});
  @override State<CompareScreen> createState()=>_CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late Player a,b;
  String mode='physical';
  String advanced='none';
  String matchup='auto';
  String query='';

  @override void initState(){
    super.initState();
    a=widget.players.firstWhere((p)=>p.name.toLowerCase().contains('haaland'), orElse:()=>widget.players.first);
    b=widget.players.firstWhere((p)=>p.name.toLowerCase().contains('van dijk'), orElse:()=>widget.players.length>1?widget.players[1]:widget.players.first);
    mode=DuelEngine.autoModeForPositions(a,b);
  }

  void _applyAuto(){ setState(()=>mode=DuelEngine.autoModeForPositions(a,b)); }
  void _applyAdvanced(String v){ setState((){ advanced=v; final m=DuelEngine.advancedModes[v]; if(m!=null && v!='none') mode=m.duelKey; }); }
  void _applyMatchup(String v){ setState((){ matchup=v; final m=DuelEngine.matchups[v]; if(v=='auto'){ mode=DuelEngine.autoModeForPositions(a,b); } else if(m!=null){ mode=m.duelKey; } }); }

  @override Widget build(BuildContext context){
    final filtered=query.isEmpty?widget.players:widget.players.where((p)=>(p.name+p.team+p.pos+p.ovr.toString()).toLowerCase().contains(query.toLowerCase())).toList();
    final result=DuelEngine.compare(a,b,mode);
    final selectedMode=DuelEngine.mode(mode);
    final adv=DuelEngine.advancedModes[advanced];
    final match=DuelEngine.matchups[matchup];
    return ListView(padding:const EdgeInsets.all(14), children:[
      _hero(context, selectedMode, result),
      const SizedBox(height:12),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Recherche joueur, équipe, poste, OVR...', border: OutlineInputBorder()), onChanged:(v)=>setState(()=>query=v)),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:DropdownButtonFormField<String>(value:mode, decoration:const InputDecoration(labelText:'Type de duel', border:OutlineInputBorder()), items:DuelEngine.modes.values.map((m)=>DropdownMenuItem(value:m.key,child:Text(m.label, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>setState(()=>mode=v!))),
        const SizedBox(width:10),
        IconButton(onPressed:_applyAuto, tooltip:'Auto-détection', icon:const Icon(Icons.auto_awesome)),
      ]),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:matchup, decoration:const InputDecoration(labelText:'Poste vs poste', border:OutlineInputBorder()), items:DuelEngine.matchups.values.map((m)=>DropdownMenuItem(value:m.key,child:Text(m.label, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>_applyMatchup(v!)),
      if(match!=null) _infoBox('Lecture matchup', match.advice, match.focus),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:advanced, decoration:const InputDecoration(labelText:'Mode de jeu avancé', border:OutlineInputBorder()), items:DuelEngine.advancedModes.values.map((m)=>DropdownMenuItem(value:m.key,child:Text(m.label, overflow: TextOverflow.ellipsis))).toList(), onChanged:(v)=>_applyAdvanced(v!)),
      if(adv!=null && advanced!='none') _infoBox('Lecture mode avancé', adv.advice, adv.focus),
      const SizedBox(height:12),
      PlayerPicker(title:'Joueur A', players: filtered, value:a, onChanged:(p)=>setState(()=>a=p)),
      PlayerPicker(title:'Joueur B', players: filtered, value:b, onChanged:(p)=>setState(()=>b=p)),
      const SizedBox(height:12),
      _resultCard(context, result),
      const SizedBox(height:12),
      _deepComparison(context, result),
      const SizedBox(height:12),
      _bonusImpact(context),
      const SizedBox(height:12),
      _calculationTable(context, result),
      const SizedBox(height:12),
      TacticalPitch(a:a,b:b,result:result,modeKey:mode),
    ]);
  }

  Widget _hero(BuildContext context, DuelMode selectedMode, result){
    return Container(
      padding:const EdgeInsets.all(18),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(24), gradient:const LinearGradient(colors:[Color(0xFF0B1728),Color(0xFF101F35)])),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Row(children:[const Icon(Icons.sports_soccer, color:Color(0xFF86EFAC)), const SizedBox(width:10), Expanded(child:Text('Duel Engine Pro+', style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900, color:Colors.white))), Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration:BoxDecoration(color:const Color(0x2238BDF8), borderRadius:BorderRadius.circular(99)), child:Text('${result.scoreA} - ${result.scoreB}', style:const TextStyle(color:Color(0xFFBFDBFE),fontWeight:FontWeight.w900)))]),
        const SizedBox(height:8),
        Text(selectedMode.advice, style:const TextStyle(color:Color(0xFFCBD5E1),height:1.35)),
      ]),
    );
  }

  Widget _infoBox(String title, String text, List<String> focus){
    return Container(margin:const EdgeInsets.only(top:10), padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:const Color(0xFFF8FAFC), borderRadius:BorderRadius.circular(16), border:Border.all(color:const Color(0xFFE2E8F0))), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(title, style:const TextStyle(fontWeight:FontWeight.w900)), const SizedBox(height:6), Text(text, style:const TextStyle(height:1.35)),
      if(focus.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8), child:Wrap(spacing:6, runSpacing:6, children:focus.map((x)=>Chip(label:Text(x), visualDensity:VisualDensity.compact)).toList())),
    ]));
  }

  Widget _resultCard(BuildContext context, result){
    return Card(child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(children:[Expanded(child:Text('Résultat du duel', style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900))), const Icon(Icons.analytics_outlined)]),
      const SizedBox(height:10),
      Text('Gagnant probable : ${result.winner}', style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:Color(0xFF16A34A))),
      const SizedBox(height:12),
      Row(children:[Expanded(child:_scoreSide(a.name, result.scoreA, result.percentA, const Color(0xFF2563EB))), const SizedBox(width:10), Expanded(child:_scoreSide(b.name, result.scoreB, 1-result.percentA, const Color(0xFFE11D48)))]),
      const Divider(height:24),
      Text('Diagnostic tactique', style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:6), Text(DuelEngine.tacticalDiagnosis(a,b,result,mode), style:const TextStyle(height:1.45)),
    ])));
  }

  Widget _scoreSide(String name, int score, double pct, Color color){
    return Container(padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:color.withOpacity(.08), borderRadius:BorderRadius.circular(16)), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(name, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w800)),
      const SizedBox(height:8), Text('$score pts', style:TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:color)),
      const SizedBox(height:8), ClipRRect(borderRadius:BorderRadius.circular(99), child:LinearProgressIndicator(value:pct.clamp(0.0,1.0), minHeight:10, color:color, backgroundColor:color.withOpacity(.15))),
    ]));
  }

  Widget _deepComparison(BuildContext context, result){
    final diffs=DuelEngine.statDiffs(a,b,mode).take(16).toList();
    return Card(child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text('Comparaison détaillée', style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:12),
      GridView.count(crossAxisCount:2, shrinkWrap:true, physics:const NeverScrollableScrollPhysics(), mainAxisSpacing:8, crossAxisSpacing:8, childAspectRatio:2.5, children:[
        _profileTile('Taille','${a.height} cm','${b.height} cm'), _profileTile('Poids','${a.weight} kg','${b.weight} kg'), _profileTile('Body Type',a.bodyType,b.bodyType), _profileTile('AcceleRATE',a.accelerate,b.accelerate),
      ]),
      const SizedBox(height:14),
      ...diffs.map((d)=>_diffRow(d)).toList(),
    ])));
  }

  Widget _profileTile(String label, String av, String bv){
    return Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:const Color(0xFFF8FAFC), borderRadius:BorderRadius.circular(14), border:Border.all(color:const Color(0xFFE2E8F0))), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(label, style:const TextStyle(fontSize:11,color:Colors.black54)), const Spacer(), Text(av, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w900)), Text('vs $bv', maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontSize:11,color:Colors.black54))]));
  }

  Widget _diffRow(StatDiff d){
    final color=d.diff>=0?const Color(0xFF2563EB):const Color(0xFFE11D48);
    final val=(d.diff>=0?d.a:d.b).clamp(0,100)/100;
    return Padding(padding:const EdgeInsets.symmetric(vertical:5), child:Row(children:[
      SizedBox(width:118, child:Text(d.label, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w700))),
      SizedBox(width:32, child:Text('${d.a}', textAlign:TextAlign.center)),
      Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(99), child:LinearProgressIndicator(value:val, minHeight:9, color:color, backgroundColor:const Color(0xFFE2E8F0)))),
      SizedBox(width:32, child:Text('${d.b}', textAlign:TextAlign.center)),
      SizedBox(width:42, child:Text('${d.diff>0?'+':''}${d.diff}', textAlign:TextAlign.end, style:TextStyle(fontWeight:FontWeight.w900,color: d.diff.abs()<3?Colors.black54:color))),
    ]));
  }

  Widget _bonusImpact(BuildContext context){
    final m=DuelEngine.mode(mode);
    final ba=DuelEngine.profileBonuses(a,m.profile);
    final bb=DuelEngine.profileBonuses(b,m.profile);
    return Card(child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text('Impact PlayStyles + profil', style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:10), Row(crossAxisAlignment:CrossAxisAlignment.start, children:[Expanded(child:_bonusList(a.name, ba)), const SizedBox(width:10), Expanded(child:_bonusList(b.name, bb))]),
    ])));
  }

  Widget _bonusList(String name, List<ProfileBonus> rows){
    return Container(padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:const Color(0xFFF8FAFC), borderRadius:BorderRadius.circular(16)), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(name, maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w900)), const SizedBox(height:8),
      if(rows.isEmpty) const Text('Aucun bonus fort dans ce mode.'),
      ...rows.map((r)=>Padding(padding:const EdgeInsets.only(bottom:6), child:Text('${r.value>0?'+':''}${r.value} ${r.label} — ${r.why}', style:TextStyle(color:r.value>=0?const Color(0xFF15803D):const Color(0xFFE11D48))))),
    ]));
  }

  Widget _calculationTable(BuildContext context, result){
    final m=DuelEngine.mode(mode);
    return Card(child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text('Détail du calcul pondéré', style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      Table(columnWidths:const {0:FlexColumnWidth(1.5),1:FlexColumnWidth(.7),2:FlexColumnWidth(.7),3:FlexColumnWidth(.7)}, children:[
        const TableRow(children:[Padding(padding:EdgeInsets.all(6), child:Text('Facteur', style:TextStyle(fontWeight:FontWeight.w900))), Padding(padding:EdgeInsets.all(6), child:Text('A', textAlign:TextAlign.center, style:TextStyle(fontWeight:FontWeight.w900))), Padding(padding:EdgeInsets.all(6), child:Text('B', textAlign:TextAlign.center, style:TextStyle(fontWeight:FontWeight.w900))), Padding(padding:EdgeInsets.all(6), child:Text('Poids', textAlign:TextAlign.center, style:TextStyle(fontWeight:FontWeight.w900)))]),
        ...m.weights.entries.map((e)=>TableRow(children:[Padding(padding:const EdgeInsets.all(6), child:Text(DuelEngine.statLabels[e.key]??e.key)), Padding(padding:const EdgeInsets.all(6), child:Text('${a.s[e.key]??0}', textAlign:TextAlign.center)), Padding(padding:const EdgeInsets.all(6), child:Text('${b.s[e.key]??0}', textAlign:TextAlign.center)), Padding(padding:const EdgeInsets.all(6), child:Text('${(e.value*100).round()}%', textAlign:TextAlign.center))])),
      ]),
      const Divider(), Text('Stats pondérées: ${result.coreA} vs ${result.coreB}  •  Bonus profil/playstyles: ${result.bonusA} vs ${result.bonusB}'),
    ])));
  }
}
