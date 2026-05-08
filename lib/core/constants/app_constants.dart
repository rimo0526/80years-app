// ============================================================
// 定数集約（GDD §1.2 用語集 / §18.4.1 schema_version）
// ============================================================

/// セーブデータスキーマバージョン（GDD §18.4）
/// 値を上げる場合は migration 関数も追加すること
const int kSchemaVersion = 1;

/// 最大年齢（GDD §11.1.4）
const int kMaxAgeNormal = 115;
const int kMaxAgeWithImmortal = 130;

/// 1キャラあたりの最大ターン数（80年×12=960）
const int kMaxTurns = 960;
const int kMaxAgeYears = 80; // 標準の人生上限（早死に含めなければ）

/// 家系で詳細保持する世代数（GDD §11.5.7）
const int kFamilyDetailGenerations = 10;

/// セーブファイル名（モバイル）
const String kSaveFileName = 'save.json';
const String kSaveBackupFileName = 'save.bak.json';
const String kHiveBoxName = 'capitalism_save_v1';
