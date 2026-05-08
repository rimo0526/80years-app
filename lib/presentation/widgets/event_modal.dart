// ============================================================
// イベントモーダル / GDD §10.3.5 結果表示の演出
// ============================================================
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/event_definition.dart';

/// イベントモーダルを表示
/// 戻り値：選択された選択肢のインデックス（0〜2）。閉じられたら null
Future<int?> showEventModal(BuildContext context, EventDefinition event) {
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _EventModal(event: event),
  );
}

class _EventModal extends StatelessWidget {
  final EventDefinition event;

  const _EventModal({required this.event});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event.isHidden ? '隠しイベント' : '突発イベント',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                  color: event.isHidden ? AppPalette.goldText : AppPalette.copper,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppPalette.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPalette.textSub,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < event.choices.length; i++) ...[
                        _ChoiceButton(
                          choice: event.choices[i],
                          onTap: () => Navigator.of(context).pop(i),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final EventChoice choice;
  final VoidCallback onTap;

  const _ChoiceButton({required this.choice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppPalette.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              choice.label,
              style: const TextStyle(
                fontSize: 14,
                color: AppPalette.textMain,
              ),
            ),
            if (choice.effectText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _normalizeEffectText(choice.effectText),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppPalette.textSub,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 効果テキストの表記統一（GDD §13.7.2）
  /// 「健康+15」→「健康度+15」、「地位+5」→「社会的地位+5」、「幸福-3」→「幸福度-3」
  static String _normalizeEffectText(String s) {
    return s
        .replaceAll(RegExp(r'(?<![的度])健康'), '健康度')
        .replaceAll(RegExp(r'(?<![的度])幸福'), '幸福度')
        .replaceAll(RegExp(r'(?<!社会的)地位'), '社会的地位');
  }
}
