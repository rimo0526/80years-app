// ============================================================
// アプリ起動部 / GDD §17.3.1 UI Layer のルートウィジェット
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class CapitalismGameApp extends ConsumerWidget {
  const CapitalismGameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '資本主義ゲーム',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
