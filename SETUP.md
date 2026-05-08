# Flutter SDK セットアップ手順（Windows）

`資本主義ゲーム` の Flutter プロジェクトを動かすための SDK インストール手順です。
**いずれか1つの方法を選択してください**。`scoop` が最も推奨です。

---

## 推奨：方法1：scoop（軽量・コマンド一発）

[scoop](https://scoop.sh/) は Windows 向けのコマンドラインインストーラ。管理者権限不要、PATH設定も自動。

### 1. scoop 自体のインストール（未導入なら）

PowerShell（管理者権限**不要**）で：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### 2. Flutter インストール

```powershell
scoop bucket add extras
scoop install flutter
```

### 3. 動作確認

```powershell
flutter --version
flutter doctor
```

`flutter doctor` で必要に応じて Visual Studio / Android Studio / Chrome 等の警告が出るので、Web版を試すなら最低 **Chrome** が必須。

---

## 方法2：Chocolatey

[Chocolatey](https://chocolatey.org/) を使う場合（管理者権限が必要）。

### 1. Chocolatey 自体のインストール

PowerShell（**管理者**として実行）：
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Flutter インストール

```powershell
choco install flutter
```

### 3. 動作確認

```powershell
flutter --version
flutter doctor
```

---

## 方法3：手動ダウンロード（最も確実、依存ツール不要）

### 1. SDK をダウンロード

公式ページから ZIP を取得：
- https://docs.flutter.dev/get-started/install/windows

### 2. 展開先を決める

例：`C:\src\flutter` に展開（**Program Files への配置は権限問題が起きやすいため避ける**）。

### 3. PATH を通す

「設定 → システム → バージョン情報 → システムの詳細設定 → 環境変数」から、ユーザー環境変数 `Path` に以下を追加：

```
C:\src\flutter\bin
```

### 4. 動作確認

新しいターミナルを開いて：
```powershell
flutter --version
flutter doctor
```

---

## インストール後の作業

### 1. プロジェクトディレクトリに移動

```powershell
cd C:\Users\81903\Documents\Claude\Projects\資本主義ゲーム\app_flutter
```

### 2. 依存解決

```powershell
flutter pub get
```

### 3. ユニットテスト実行

```powershell
flutter test test/save_repository_test.dart
```

期待される出力：
```
00:01 +4: All tests passed!
```

### 4. 静的解析

```powershell
flutter analyze
```

警告が出ても致命的でなければ進行可能。

### 5. Web 版を起動

```powershell
flutter run -d chrome
```

Chrome が起動して、タイトル画面が表示されれば成功。

### 6. Android（実機/エミュレータ）で起動

```powershell
flutter devices
flutter run -d <device-id>
```

`flutter doctor` で Android Studio 関連の警告が出ていれば、それを先に解消する必要あり。

---

## トラブルシューティング

### `flutter` コマンドが見つからない
→ PATH が通っていない。新しいターミナルを開き直すか、PATH 設定を見直す。

### `flutter doctor` で X マーク
→ 必要なツール（Visual Studio / Android Studio / Chrome）を案内に従ってインストール。
→ Web版だけ動かしたい場合は Chrome のみで OK（Visual Studio / Android Studio の警告は無視可）。

### `flutter pub get` が遅い・失敗する
→ pub.dev へのネットワーク接続を確認。社内プロキシ環境なら `flutter config --no-analytics` などで対応。

### `--break-system-packages` 等の Python エラー
→ `tools/xlsx_to_json.py` 実行時のメッセージ。`pip install openpyxl --break-system-packages` で解決。

### Web 版で日本語が文字化けする
→ Phase 1 で `assets/fonts/` に NotoSansJP を同梱して解決予定。現状はシステムフォント依存。

---

## 関連リソース

| 用途 | URL |
|---|---|
| Flutter 公式ガイド | https://docs.flutter.dev |
| Riverpod ドキュメント | https://riverpod.dev |
| go_router | https://pub.dev/packages/go_router |
| Hive | https://pub.dev/packages/hive |
| pub.dev | https://pub.dev |

---

## SDKバージョンの推奨

| 項目 | 推奨値 |
|---|---|
| Flutter SDK | 3.22 以上（pubspec.yaml 指定） |
| Dart SDK | 3.3 以上（Flutter SDK に含まれる） |
| Android SDK | API 26（8.0 Oreo）以上 |
| iOS SDK | 14 以上 |

`flutter upgrade` で最新の安定版に更新できます。
