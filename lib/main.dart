// ============================================================
// 資本主義ゲーム - エントリポイント
// GDD §17.1 / §17.3 準拠
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'domain/models/event_definition.dart';
import 'domain/services/master_data_loader.dart';
import 'presentation/providers/game_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 初期化（Web=IndexedDB / Mobile=端末ローカル）
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    await Hive.initFlutter('capitalism_game');
  }

  // マスターデータ事前ロード（events.json / achievements.json 等）
  final loader = MasterDataLoader();
  final master = await loader.load();

  // events.json → EventDefinition 配列に変換
  final events = master.events
      .map(EventDefinition.fromJson)
      .toList();

  runApp(
    ProviderScope(
      overrides: [
        eventDefinitionsProvider.overrideWith((ref) => events),
      ],
      child: const CapitalismGameApp(),
    ),
  );
}
