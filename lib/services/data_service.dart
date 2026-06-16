import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class DataService {
  static const _customKey = 'fc24_custom_players';

  Future<List<Player>> loadPlayers() async {
    final raw = await rootBundle.loadString('assets/data/fc24-real-data.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final base = (data['players'] as List).map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getString(_customKey);
    if (customRaw != null) {
      final custom = (jsonDecode(customRaw) as List).map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
      base.insertAll(0, custom);
    }
    base.sort((a,b) => b.ovr.compareTo(a.ovr));
    return base;
  }

  Future<void> saveCustomPlayer(Player p) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    final list = raw == null ? <Map<String,dynamic>>[] : (jsonDecode(raw) as List).cast<Map<String,dynamic>>();
    list.removeWhere((e) => '${e['id']}' == p.id);
    list.add(p.toJson());
    await prefs.setString(_customKey, jsonEncode(list));
  }

  Player importFromUrlNameOnly(String url) {
    final sofifa = RegExp(r'sofifa\.com/player/(\d+)/([^/]+)/(\d+)').firstMatch(url);
    final fifaIndex = RegExp(r'fifaindex\.com/player/(\d+)/([^/]+)').firstMatch(url);
    final id = sofifa?.group(1) ?? fifaIndex?.group(1) ?? DateTime.now().millisecondsSinceEpoch.toString();
    final slug = sofifa?.group(2) ?? fifaIndex?.group(2) ?? 'custom-player';
    final name = slug.split('-').where((x)=>x.isNotEmpty).map((w)=>w[0].toUpperCase()+w.substring(1)).join(' ');
    return Player(id: 'import_$id', name: name, team: 'Imported', pos: 'ST', ovr: 80, height: 180, weight: 75, bodyType: 'Average', accelerate: 'Controlled', foot: 'Right', playStyles: const [], s: const {
      'pac':75,'sho':75,'pas':75,'dri':75,'def':55,'phy':75,'acc':75,'sprint':75,'str':75,'agg':70,'bal':75,'agi':75,'react':75,'ball':75,'drib':75,'defaw':55,'tackle':55,'inter':55,'finish':75,'shot':75,'comp':75,'stam':75,'jump':75,'head':75,'cross':70,'shortp':75,'longp':70,'vision':75
    });
  }
}
