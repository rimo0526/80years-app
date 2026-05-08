// ============================================================
// セーブデータ全体 / GDD §18.3 セーブデータJSONスキーマ準拠
// 5ブロック構造：character / family / achievements / settings / statistics
// ============================================================
import '../../core/constants/app_constants.dart';
import 'character.dart';
import 'family.dart';
import 'achievements_data.dart';
import 'settings_data.dart';
import 'statistics_data.dart';

class GameSaveData {
  final int schemaVersion;
  final String savedAt;       // ISO 8601
  final String? checksum;     // SHA-256（GDD §18.5）

  final Character? character; // null=未開始
  final Family family;
  final AchievementsData achievements;
  final SettingsData settings;
  final StatisticsData statistics;

  const GameSaveData({
    this.schemaVersion = kSchemaVersion,
    required this.savedAt,
    this.checksum,
    this.character,
    this.family = const Family(),
    this.achievements = const AchievementsData(),
    this.settings = const SettingsData(),
    this.statistics = const StatisticsData(),
  });

  GameSaveData copyWith({
    int? schemaVersion,
    String? savedAt,
    String? checksum,
    Character? character,
    bool clearCharacter = false,
    Family? family,
    AchievementsData? achievements,
    SettingsData? settings,
    StatisticsData? statistics,
  }) {
    return GameSaveData(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      savedAt: savedAt ?? this.savedAt,
      checksum: checksum ?? this.checksum,
      character: clearCharacter ? null : (character ?? this.character),
      family: family ?? this.family,
      achievements: achievements ?? this.achievements,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
    );
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'saved_at': savedAt,
        if (checksum != null) 'checksum': checksum,
        if (character != null) 'character': character!.toJson(),
        'family': family.toJson(),
        'achievements': achievements.toJson(),
        'settings': settings.toJson(),
        'statistics': statistics.toJson(),
      };

  factory GameSaveData.fromJson(Map<String, dynamic> j) {
    return GameSaveData(
      schemaVersion: (j['schema_version'] ?? kSchemaVersion) as int,
      savedAt: (j['saved_at'] ?? DateTime.now().toIso8601String()) as String,
      checksum: j['checksum'] as String?,
      character: j['character'] == null
          ? null
          : Character.fromJson((j['character'] as Map).cast<String, dynamic>()),
      family: Family.fromJson(
          (j['family'] as Map?)?.cast<String, dynamic>() ?? {}),
      achievements: AchievementsData.fromJson(
          (j['achievements'] as Map?)?.cast<String, dynamic>() ?? {}),
      settings: SettingsData.fromJson(
          (j['settings'] as Map?)?.cast<String, dynamic>() ?? {}),
      statistics: StatisticsData.fromJson(
          (j['statistics'] as Map?)?.cast<String, dynamic>() ?? {}),
    );
  }

  /// 新規セーブ（初回起動時）
  factory GameSaveData.fresh() {
    return GameSaveData(savedAt: DateTime.now().toIso8601String());
  }
}

// ============================================================
// マイグレーション関数（GDD §18.4.2）
// schema_version が上がるたびに以下の関数を追加
// ============================================================

typedef MigrationFn = Map<String, dynamic> Function(Map<String, dynamic>);

/// バージョン別のマイグレーション関数表
/// 例：v1 → v2 への移行は migrationFunctions[1] を使う
final Map<int, MigrationFn> migrationFunctions = {
  // 現在は v1 のみ。将来 v2 が出たらここに追加：
  // 1: (data) {
  //   data['character']?['household']?['investments']?['crypto'] ??= 0;
  //   data['schema_version'] = 2;
  //   return data;
  // },
};

/// マイグレーションを実行して最新スキーマに更新
Map<String, dynamic> migrate(Map<String, dynamic> json) {
  var data = Map<String, dynamic>.from(json);
  var version = (data['schema_version'] ?? 1) as int;

  while (version < kSchemaVersion) {
    final fn = migrationFunctions[version];
    if (fn == null) {
      // マイグレーション関数が無い → エラー扱い
      throw StateError(
          'No migration function for schema version $version → ${version + 1}');
    }
    data = fn(data);
    version = (data['schema_version'] ?? version + 1) as int;
  }
  return data;
}
