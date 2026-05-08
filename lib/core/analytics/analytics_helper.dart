// ============================================================
// AnalyticsHelper / Firebase Analytics + Crashlytics ラッパー
// GDD §17.1.2 / §17.6 / §21
//
// 同意UI の analyticsOptin / crashReportOptin に応じて起動・停止。
// 主要イベントを 1 ヶ所で発火する API を提供。
// ============================================================
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// 主要イベントの定数（GA4 のイベント名規約に合わせた snake_case）
class AnalyticsEvent {
  // 起動・終了
  static const appLaunch = 'app_launch';
  static const consentSet = 'consent_set';
  // キャラ作成
  static const characterCreateStart = 'character_create_start';
  static const characterCreateComplete = 'character_create_complete';
  static const eraSelected = 'era_selected';
  // ゲーム進行
  static const gameStart = 'game_start';
  static const turnAdvanced = 'turn_advanced';
  static const milestoneFired = 'milestone_fired';
  static const eventFired = 'event_fired';
  static const skillUnlocked = 'skill_unlocked';
  // 終了系
  static const characterDied = 'character_died';
  static const endingShown = 'ending_shown';
  static const generationStart = 'generation_start';
  // 実績
  static const achievementUnlocked = 'achievement_unlocked';
  // 共有
  static const tombShared = 'tomb_shared';
  // 広告
  static const adShown = 'ad_shown';
  static const adClicked = 'ad_clicked';
  static const rewardedClaimed = 'rewarded_claimed';
  // エラー
  static const errorOccurred = 'error_occurred';
}

class AnalyticsHelper {
  AnalyticsHelper._();
  static final instance = AnalyticsHelper._();

  bool _initialized = false;
  bool _analyticsEnabled = false;
  bool _crashlyticsEnabled = false;
  FirebaseAnalytics? _analytics;

  /// 同意UI 結果から起動。
  /// analyticsOptin=true なら GA4 ログ送信
  /// crashReportOptin=true なら Crashlytics 起動
  Future<void> initialize({
    required bool analyticsOptin,
    required bool crashReportOptin,
  }) async {
    if (_initialized) return;
    _analyticsEnabled = analyticsOptin;
    _crashlyticsEnabled = crashReportOptin;

    try {
      // Web でも動作するが、Firebase の初期化が必要
      // 実際の DefaultFirebaseOptions は flutterfire configure で生成する
      // 現状はスタブとして try/catch で握りつぶす
      await Firebase.initializeApp();

      if (_analyticsEnabled) {
        _analytics = FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
      }

      if (_crashlyticsEnabled && !kIsWeb) {
        // Web ではCrashlyticsは非対応
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
      }

      _initialized = true;
    } catch (e) {
      // 初期化失敗時は黙ってスキップ（オフライン環境等）
      _initialized = false;
    }
  }

  /// 同意撤回時に呼ぶ
  Future<void> revokeConsent() async {
    _analyticsEnabled = false;
    _crashlyticsEnabled = false;
    if (_analytics != null) {
      await _analytics!.setAnalyticsCollectionEnabled(false);
    }
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  }

  /// イベントログ送信
  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (!_initialized || !_analyticsEnabled || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: params);
    } catch (_) {
      // 黙って無視
    }
  }

  /// エラーログ送信（Crashlytics へも転送）
  Future<void> logError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    if (!_initialized) return;
    if (_analyticsEnabled) {
      await logEvent(AnalyticsEvent.errorOccurred, params: {
        'error_type': error.runtimeType.toString(),
        if (reason != null) 'reason': reason,
      });
    }
    if (_crashlyticsEnabled && !kIsWeb) {
      try {
        await FirebaseCrashlytics.instance.recordError(error, stack,
            reason: reason);
      } catch (_) {}
    }
  }

  /// 画面遷移ログ
  Future<void> logScreenView(String screenName) async {
    if (!_initialized || !_analyticsEnabled || _analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  // ============================================================
  // ヘルパー：GDD §17 のシナリオ別ログ
  // ============================================================

  Future<void> logCharacterCreate({
    required String era,
    required String strength,
  }) async {
    await logEvent(AnalyticsEvent.characterCreateComplete, params: {
      'era': era,
      'strength': strength,
    });
  }

  Future<void> logCharacterDeath({
    required int age,
    required String cause,
    required String era,
    required int generation,
  }) async {
    await logEvent(AnalyticsEvent.characterDied, params: {
      'age': age,
      'cause': cause,
      'era': era,
      'generation': generation,
    });
  }

  Future<void> logEnding(String endingId, {required int finalAsset}) async {
    await logEvent(AnalyticsEvent.endingShown, params: {
      'ending_id': endingId,
      'final_asset': finalAsset,
    });
  }

  Future<void> logAchievement(String achievementId) async {
    await logEvent(AnalyticsEvent.achievementUnlocked, params: {
      'achievement_id': achievementId,
    });
  }

  Future<void> logTombShared({required String platform}) async {
    await logEvent(AnalyticsEvent.tombShared, params: {
      'platform': platform,
    });
  }

  Future<void> logRewardedClaimed({required String rewardType}) async {
    await logEvent(AnalyticsEvent.rewardedClaimed, params: {
      'reward_type': rewardType,
    });
  }

  bool get isReady => _initialized;
  bool get analyticsEnabled => _analyticsEnabled;
}
