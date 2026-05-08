// ============================================================
// Web版セーブ実装（Hive on IndexedDB） / GDD §17.2.1 Phase 1
// ============================================================
import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/game_save_data.dart';
import '../../domain/services/save_repository.dart';

class WebSaveRepository implements SaveRepository {
  static const String _mainKey = 'main';
  static const String _backupKey = 'main_bak';

  Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(kHiveBoxName)) {
      return Hive.box<String>(kHiveBoxName);
    }
    return Hive.openBox<String>(kHiveBoxName);
  }

  @override
  Future<GameSaveData?> load() async {
    final box = await _box();
    final encoded = box.get(_mainKey);
    if (encoded == null || encoded.isEmpty) return null;

    final data = SaveCodec.decode(encoded);
    if (data != null) return data;

    // メインが破損 → バックアップから復元
    return restoreFromBackup().then((ok) async {
      if (!ok) return null;
      final encoded2 = (await _box()).get(_mainKey);
      if (encoded2 == null) return null;
      return SaveCodec.decode(encoded2);
    });
  }

  @override
  Future<void> save(GameSaveData data) async {
    final box = await _box();
    // 書込前に現在のメインをバックアップに退避
    final current = box.get(_mainKey);
    if (current != null && current.isNotEmpty) {
      await box.put(_backupKey, current);
    }
    final encoded = SaveCodec.encode(data);
    await box.put(_mainKey, encoded);
  }

  @override
  Future<String> export() async {
    final data = await load();
    if (data == null) return '';
    return SaveCodec.exportPlain(data);
  }

  @override
  Future<void> import(String jsonString) async {
    final data = SaveCodec.importPlain(jsonString);
    if (data == null) {
      throw const FormatException('Invalid save data format');
    }
    await save(data);
  }

  @override
  Future<void> clear() async {
    final box = await _box();
    await box.delete(_mainKey);
    await box.delete(_backupKey);
  }

  @override
  Future<bool> restoreFromBackup() async {
    final box = await _box();
    final bak = box.get(_backupKey);
    if (bak == null || bak.isEmpty) return false;
    await box.put(_mainKey, bak);
    return true;
  }
}
