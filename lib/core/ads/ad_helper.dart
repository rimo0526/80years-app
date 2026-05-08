// ============================================================
// AdHelper / AdMob のラッパー（GDD §15.1.4）
//
// 設計：
//  - Web / Mobile の差異を抽象化
//  - 同意UI（ConsentSettings.adsPersonalization）と連動
//  - 3広告タイプ（Banner / Interstitial / Rewarded）を統一API
//  - テスト広告ID と本番広告ID をビルド時切替
//  - 初期化失敗・読み込み失敗で例外を握りつぶす（無料運営）
// ============================================================
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 広告ID 定義
/// - debug ビルド時はテストID
/// - release ビルド時は本番ID（後日 ad_ids_secret.dart で上書き予定）
class AdIds {
  static String get banner {
    if (kIsWeb) return ''; // Web は AdSense 経由のため空
    if (kDebugMode) return _testBannerId();
    return _productionBannerId();
  }

  static String get interstitial {
    if (kIsWeb) return '';
    if (kDebugMode) return _testInterstitialId();
    return _productionInterstitialId();
  }

  static String get rewarded {
    if (kIsWeb) return '';
    if (kDebugMode) return _testRewardedId();
    return _productionRewardedId();
  }

  // ----- AdMob 公式テストID（GDD §15.1.4 に従う） -----
  static String _testBannerId() {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String _testInterstitialId() {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  static String _testRewardedId() {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }

  // ----- 本番ID（AdMob審査通過後に取得） -----
  // TODO: ad_ids_secret.dart で override（gitignore 対象）
  static String _productionBannerId() {
    return _testBannerId(); // 一時的にテストIDで運用
  }

  static String _productionInterstitialId() {
    return _testInterstitialId();
  }

  static String _productionRewardedId() {
    return _testRewardedId();
  }
}

/// AdMob 初期化＋3広告タイプの統一API
class AdHelper {
  AdHelper._();
  static final instance = AdHelper._();

  bool _initialized = false;
  bool _personalizationConsent = false;

  /// 同意UI 結果から呼ばれる
  /// adsPersonalization=true → パーソナライズ広告
  ///                  =false → コンテキスト広告のみ
  Future<void> initialize({required bool adsPersonalization}) async {
    if (kIsWeb) return; // Web は AdSense なので何もしない
    if (_initialized) return;

    _personalizationConsent = adsPersonalization;
    try {
      await MobileAds.instance.initialize();
      // NPA（Non-Personalized Ads）パラメータ設定
      // Web経由の Targeted フラグは将来 ConsentInformation で動的化
      _initialized = true;
    } catch (e) {
      // 失敗しても無視（広告なしで継続）
      _initialized = false;
    }
  }

  /// 同意撤回時に呼ぶ
  void revokeConsent() {
    _personalizationConsent = false;
    // 既存広告は次回ロード時に NPA フラグで再要求される
  }

  bool get isReady => _initialized;
  bool get personalizationConsent => _personalizationConsent;

  /// バナー広告ロード（フッター固定表示用）
  /// 戻り値：BannerAd オブジェクト。利用側で .load() → AdWidget で描画
  BannerAd loadBanner({
    required AdSize size,
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: _adRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          onAdFailedToLoad(ad, err);
        },
      ),
    );
  }

  /// インタースティシャル（GDD §15.1.4 月N回・キャラ作成完了時等）
  Future<InterstitialAd?> loadInterstitial() async {
    if (!_initialized) return null;
    InterstitialAd? loaded;
    final completer = Future<InterstitialAd?>(() async {
      await InterstitialAd.load(
        adUnitId: AdIds.interstitial,
        request: _adRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => loaded = ad,
          onAdFailedToLoad: (err) => loaded = null,
        ),
      );
      // ロードのコールバックは別スレッドで設定されるが、
      // 最大3秒待機して諦める
      var waited = 0;
      while (loaded == null && waited < 30) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      return loaded;
    });
    return completer;
  }

  /// リワード広告（GDD §15.1.2 6種のリワード用）
  Future<RewardedAd?> loadRewarded() async {
    if (!_initialized) return null;
    RewardedAd? loaded;
    await RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: _adRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => loaded = ad,
        onAdFailedToLoad: (err) => loaded = null,
      ),
    );
    var waited = 0;
    while (loaded == null && waited < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      waited++;
    }
    return loaded;
  }

  AdRequest _adRequest() {
    return AdRequest(
      nonPersonalizedAds: !_personalizationConsent,
    );
  }
}
