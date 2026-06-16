import 'package:flutter/material.dart';
import '../models/player.dart';
import 'compare_screen.dart';
import 'detector_screen.dart';
import 'players_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Player> players;
  const HomeScreen({super.key, required this.players});
  @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int i=0;
  @override Widget build(BuildContext context) {
    final pages=[CompareScreen(players: widget.players), DetectorScreen(players: widget.players), PlayersScreen(players: widget.players)];
    return Scaffold(
      appBar: AppBar(title: const Text('FC24 Coach AI'), actions:[Padding(padding:const EdgeInsets.all(12), child: Center(child: Text('${widget.players.length} joueurs')))]),
      body: pages[i],
      bottomNavigationBar: NavigationBar(selectedIndex:i,onDestinationSelected:(v)=>setState(()=>i=v),destinations: const [
        NavigationDestination(icon: Icon(Icons.sports_soccer), label: 'Comparer'),
        NavigationDestination(icon: Icon(Icons.trending_up), label: 'Plus forts'),
        NavigationDestination(icon: Icon(Icons.people), label: 'Joueurs'),
      ]),
    );
  }
}
