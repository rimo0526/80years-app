// ============================================================
// プラットフォーム判定でWeb/Mobile実装を返すファクトリ
// GDD §17.3.2 抽象化レイヤーの中核
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/save_repository.dart';
import '../sources/codec_io.dart';
import 'save_repository_web.dart';
import 'save_repository_mobile.dart';

/// 起動時に1回だけ呼び出してCodecを初期化
bool _codecInitialized = false;
void _ensureCodec() {
  if (_codecInitialized) return;
  initCodec();
  _codecInitialized = true;
}

/// Riverpod プロバイダー：プラットフォームに応じた実装を返す
final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  _ensureCodec();
  if (kIsWeb) {
    return WebSaveRepository();
  } else {
    return MobileSaveRepository();
  }
});
