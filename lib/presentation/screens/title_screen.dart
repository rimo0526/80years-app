// ============================================================
// SCR-01 タイトル画面 / GDD §12.2.1
// ============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgOuter,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            color: AppPalette.bgInner,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Emblem(),
                const SizedBox(height: 30),
                const Text(
                  '資本主義ゲーム',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: AppPalette.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '人生は何度でも',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: AppPalette.textSub,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go(AppRoute.createGender),
                        child: const Text('ニューゲーム'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('続きから（実装中）')),
                          );
                        },
                        child: const Text('続きから（準備中）'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('実績図鑑（実装中）')),
                          );
                        },
                        child: const Text('実績図鑑（準備中）'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.textMain, width: 2),
      ),
      child: const Center(
        child: Text(
          '資',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w300,
            color: AppPalette.textMain,
          ),
        ),
      ),
    );
  }
}
