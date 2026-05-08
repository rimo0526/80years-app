// ============================================================
// SCR-07 エンディング画面 / GDD §11.2 / §11.3
//
// Phase 0 ではプレースホルダ。Phase 1 で本格実装：
//  - 墓標カード生成
//  - 1.91:1 / 1:1 画像出力
//  - SNS共有ボタン
// ============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';

class EndingScreen extends StatelessWidget {
  const EndingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgInner,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'R . I . P',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 8,
                    color: AppPalette.textSub,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'エンディング画面',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Phase 0 のスケルトン。\n'
                  'Phase 1 で墓標生成・SNS共有を実装。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.textSub),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppRoute.title),
                  child: const Text('タイトルへ戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
