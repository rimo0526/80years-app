# 資本主義ゲーム — Flutter プロジェクト

スマホ向け人生シミュレーション・ローグライクゲーム「資本主義ゲーム」の Flutter 実装。

GDD（Game Design Document）：`../GDD本体.md`（v1.2）

## プロジェクト概要

- **言語**：Dart 3.x / Flutter 3.x
- **状態管理**：Riverpod
- **画面遷移**：go_router
- **永続化**：Hive（Web）/ path_provider（Mobile）
- **マネタイズ**：広告のみ（Phase 1〜で AdMob/AdSense 統合）
- **運営方針**：基本無料運営（GDD §15.1.0、月運営費 0円〜数千円）

## セットアップ手順

```bash
# 1. Flutter SDK インストール（未導入なら）
#    https://docs.flutter.dev/get-started/install

# 2. 依存解決
flutter pub get

# 3. コード生成（json_serializable 等）— 現状はスケルトンのため不要
# flutter pub run build_runner build --delete-conflicting-outputs

# 4. Web で動作確認
flutter run -d chrome

# 5. Android で動作確認（実機/エミュレータ）
flutter run -d <device-id>

# 6. テスト
flutter test
```

## ディレクトリ構造（GDD §17.4 準拠）

```
app_flutter/
├── pubspec.yaml             # 依存パッケージ定義
├── analysis_options.yaml    # 静的解析ルール
├── lib/
│   ├── main.dart            # エントリポイント
│   ├── app/
│   │   ├── app.dart         # MaterialApp.router 起動部
│   │   ├── router.dart      # go_router 設定（22画面のルート定義）
│   │   └── theme.dart       # 13色パレット → ThemeData
│   ├── core/                # 横断ユーティリティ
│   │   ├── constants/       # app_constants.dart, enums.dart
│   │   ├── utils/           # ヘルパー関数
│   │   └── extensions/      # 拡張メソッド
│   ├── domain/              # ゲームロジック（Flutter依存なしの純粋Dart）
│   │   ├── models/          # Character, Family, GameSaveData 等
│   │   ├── engines/         # GameEngine, EconomyEngine 等
│   │   └── services/        # SaveRepository（抽象）, MasterDataLoader
│   ├── data/                # 実装層
│   │   ├── repositories/    # SaveRepository の Web/Mobile 実装
│   │   └── sources/         # codec_io.dart など
│   └── presentation/        # UI層
│       ├── screens/         # title, character_create, main_game, ending
│       ├── widgets/         # 共通ウィジェット（Phase 1 で追加）
│       └── providers/       # Riverpod プロバイダー
├── assets/
│   ├── data/                # JSONマスターデータ（events.json 等）
│   ├── fonts/
│   ├── images/
│   └── sounds/
├── test/                    # ユニット・統合テスト
└── web/                     # Flutter Web 用エントリ（flutter create で自動生成）
```

## Phase 0 進捗チェックリスト

### ✅ 完了（Phase 0 + Phase 1 序盤＋中盤＋終盤準備）
- [x] プロジェクト初期化（pubspec.yaml、analysis_options.yaml）
- [x] 起動部（main.dart, app.dart, router.dart, theme.dart）
- [x] カラーパレット13色のCSS変数→ThemeData変換
- [x] 列挙型（Gender, AbilityKind, ResultKind, Era, LifePhase, SkillTree）
- [x] ドメインモデル（Character, Family, Achievements, Settings, Statistics, GameSaveData, EventDefinition, AchievementDefinition）
- [x] **セーブ抽象化レイヤー**（SaveRepository 抽象 + Web/Mobile 実装 + Factory）
- [x] **改ざん防止コーデック**（SaveCodec：SHA-256 checksum + XOR + Base64）
- [x] **マイグレーション関数のひな形**（schema_version 管理）
- [x] GameEngine 本実装（6段階月次フロー、動的寿命 v1.1、ストレス／幸福度／スキルpt）
- [x] EconomyEngine 本実装（投資7商品、住宅ローン、破産判定、時代別物価）
- [x] EventResolver 本実装（発火優先順位、クールダウン、連鎖、運／強み補正）
- [x] EffectParser（自由テキスト→構造化）
- [x] ParentRoller（4階層レアリティ、特殊レア4種、時代係数）
- [x] CharacterFactory（draft → Character 生成）
- [x] HUD / ActionPanel / EventModal ウィジェット
- [x] AvatarPicker / AvatarPreview（4,608通りの顔パーツUI）
- [x] ConsentDialog（同意UI / CMP 簡易版）
- [x] Riverpod プロバイダー集約（eventDefinitions, gameEngine, character, charDraft）
- [x] events.json / achievements.json 起動時ロード
- [x] 5画面（タイトル/作成5ステップ/メイン/エンディング）統合済
- [x] テスト6本：save_repository, event_resolver, economy_engine, game_engine, effect_parser, parent_roller
- [x] integration_test 2本：save_persistence, full_game
- [x] AIシミュレーション基盤（lib/dev/sim_runner.dart、CSV出力）
- [x] AdSense 雛形（web/index.html）
- [x] DEPLOY_PHASE1.md（GitHub Pages 配信手順）

### 🔧 Phase 1 GA で対応する事項
- [ ] events_database.xlsx → events.json への変換スクリプト（Python）
- [ ] achievements_database.xlsx → achievements.json への変換
- [ ] master_skills.json の手動作成（70ノード）
- [ ] era_parameters.json / economy_constants.json の作成
- [ ] GameEngine の月次ターン本格実装（収支計算・イベント発火）
- [ ] HUD ウィジェット（年齢・ステータス5+5・所持金）
- [ ] アクション選択UI
- [ ] イベントモーダル
- [ ] 顔パーツ組合せUI（8×6×6×4×4 = 4,608通り）
- [ ] 親ガチャの抽選ロジック
- [ ] 墓標画像生成（RepaintBoundary、1.91:1 + 1:1）
- [ ] SNS共有（share_plus 統合）
- [ ] 同意UI（CMP）
- [ ] AdSense 統合（Web）
- [ ] テスト（ユニット＋統合）

### 📋 Phase 2 以降
- [ ] AdMob 統合（Android）
- [ ] Firebase Analytics + Crashlytics
- [ ] iOS 対応・ATT 実装
- [ ] AI楽曲制作（Suno等で外注比90%減）
- [ ] AIシミュレーション（バランス検証）

## 設計方針

### セーブ抽象化レイヤー（最重要）
GDD §17.3.2 に基づき、Phase 0 から導入。Web（Hive/IndexedDB）と Mobile（path_provider/JSON）の差異を完全に吸収する `SaveRepository` 抽象クラスを設置。

**特徴**：
- バックアップ機能（書込前に `save.bak` へ退避）
- 改ざん検知（SHA-256 checksum）
- 軽量難読化（XOR + Base64）
- マイグレーション（schema_version 管理）
- エクスポート/インポート（プラットフォーム間移行用）

### コンテンツポリシー（GDD §2.2.3）
- 自殺・自傷を扱わない（死亡演出は加齢・病気・事故・寿命のみ）
- センシティブ題材は婉曲表現で（events_database.xlsx v2.1 で対応済）
- 実在の人物・企業を中傷しない

### 時代固定方式（GDD §7.1.1 v1.2）
選んだ時代の世界観が80年間ずっと続く「並行世界」方式。`Era` 列挙型で4時代を管理。

## 関連ドキュメント

| ドキュメント | 用途 |
|---|---|
| `../GDD本体.md` | 唯一の正典仕様書（v1.2） |
| `../GDD_章立て.md` | 全21章＋付録の目次 |
| `../アプリ化_想定課題.md` | リリース戦略の補助文書 |
| `../events_database.xlsx` | ライフイベント原典（v2.1、149件） |
| `../achievements_database.xlsx` | 実績マスター（v1.0、100件） |
| `../demo.html` | 既存ワイヤーフレーム＋プロト（v2、参照のみ） |

## ライセンス・著作権

本プロジェクトは個人開発作品。商用利用前に各依存パッケージのライセンスを確認すること。
