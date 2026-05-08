// ============================================================
// Analytics 関連 Riverpod プロバイダ
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_helper.dart';

final analyticsHelperProvider =
    Provider<AnalyticsHelper>((ref) => AnalyticsHelper.instance);
