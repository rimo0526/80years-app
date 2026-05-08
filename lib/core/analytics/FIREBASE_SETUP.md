# Firebase セットアップ手順

`firebase_core` / `firebase_analytics` / `firebase_crashlytics` の初期化には Firebase プロジェクト作成と設定ファイル配置が必要。

最終更新：2026-05-08

---

## Step 1：Firebase プロジェクト作成

1. `https://console.firebase.google.com/` でログイン
2. 「プロジェクトを追加」 → 名前：`80years-app`
3. Analytics を有効化（GA4 アカウントを新規作成 or 既存連携）
4. リージョン：日本（asia-northeast1）

---

## Step 2：FlutterFire CLI で設定生成

```powershell
# CLI インストール（初回のみ）
dart pub global activate flutterfire_cli

# プロジェクト連携
cd C:\Users\81903\Documents\Claude\Projects\資本主義ゲーム\app_flutter
flutterfire configure
```

対話で：
- Firebase プロジェクト：80years-app を選択
- プラットフォーム：android, ios, web を全選択
- iOS bundle id：com.rimo.capitalismGame
- Android package：com.rimo.capitalism_game

→ `lib/firebase_options.dart` が生成される。この**ファイルは機密情報を含むため git ignore 推奨**。

---

## Step 3：main.dart 修正

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 同意UI 表示後に AnalyticsHelper.instance.initialize(...) 呼ぶ
  runApp(const CapitalismGameApp());
}
```

---

## Step 4：Web Analytics タグ追加

`web/index.html` の `<head>` に追加（既にコメントアウトのテンプレート有り）：

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  // 同意取得後にDart側から発火するため、ここでは config しない
</script>
```

`G-XXXXXXXXXX` は Firebase Console → Analytics → 設定 で取得。

---

## Step 5：Crashlytics（Android 限定設定）

`android/build.gradle.kts` の `dependencies`：

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("com.google.firebase.crashlytics") version "3.0.0" apply false
}
```

`android/app/build.gradle.kts`：

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}
```

---

## Step 6：iOS Crashlytics 設定

`ios/Runner/AppDelegate.swift`：

```swift
import Firebase
import FirebaseCrashlytics

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(...) -> Bool {
    FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Build Phase で「Run Script」を追加：

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

---

## Step 7：動作確認

```powershell
flutter run -d chrome
# DevTools コンソールで Firebase init ログ確認
# Firebase Console → Analytics → DebugView でリアルタイム確認可能
```

テスト用イベント送信：

```dart
AnalyticsHelper.instance.logEvent('test_event', params: {'test': 'value'});
```

---

## Step 8：プライバシーポリシー追記

既存の `privacy.html` 第3条にて Firebase（Google）への送信を明記済 ✅

---

## 重要：機密ファイル管理

`.gitignore` に以下を追加（既存のものに追記）：

```
# Firebase
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

公開リポでこれらを公開すると、攻撃者がプロジェクトに偽データを送り込めるリスク有り。

---

## トラブルシューティング

### 「Firebase has not been initialized」

- `main.dart` で `Firebase.initializeApp()` 呼んでいるか
- `firebase_options.dart` 生成済みか

### Web で Analytics イベントが届かない

- ブラウザ拡張機能（広告ブロッカー）でブロックされている可能性
- DebugView で確認、本番環境（独自ドメイン後）で再テスト

### iOS で Crashlytics が動かない

- BuildPhase の Run Script 順序確認（Compile Sources の後）
- dSYMs アップロード確認

---

## 参考リンク

- FlutterFire 公式：https://firebase.flutter.dev
- Crashlytics 設定：https://firebase.google.com/docs/crashlytics/get-started?platform=flutter
- Firebase Console：https://console.firebase.google.com
