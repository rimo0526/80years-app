// ============================================================
// セーブリポジトリ抽象クラス / GDD §17.3.2 最重要レイヤー
//
// このレイヤーの存在意義：
//  - Web (Hive/IndexedDB) と Mobile (path_provider/JSON file) の差異を吸収
//  - エクスポート/インポート機能でクラウド同期なしのプラットフォーム間移行
//  - 「後から乗り換えられない構造を作らない」の中核
// ============================================================
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import '../models/game_save_data.dart';

abstract class SaveRepository {
  /// セーブデータをロード（無ければ null）
  Future<GameSaveData?> load();

  /// セーブデータを保存（書込前に save.bak としてバックアップ）
  Future<void> save(GameSaveData data);

  /// JSON文字列としてエクスポート（GDD §17.3.3 セーブ移行）
  Future<String> export();

  /// JSON文字列からインポート（プラットフォーム間の移行用）
  Future<void> import(String jsonString);

  /// セーブデータを完全削除
  Future<void> clear();

  /// バックアップから復元（メイン破損時の救済）
  Future<bool> restoreFromBackup();
}

/// セーブのシリアライズ/暗号化処理（GDD §18.5）
/// Web/Mobile 実装で共通利用
class SaveCodec {
  /// 改ざん防止用の固定キー（XOR用）
  /// プロダクションでは難読化を増やす
  static const int _xorKey = 0x5A;

  /// JSON → 保存形式へエンコード
  /// GDD §18.5.3 の流れ：
  /// 1. JSON 文字列を作る
  /// 2. checksum（SHA-256）を計算してフィールドに含める
  /// 3. XOR で軽く難読化
  /// 4. Base64
  static String encode(GameSaveData data) {
    // checksum 計算用に checksum 抜きの安定ハッシュ用 JSON を作る
    final mapNoChecksum = data.toJson()..remove('checksum');
    final stableForHash = _stableJsonEncode(mapNoChecksum);
    final checksum = _sha256Hex(stableForHash);

    // checksum を含めて再エンコード
    final withChecksum = data.copyWith(checksum: checksum);
    final fullJson = _stableJsonEncode(withChecksum.toJson());

    // XOR したバイト列を Base64 にエンコード（UTF-8 往復は破損するため不可）
    final jsonBytes = utf8.encode(fullJson);
    final xored = _xorByteList(jsonBytes);
    return base64Encode(xored);
  }

  /// 保存形式 → JSON にデコード
  static GameSaveData? decode(String encoded) {
    try {
      final xored = base64Decode(encoded);
      final jsonBytes = _xorByteList(xored);
      final raw = utf8.decode(jsonBytes);
      final dynamic parsed = json.decode(raw);
      if (parsed is! Map) return null;
      final jsonMap = parsed.cast<String, dynamic>();

      // checksum 検証
      final claimed = jsonMap['checksum'] as String?;
      final copy = Map<String, dynamic>.from(jsonMap)..remove('checksum');
      final computed = _sha256Hex(_stableJsonEncode(copy));
      if (claimed != null && claimed != computed) {
        // 改ざん検知 → 破損として扱う
        return null;
      }

      // マイグレーション
      final migrated = migrate(jsonMap);
      return GameSaveData.fromJson(migrated);
    } catch (_) {
      return null;
    }
  }

  /// 平文 JSON エクスポート（QRコード/手動コピー向け）
  static String exportPlain(GameSaveData data) {
    return _stableJsonEncode(data.toJson());
  }

  /// 平文 JSON インポート
  static GameSaveData? importPlain(String jsonString) {
    try {
      final dynamic parsed = json.decode(jsonString);
      if (parsed is! Map) return null;
      final jsonMap = parsed.cast<String, dynamic>();
      final migrated = migrate(jsonMap);
      return GameSaveData.fromJson(migrated);
    } catch (_) {
      return null;
    }
  }

  // ----- 内部実装 -----

  /// バイト列に XOR を適用（往復可能、UTF-8 経由しない）
  static List<int> _xorByteList(List<int> bytes) {
    final out = List<int>.filled(bytes.length, 0);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ _xorKey;
    }
    return out;
  }

  /// 安定した JSON エンコード（キー順固定でハッシュ計算が一貫するように）
  static String _stableJsonEncode(Map<String, dynamic> map) {
    return json.encode(_sortMap(map));
  }

  static dynamic _sortMap(dynamic v) {
    if (v is Map) {
      final sorted = <String, dynamic>{};
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      for (final k in keys) {
        sorted[k] = _sortMap(v[k]);
      }
      return sorted;
    } else if (v is List) {
      return v.map(_sortMap).toList();
    }
    return v;
  }

  static String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    return crypto.sha256.convert(bytes).toString();
  }
}
