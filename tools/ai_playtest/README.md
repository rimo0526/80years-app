# tools/ai_playtest（Phase C v0.1）

資本主義ゲームの AI 主導プレイテスト基盤。

## 構成

```
tools/ai_playtest/
├── README.md           ← この文書
├── random_bot.dart     ← Dart 側のメインボット（既存 GameEngine を直接利用）
├── random_bot.py       ← Python 薄ラッパ（Dart 呼出 + ログ集計）
└── logs/
    └── {YYYY-MM-DD}/
        ├── session_{seed}_{i}.json  ← セッション単位のフルログ
        └── _summary.json            ← 当該実行のサマリ
```

## 使い方

### 基本（ローカル実行）

```bash
# Dart のみ：10セッションをランダムプレイ
dart run tools/ai_playtest/random_bot.dart

# パラメータ指定：100セッション、最大960ターン、固定シード
dart run tools/ai_playtest/random_bot.dart --sessions=100 --max-turns=960 --seed=42 --verbose

# Python ラッパ経由（Dart 実行 + 集計）
python tools/ai_playtest/random_bot.py --sessions=100

# 集計のみ（既存ログを再分析）
python tools/ai_playtest/random_bot.py --analyze-only --date 2026-05-09
```

### CI/CD での使い方

`.github/workflows/ci.yml` の `test` ジョブで、毎 push 時に **10セッションのスモークテスト** を実行。
クラッシュ・無限ループの早期検出が目的（`continue-on-error: true` で CI 全体は止めない）。

```yaml
- name: AI playtest sanity (Dart-side random bot, 10 sessions)
  run: dart run tools/ai_playtest/random_bot.dart --sessions=10 --max-turns=960
  continue-on-error: true
```

## 出力フォーマット

### `session_*.json`（1セッション）

```json
{
  "session_id": "session_1715234567_0",
  "seed": 1715234567,
  "turn_count": 80,
  "turns": [
    { "turn": 0,  "age": 18, "asset": 0,    "health": 100, "happiness": 50 },
    { "turn": 12, "age": 19, "asset": 240,  "health":  98, "happiness": 52 },
    ...
  ],
  "result": {
    "final_turn": 960,
    "final_age": 80,
    "final_asset": 12000000,
    "final_health": 30,
    "final_happiness": 70,
    "is_over": true,
    "reached_max_turn": false
  },
  "error": null,
  "started_at": "2026-05-09T13:30:00.000Z",
  "finished_at": "2026-05-09T13:30:01.234Z",
  "duration_ms": 1234
}
```

### `_summary.json`（実行サマリ）

```json
{
  "generated_at": "2026-05-09T13:35:00.000Z",
  "total_sessions": 100,
  "ok": 98,
  "errors": 2,
  "total_duration_ms": 12345,
  "avg_duration_ms": 123,
  "sessions": [...]
}
```

## v0.1 の制約と TODO

### 既知の制約
- `GameEngine.getAvailableActions()` / `executeAction()` の API 名は仮（実装に合わせて調整要）
- 1ターンごとのスナップショットは「年単位（12ターン毎）」のみ取得（フルダンプは肥大化のため）
- セッション間のクロス分析は未対応（Phase C v0.2 で `auto_balance.py` 着手時に追加）

### Phase C v0.2 で追加予定
- バランス自動調整（勝率・破産率・到達年齢分布の解析）
- Claude API 連携によるパラメータ調整提案
- プレイログのクラウド集約（Cloudflare Workers D1 候補）

### Phase C v0.3 で追加予定
- AI 生成カード・イベントの動作検証
- 新規コンテンツの自動回帰テスト

## トラブルシュート

### `Cannot resolve package:capitalism_game/...`
- `flutter pub get` を先に実行
- pubspec.yaml の `name` が `capitalism_game` であることを確認

### Dart bot がエラー終了する（exit 1）
- エラー率が50%超でCI失敗扱いに。多くは既存 GameEngine の API 仕様変更
- `--verbose` で詳細確認、必要に応じて `random_bot.dart` の `(game as dynamic).foo()` 部分を実装に合わせる

## cowork-claude-sync 連携

各 CI 実行完了時、shared-workspace event-log に `(playtest) {n} sessions ok={ok} err={err}` を記録予定（Phase C v0.2 で webhook 接続）。
