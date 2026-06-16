import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/duel.dart';

class TacticalPitch extends StatefulWidget {
  final Player a;
  final Player b;
  final DuelResult result;
  final String modeKey;
  const TacticalPitch({super.key, required this.a, required this.b, required this.result, required this.modeKey});
  @override State<TacticalPitch> createState()=>_TacticalPitchState();
}
class _TacticalPitchState extends State<TacticalPitch> with SingleTickerProviderStateMixin {
  late final AnimationController c;
  @override void initState(){ super.initState(); c=AnimationController(vsync:this,duration:const Duration(milliseconds:1700))..forward(); }
  @override void didUpdateWidget(covariant TacticalPitch oldWidget){ super.didUpdateWidget(oldWidget); c.forward(from:0); }
  @override void dispose(){ c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context)=>Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Text('Terrain animé', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height:10),
    AspectRatio(aspectRatio: 1.65, child: AnimatedBuilder(animation:c, builder:(_,__)=>CustomPaint(painter: PitchPainter(c.value, widget.a, widget.b, widget.result, widget.modeKey)))),
    const SizedBox(height:8), Text('Gagnant animation : ${widget.result.winner}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF86EFAC)))
  ])));
}

class PitchPainter extends CustomPainter {
  final double t; final Player a,b; final DuelResult result; final String modeKey;
  PitchPainter(this.t,this.a,this.b,this.result,this.modeKey);
  @override void paint(Canvas canvas, Size size){
    final field=Paint()..color=const Color(0xFF146C43); canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero&size,const Radius.circular(20)), field);
    final line=Paint()..color=Colors.white.withOpacity(.65)..style=PaintingStyle.stroke..strokeWidth=2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18,18,size.width-36,size.height-36), const Radius.circular(14)), line);
    canvas.drawLine(Offset(size.width/2,18),Offset(size.width/2,size.height-18),line);
    canvas.drawCircle(Offset(size.width/2,size.height/2), size.height*.12, line);
    canvas.drawRect(Rect.fromLTWH(18,size.height*.28,size.width*.14,size.height*.44), line);
    canvas.drawRect(Rect.fromLTWH(size.width-size.width*.14-18,size.height*.28,size.width*.14,size.height*.44), line);
    final sc = _scenario();
    Offset lerp(Offset x, Offset y)=>Offset.lerp(x,y,t)!;
    final aPos=lerp(_p(size, sc.a1), _p(size, sc.a2)); final bPos=lerp(_p(size, sc.b1), _p(size, sc.b2)); final ball=lerp(_p(size, sc.ball1), _p(size, sc.ball2));
    final run=Paint()..color=Colors.amber..strokeWidth=3..style=PaintingStyle.stroke; canvas.drawLine(_p(size, sc.a1), _p(size, sc.a2), run);
    final pass=Paint()..color=Colors.lightBlueAccent..strokeWidth=3..style=PaintingStyle.stroke; canvas.drawLine(_p(size, sc.ball1), _p(size, sc.ball2), pass);
    _drawPlayer(canvas, aPos, Colors.lightBlueAccent, a.name.substring(0, a.name.length>1?2:1).toUpperCase(), result.winner==a.name);
    _drawPlayer(canvas, bPos, Colors.pinkAccent, b.name.substring(0, b.name.length>1?2:1).toUpperCase(), result.winner==b.name);
    canvas.drawCircle(ball, 8, Paint()..color=Colors.white);
  }
  Offset _p(Size s, Offset pct)=>Offset(s.width*pct.dx/100, s.height*pct.dy/100);
  void _drawPlayer(Canvas c, Offset p, Color color, String label, bool win){
    final paint=Paint()..color=color; if(win && t>.92){ c.drawCircle(p, 34, Paint()..color=const Color(0xFF22C55E).withOpacity(.25)); }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:p,width:46,height:46), const Radius.circular(15)), paint);
    final tp=TextPainter(text:TextSpan(text:label,style:const TextStyle(color:Colors.black,fontWeight:FontWeight.w900)), textDirection:TextDirection.ltr)..layout(); tp.paint(c, p-Offset(tp.width/2,tp.height/2));
  }
  _Scenario _scenario(){
    if(modeKey.contains('press')) return _Scenario(const Offset(40,52),const Offset(50,50),const Offset(58,50),const Offset(50,50),const Offset(58,55),const Offset(50,53));
    if(modeKey.contains('inter')) return _Scenario(const Offset(34,58),const Offset(34,58),const Offset(58,48),const Offset(50,50),const Offset(36,58),const Offset(64,43));
    if(modeKey.contains('aerial')) return _Scenario(const Offset(62,38),const Offset(72,47),const Offset(70,52),const Offset(72,47),const Offset(36,78),const Offset(72,47));
    if(modeKey.contains('speed')) return _Scenario(const Offset(38,48),const Offset(78,40),const Offset(52,50),const Offset(74,42),const Offset(35,58),const Offset(78,40));
    return _Scenario(const Offset(38,55),const Offset(62,48),const Offset(55,52),const Offset(58,50),const Offset(39,58),const Offset(62,50));
  }
  @override bool shouldRepaint(covariant PitchPainter oldDelegate)=>true;
}
class _Scenario{final Offset a1,a2,b1,b2,ball1,ball2; const _Scenario(this.a1,this.a2,this.b1,this.b2,this.ball1,this.ball2);}
