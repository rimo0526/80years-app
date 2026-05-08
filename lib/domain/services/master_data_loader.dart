// ============================================================
// マスターデータ読込 / GDD §18.1 / §18.2
// events.json / achievements.json / master_skills.json 等を起動時に読み込む
// ============================================================
import 'dart:convert';

import 'package:flutter/services.dart';

class MasterData {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> achievements;
  final List<Map<String, dynamic>> skills;
  final Map<String, dynamic> eraParameters;
  final Map<String, dynamic> economyConstants;

  const MasterData({
    this.events = const [],
    this.achievements = const [],
    this.skills = const [],
    this.eraParameters = const {},
    this.economyConstants = const {},
  });
}

/// 起動時に1回だけ呼び出して、全マスターデータを読み込む
class MasterDataLoader {
  Future<MasterData> load() async {
    final events = await _loadList('assets/data/events.json', 'events');
    final achievements =
        await _loadList('assets/data/achievements.json', 'achievements');
    final skills = await _loadList('assets/data/master_skills.json', 'skills');
    final eras = await _loadMap('assets/data/era_parameters.json');
    final economy = await _loadMap('assets/data/economy_constants.json');

    return MasterData(
      events: events,
      achievements: achievements,
      skills: skills,
      eraParameters: eras,
      economyConstants: economy,
    );
  }

  Future<List<Map<String, dynamic>>> _loadList(String path, String key) async {
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json[key] as List?) ?? const [];
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (_) {
      // 開発初期はファイル未配置でもクラッシュしないよう空を返す
      return const [];
    }
  }

  Future<Map<String, dynamic>> _loadMap(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }
}
