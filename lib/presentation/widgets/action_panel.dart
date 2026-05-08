// ============================================================
// アクション選択パネル / GDD §8.3
// 標準5択（学業／運動／社交／趣味／休息）＋解放アクション
// ============================================================
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/character.dart';

class ActionDef {
  final String label;
  final String hint;
  final Map<String, int> effects; // 「健康度+5」のような表示用ではなく内部キー
  final IconData icon;

  const ActionDef({
    required this.label,
    required this.hint,
    required this.effects,
    required this.icon,
  });
}

class ActionPanel extends StatelessWidget {
  final Character character;
  final void Function(ActionDef action) onSelected;

  const ActionPanel({
    required this.character,
    required this.onSelected,
    super.key,
  });

  /// 標準5択
  static List<ActionDef> standardActions(Character c) {
    return [
      const ActionDef(
        label: '学業に取り組む',
        hint: '頭脳+1',
        effects: {'頭脳': 1},
        icon: Icons.menu_book,
      ),
      const ActionDef(
        label: '運動する',
        hint: '肉体+1 / 健康度+1',
        effects: {'肉体': 1, '健康': 1},
        icon: Icons.directions_run,
      ),
      const ActionDef(
        label: '人と会う',
        hint: 'コミュ+1 / 幸福度+1',
        effects: {'コミュ': 1, '幸福': 1},
        icon: Icons.people,
      ),
      const ActionDef(
        label: '趣味に没頭する',
        hint: 'センス+1 / 幸福度+2',
        effects: {'センス': 1, '幸福': 2},
        icon: Icons.palette,
      ),
      const ActionDef(
        label: 'ゆっくり休む',
        hint: '健康度+3 / 幸福度+2',
        effects: {'健康': 3, '幸福': 2},
        icon: Icons.bed,
      ),
    ];
  }

  /// 解放アクション（GDD §8.3.3）
  static List<ActionDef> unlockedActions(Character c) {
    final result = <ActionDef>[];
    if (c.stats.social >= 40) {
      result.add(const ActionDef(
        label: '副業を探す',
        hint: '副業収入の機会',
        effects: {'コミュ': 1},
        icon: Icons.work_outline,
      ));
    }
    if (c.results.asset >= 100000) {
      result.add(const ActionDef(
        label: '投資する',
        hint: '投資配分を見直し',
        effects: {'センス': 1},
        icon: Icons.trending_up,
      ));
    }
    if (c.age >= 20) {
      result.add(const ActionDef(
        label: 'ボランティア',
        hint: '人間性+2',
        effects: {'人間性': 2, 'コミュ': 1},
        icon: Icons.volunteer_activism,
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      ...standardActions(character),
      ...unlockedActions(character),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '今月、何をして過ごしますか？',
            style: TextStyle(
              fontSize: 13,
              color: AppPalette.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        for (final a in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActionButton(action: a, onTap: () => onSelected(a)),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ActionDef action;
  final VoidCallback onTap;

  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppPalette.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(action.icon, size: 22, color: AppPalette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.textMain,
                    ),
                  ),
                  if (action.hint.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.hint,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
