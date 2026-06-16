import 'package:flutter/material.dart';
import 'models/player.dart';
import 'services/data_service.dart';
import 'screens/home_screen.dart';

void main() => runApp(const Fc24CoachApp());

class Fc24CoachApp extends StatelessWidget {
  const Fc24CoachApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FC24 Coach AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06101D),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E), brightness: Brightness.dark),
        useMaterial3: true,
        cardTheme: CardThemeData(color: const Color(0xFF0B1728), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      ),
      home: const Bootstrap(),
    );
  }
}

class Bootstrap extends StatefulWidget { const Bootstrap({super.key}); @override State<Bootstrap> createState()=>_BootstrapState(); }
class _BootstrapState extends State<Bootstrap> {
  late Future<List<Player>> _future;
  @override void initState(){ super.initState(); _future = DataService().loadPlayers(); }
  @override Widget build(BuildContext context){
    return FutureBuilder<List<Player>>(
      future: _future,
      builder: (_, snap){
        if(!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return HomeScreen(players: snap.data!);
      },
    );
  }
}
