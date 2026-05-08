# Phase 1 デプロイガイド（Web版 GitHub Pages）

GDD §17.2.1 / §19.3 / アプリ化_想定課題.md 準拠。
**Phase 1 = Web 正式版を GitHub Pages に公開** が最終ゴール。

---

## 前提

- Flutter SDK 3.22 以降がインストール済み（`flutter --version` で確認）
- GitHub アカウント／空のリポジトリ作成済（例：`username/capitalism-game`）
- Google AdSense アカウント（広告審査前でもデプロイ自体は可能）
- 独自ドメイン（任意。GitHub Pages のサブドメインでも始められる）

---

## Step 1：Web ビルド

```powershell
cd C:\Users\81903\Documents\Claude\Projects\資本主義ゲーム\app_flutter

# 依存解決（初回 or pubspec 変更後）
flutter pub get

# Web ビルド（CanvasKit レンダラ：GDD §1.1 推奨）
flutter build web --release --web-renderer canvaskit

# 成果物は build/web/ に出力される
```

**ビルド成果物の中身**：
```
build/web/
├── index.html
├── flutter.js / flutter_bootstrap.js
├── main.dart.js
├── canvaskit/
├── assets/
│   └── data/  (events.json, achievements.json 等)
├── manifest.json
└── icons/  (PWA アイコン、必要なら追加)
```

---

## Step 2：AdSense / GA4 の有効化

### 2.1 AdSense 有効化（収益化対応の場合）

`web/index.html` を編集：

```html
<!-- コメント解除して data-ad-client を実値に -->
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-XXXXXXXXXXXXXXXX"
        crossorigin="anonymous"></script>
```

下部のバナースロットも `data-ad-client` / `data-ad-slot` を実値に置き換え。

### 2.2 GA4 有効化（任意）

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  // gtag('config', 'G-XXXXXXXXXX');  // 同意取得後に Dart 側から呼ぶ
</script>
```

> 同意UI（CMP）通過後にしか発火させないこと。GDD §17.2.6 / §17.3 / §17.6 参照。

### 2.3 編集後にリビルド

```powershell
flutter build web --release --web-renderer canvaskit
```

---

## Step 3：GitHub Pages にデプロイ

### 3.1 リポジトリ用意

```powershell
cd C:\Users\81903\Documents\Claude\Projects\資本主義ゲーム

git init
git remote add origin https://github.com/<your-username>/capitalism-game.git

# .gitignore に build/ を入れているため、build/web/ をデプロイ用ブランチに分離
```

### 3.2 デプロイブランチ（gh-pages）

GitHub Pages は **専用ブランチ** から配信するのが運用しやすい。

```powershell
# 一時的に build/web/ を gh-pages ブランチへ push する
cd app_flutter

# gh-pages という孤立ブランチを作る
git --work-tree build/web checkout --orphan gh-pages
git --work-tree build/web add --all
git --work-tree build/web commit -m "Deploy v0.1.0"

# Push
git push origin HEAD:gh-pages --force

# main ブランチに戻る
git checkout main
```

### 3.3 GitHub 側設定

- Settings → Pages
  - Source: `gh-pages` ブランチ
  - Folder: `/`（root）
- 数分待つと `https://<username>.github.io/capitalism-game/` で公開

---

## Step 4：独自ドメイン（任意、推奨）

GDD §17.2.5 のドメイン候補：

| 推奨候補 | 年額 | 取得先 |
|---|---|---|
| `80years.app` | $15 | Cloudflare Registrar / Google Domains 後継 |
| `lifegen.app` | $15 | 同上 |
| `ikiru.app` | $15 | 同上 |
| `bohyo.fun` | $5〜15 | 同上 |
| `shihonshugi.game` | $30〜50 | 同上 |

### 4.1 ドメイン取得後

GitHub Pages 設定 → Custom domain に入力。
リポジトリ ルートに `CNAME` ファイルを置く（中身はドメイン名のみ）。

### 4.2 DNS 設定（Cloudflare 等）

- A レコード or CNAME を `<username>.github.io` に向ける
- TTL：Auto

---

## Step 5：プライバシーポリシー & 利用規約

ストア審査・GDPR・COPPA 対応として必須（GDD §21.1.4 / アプリ化_想定課題.md §5.4）。

### 必須項目

- 収集する情報（広告ID、プレイデータ、クラッシュレポート）
- 利用目的（広告配信、改善、障害対応）
- 第三者提供（Google AdSense、Firebase）
- ユーザー権利（オプトアウト方法）
- 連絡先メール

### 配置先

`web/privacy.html` と `web/terms.html` を作成し、GitHub Pages で同時配信。
アプリ内の設定画面からリンクを貼る。

---

## Step 6：動作確認チェックリスト

公開後、以下を順次確認：

- [ ] タイトル画面表示（CanvasKit 初回ロード約2〜3秒）
- [ ] キャラ作成 5 ステップ通し動作
- [ ] 時代選択 → メインゲーム遷移
- [ ] アクション選択でターン進行
- [ ] HUD ステータス更新
- [ ] イベントモーダル発火（events.json から）
- [ ] 死亡 → エンディング画面
- [ ] AdSense バナー表示（実装した場合）
- [ ] 同意UI 起動時表示
- [ ] セーブ → リロード → 続きから可能
- [ ] エクスポート（JSON文字列）動作

---

## Step 7：公開後の運用

### 月次

- AdSense 管理画面で eCPM / 広告収益を確認
- GA4 でリテンション・離脱箇所を確認
- バランス調整値（`assets/data/balance.json` 等）を更新 → 再ビルド → 再デプロイ

### 四半期

- イベント追加（`events_database.xlsx` 改訂 → `python tools/xlsx_to_json.py` で再生成）
- 実績追加
- スクリーンショット差し替え

### バージョニング

- `pubspec.yaml` の version: 0.1.0+1 → 0.2.0+2 のように上げる
- GitHub Releases でタグを切る

---

## トラブルシューティング

### ビルドが遅い／メモリ不足
→ `flutter build web --release --web-renderer canvaskit --no-tree-shake-icons`

### ロード時に空白画面
→ CanvasKit のロードに数秒かかる。`web/index.html` の `#loading` を確認

### イベントが発火しない
→ DevTools コンソールで `assets/data/events.json` の 200 応答を確認

### 文字化け
→ `web/index.html` の `<meta charset="UTF-8">` を確認、Hiragino フォント未同梱なら NotoSansJP を `assets/fonts/` に追加

---

## 参考リンク

- Flutter Web デプロイ：https://docs.flutter.dev/deployment/web
- GitHub Pages：https://docs.github.com/pages
- AdSense：https://adsense.google.com
- 関連ドキュメント
  - `../GDD本体.md` §17 技術仕様 / §19 開発計画 / §21 リリース
  - `../アプリ化_想定課題.md` §1 技術 / §5 配信
