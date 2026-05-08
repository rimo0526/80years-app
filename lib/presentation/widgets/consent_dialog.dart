// ============================================================
// 同意UI（簡易CMP） / GDD §17.2.6
// アナリティクス・広告のパーソナライゼーション・クラッシュレポート
// の3項目をオプトインで同意取得する。
// 結果は SettingsData.consent ブロックに記録（GDD §18.3.5）。
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../domain/models/settings_data.dart';

class ConsentResult {
  final bool analyticsOptin;
  final bool adsPersonalization;
  final bool crashReportOptin;

  const ConsentResult({
    required this.analyticsOptin,
    required this.adsPersonalization,
    required this.crashReportOptin,
  });

  ConsentSettings toSettings() => ConsentSettings(
        analyticsOptin: analyticsOptin,
        adsPersonalization: adsPersonalization,
        crashReportOptin: crashReportOptin,
        policyAcceptedAt: DateTime.now().toIso8601String(),
      );
}

/// 同意ダイアログを表示。結果は ConsentResult（任意）。
/// すべてオプトイン（チェックなしで「同意して開始」可）。
Future<ConsentResult?> showConsentDialog(BuildContext context) {
  return showDialog<ConsentResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _ConsentDialog(),
  );
}

class _ConsentDialog extends ConsumerStatefulWidget {
  const _ConsentDialog();

  @override
  ConsumerState<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends ConsumerState<_ConsentDialog> {
  bool _analytics = false;
  bool _ads = false;
  bool _crash = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'プライバシー設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppPalette.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '本作はマネタイズに広告を使い、改善のため一部のデータを収集します。'
                '以下はすべて任意です。後から設定画面で変更できます。',
                style: TextStyle(
                  fontSize: 12,
                  color: AppPalette.textSub,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              _row(
                title: 'アナリティクス送信',
                subtitle: '改善のための匿名プレイデータを送信します',
                value: _analytics,
                onChanged: (v) => setState(() => _analytics = v),
              ),
              _row(
                title: '広告のパーソナライズ',
                subtitle: 'あなたに合った広告を表示します',
                value: _ads,
                onChanged: (v) => setState(() => _ads = v),
              ),
              _row(
                title: 'クラッシュレポート',
                subtitle: '不具合発生時に診断情報を送信します',
                value: _crash,
                onChanged: (v) => setState(() => _crash = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  ConsentResult(
                    analyticsOptin: _analytics,
                    adsPersonalization: _ads,
                    crashReportOptin: _crash,
                  ),
                ),
                child: const Text('同意して開始'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  const ConsentResult(
                    analyticsOptin: false,
                    adsPersonalization: false,
                    crashReportOptin: false,
                  ),
                ),
                child: const Text('すべて拒否して開始'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppPalette.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPalette.textSub,
                      height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
