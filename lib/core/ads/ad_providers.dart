// ============================================================
// AdMob 関連の Riverpod プロバイダ
// GDD §15.1.4 / §17.1.2
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_helper.dart';

/// 起動時に同意UI から渡されるフラグで初期化される
/// main.dart のスプラッシュ後に Provider.read で実行
final adHelperProvider = Provider<AdHelper>((ref) => AdHelper.instance);

/// 直近のインタースティシャル提示時刻（連続提示防止用）
final lastInterstitialAtProvider = StateProvider<DateTime?>((ref) => null);

/// インタースティシャル間隔ポリシー（GDD §15.1.5 フェアユーザー指標）
/// 同一プレイ中、最低 5 分は間を空ける
class InterstitialPolicy {
  static const minIntervalMinutes = 5;

  /// 直近提示から十分時間が経っていれば true
  static bool canShow(DateTime? lastAt) {
    if (lastAt == null) return true;
    final diff = DateTime.now().difference(lastAt);
    return diff.inMinutes >= minIntervalMinutes;
  }
}
