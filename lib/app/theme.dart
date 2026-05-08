// ============================================================
// テーマ定義 / GDD §13.1.2 配色パレット13色準拠
// demo.html の CSS変数と同じ13色を Flutter ThemeData にマッピング
// ============================================================
import 'package:flutter/material.dart';

/// 正式パレット（GDD §13.1.2、demo.html v2 と同期）
class AppPalette {
  // 背景系
  static const Color bgOuter = Color(0xFFECEAE3);   // ボーン（外周背景）
  static const Color bgInner = Color(0xFFFAFAF7);   // アイボリー（内側背景）
  static const Color bgSub = Color(0xFFF1EFE8);     // ライトボーン（HUD・タグ）
  static const Color border = Color(0xFFD3D1C7);    // グレージュ（罫線）

  // テキスト
  static const Color textMain = Color(0xFF2C2C2A); // ダークグレー
  static const Color textSub = Color(0xFF5F5E5A);  // ミディアムグレー

  // アクセント
  static const Color accent = Color(0xFF378ADD);     // ロイヤルブルー
  static const Color accentBg = Color(0xFFE6F1FB);   // ライトブルー

  // 増減
  static const Color plus = Color(0xFF1D9E75);       // グリーン
  static const Color minus = Color(0xFFD85A30);      // バーミリオン

  // 警告金・銅
  static const Color goldBg = Color(0xFFFAEEDA);
  static const Color goldText = Color(0xFF854F0B);
  static const Color copper = Color(0xFFBA7517);
  static const Color brick = Color(0xFF993C1D);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.accent,
      surface: AppPalette.bgInner,
      onSurface: AppPalette.textMain,
      primary: AppPalette.accent,
      onPrimary: Colors.white,
      error: AppPalette.minus,
    ),
    scaffoldBackgroundColor: AppPalette.bgOuter,
    fontFamily: _platformFontFamily,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppPalette.textMain,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: AppPalette.textMain,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppPalette.textSub,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.textSub,
        side: const BorderSide(color: AppPalette.border),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}

/// プラットフォーム別の優先フォント
/// 本番では NotoSansJP を assets に同梱して切替
const String _platformFontFamily = 'Hiragino Kaku Gothic ProN';
