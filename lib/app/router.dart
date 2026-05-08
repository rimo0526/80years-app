// ============================================================
// ルーティング設定 / GDD §17.3.5 go_router
// 22画面のID管理（GDD §12.2）に対応
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/title_screen.dart';
import '../presentation/screens/character_create_screen.dart';
import '../presentation/screens/main_game_screen.dart';
import '../presentation/screens/ending_screen.dart';

/// 画面ID（GDD §12.2.1〜12.2.2）
/// Phase 0 ではタイトル/キャラ作成5ステップ/メインゲーム/エンディングのみ実装
class AppRoute {
  static const title = '/';                   // SCR-01
  static const createGender = '/create/gender'; // SCR-02
  static const createStrength = '/create/strength'; // SCR-03
  static const createAvatar = '/create/avatar'; // SCR-04
  static const createParent = '/create/parent'; // SCR-05
  static const createEra = '/create/era';     // SCR-08（v1.2 追加）
  static const main = '/main';                // SCR-06
  static const ending = '/ending';            // SCR-07

  // Phase 1 以降で実装：
  // static const finance = '/finance';         // SCR-09
  // static const skillTree = '/skill';         // SCR-11
  // static const investment = '/investment';   // SCR-12
  // static const tombGallery = '/gallery';     // SCR-19
  // static const achievements = '/achievements'; // SCR-20
  // static const settings = '/settings';       // SCR-21
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.title,
    routes: [
      GoRoute(
        path: AppRoute.title,
        builder: (context, state) => const TitleScreen(),
      ),
      GoRoute(
        path: AppRoute.createGender,
        builder: (context, state) => const CharacterCreateScreen(step: CreateStep.gender),
      ),
      GoRoute(
        path: AppRoute.createStrength,
        builder: (context, state) => const CharacterCreateScreen(step: CreateStep.strength),
      ),
      GoRoute(
        path: AppRoute.createAvatar,
        builder: (context, state) => const CharacterCreateScreen(step: CreateStep.avatar),
      ),
      GoRoute(
        path: AppRoute.createParent,
        builder: (context, state) => const CharacterCreateScreen(step: CreateStep.parent),
      ),
      GoRoute(
        path: AppRoute.createEra,
        builder: (context, state) => const CharacterCreateScreen(step: CreateStep.era),
      ),
      GoRoute(
        path: AppRoute.main,
        builder: (context, state) => const MainGameScreen(),
      ),
      GoRoute(
        path: AppRoute.ending,
        builder: (context, state) => const EndingScreen(),
      ),
    ],
  );
});
