// ============================================================
// Mobile版セーブ実装（path_provider + JSON ファイル） / GDD §17.2.1 Phase 2-3
// ============================================================
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/game_save_data.dart';
import '../../domain/services/save_repository.dart';

class MobileSaveRepository implements SaveRepository {
  Future<Directory> _baseDir() async {
    return getApplicationDocumentsDirectory();
  }

  Future<File> _mainFile() async {
    final dir = await _baseDir();
    return File('${dir.path}/$kSaveFileName');
  }

  Future<File> _backupFile() async {
    final dir = await _baseDir();
    return File('${dir.path}/$kSaveBackupFileName');
  }

  @override
  Future<GameSaveData?> load() async {
    final file = await _mainFile();
    if (!await file.exists()) return null;
    final encoded = await file.readAsString();
    if (encoded.isEmpty) return null;

    final data = SaveCodec.decode(encoded);
    if (data != null) return data;

    // 破損時は backup から復元を試みる
    if (await restoreFromBackup()) {
      final f2 = await _mainFile();
      if (await f2.exists()) {
        return SaveCodec.decode(await f2.readAsString());
      }
    }
    return null;
  }

  @override
  Future<void> save(GameSaveData data) async {
    final mainFile = await _mainFile();
    final bakFile = await _backupFile();

    // 既存メインを backup に退避
    if (await mainFile.exists()) {
      try {
        final old = await mainFile.readAsString();
        await bakFile.writeAsString(old, flush: true);
      } catch (_) {
        // バックアップ失敗しても本体保存は続行
      }
    }

    final encoded = SaveCodec.encode(data);
    await mainFile.writeAsString(encoded, flush: true);
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
    final mainFile = await _mainFile();
    final bakFile = await _backupFile();
    if (await mainFile.exists()) await mainFile.delete();
    if (await bakFile.exists()) await bakFile.delete();
  }

  @override
  Future<bool> restoreFromBackup() async {
    final mainFile = await _mainFile();
    final bakFile = await _backupFile();
    if (!await bakFile.exists()) return false;
    final content = await bakFile.readAsString();
    if (content.isEmpty) return false;
    await mainFile.writeAsString(content, flush: true);
    return true;
  }
}
