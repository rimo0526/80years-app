# AdMob ネイティブセットアップ手順

`google_mobile_ads` パッケージは Web では何もしないが、Android / iOS ではネイティブ設定が必要。

このプロジェクトは現状 Web 中心で android/ ios/ ディレクトリが未生成。
モバイル展開時に以下を実行：

---

## Step 1：android/ios プロジェクトを生成

```powershell
cd C:\Users\81903\Documents\Claude\Projects\資本主義ゲーム\app_flutter
flutter create --platforms=android,ios --org com.rimo .
```

`--org com.rimo` は package id のプレフィックス。最終的に
`com.rimo.capitalism_game` になる。後で変更不可なので慎重に。

---

## Step 2：Android — AndroidManifest.xml 編集

`android/app/src/main/AndroidManifest.xml` の `<application>` 内に追記：

```xml
<application
    android:label="資本主義ゲーム"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">

    <!-- AdMob Application ID -->
    <!-- 現状はテストID。本番ID取得後に置換 -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-3940256099942544~3347511713"/>

    <!-- 以下、既存の <activity> 等 -->
</application>
```

注意：`APPLICATION_ID` は `ca-app-pub-XXXX~YYYY`（チルダ区切り）。
広告ユニットIDの `/` 区切りとは異なる。

---

## Step 3：iOS — Info.plist 編集

`ios/Runner/Info.plist` に追加：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>

<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <!-- 他 SKAdNetwork は GDD §15.1.4 SKAN リストを参照 -->
</array>

<!-- App Tracking Transparency 用（iOS 14.5+） -->
<key>NSUserTrackingUsageDescription</key>
<string>このアプリは広告のパーソナライズのため、デバイスの広告識別子を使用します。</string>
```

---

## Step 4：iOS — Podfile 編集

`ios/Podfile` の最低デプロイメントターゲット：

```ruby
platform :ios, '12.0'   # AdMob 5.x は iOS 12+ 必要
```

---

## Step 5：実機テスト

```powershell
# Android
flutter run -d android

# iOS（Mac 必須）
flutter run -d iphone
```

DevTools で広告がロードされるか確認。テストIDなので「Test Ad」と表示される。

---

## Step 6：本番ID取得（AdSense / AdMob 承認後）

1. AdMob Console（`https://admob.google.com`）でアプリ登録
2. アプリID（`ca-app-pub-XXXX~YYYY`）を取得
3. 広告ユニット作成（バナー / インタースティシャル / リワード）
   - 各ユニットの ID（`ca-app-pub-XXXX/ZZZZ`）を取得
4. `lib/core/ads/ad_helper.dart` の `_productionXXXId()` を本番IDに置換
5. AndroidManifest / Info.plist の APPLICATION_ID を本番に置換
6. リビルド → リリースビルドで広告動作を確認

---

## トラブルシューティング

### Android：広告がロードされない

- DevTools コンソールで `Ad failed to load` の詳細エラー確認
- インターネット接続確認
- AndroidManifest の APPLICATION_ID 正しいか
- `compileSdkVersion 34+` になっているか

### iOS：ATT ダイアログが出ない

- iOS 14.5+ でないと出ない（SimuLator 設定で調整）
- Info.plist の `NSUserTrackingUsageDescription` あるか
- 同意UI の前に AdHelper.initialize() してないか

### Web：何も表示されない

- 正常。`google_mobile_ads` は Web stubs。Web は AdSense 経由（`web/index.html`）

---

## 関連ドキュメント

- AdMob Flutter プラグイン：https://developers.google.com/admob/flutter/quick-start
- AdSense 申請ガイド：`_docs/ADSENSE_APPLY_GUIDE.md`
- プライバシーポリシー：`web/privacy.html`
