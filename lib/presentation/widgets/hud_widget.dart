// ============================================================
// HUD ウィジェット / GDD §12.3 HUD構成
// demo.html v2 と同レイアウト：
//   上部固定 80px：年齢／年月／所持金／時代
//   中段 60px：能力5＋デルタ
//   下段：結果系5（折畳可、簡素モード切替対応）
// ============================================================
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/enums.dart';
import '../../domain/engines/game_engine.dart';
import '../../domain/models/character.dart';

/// 表示モード（GDD §12.3.4）
enum HudMode { standard, simple }

class HudWidget extends StatelessWidget {
  final Character character;
  final Stats? previousStats; // デルタ表示用
  final HudMode mode;

  const HudWidget({
    required this.character,
    this.previousStats,
    this.mode = HudMode.standard,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _topBar(context),
        const SizedBox(height: 8),
        _abilityRow(),
        if (mode == HudMode.standard) ...[
          const SizedBox(height: 8),
          _resultRow(),
        ],
      ],
    );
  }

  Widget _topBar(BuildContext context) {
    final season = GameEngine.seasonOfAge(character.age);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.bgSub,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _topItem(
            'PROGRESS',
            '${character.yearIndex}年目（${character.age}歳）の$season',
          ),
          _topItem('ERA', '${character.era.label} / ${_schoolStageLabel(character)}'),
          _topItem('ASSET', _formatMoney(character.results.asset)),
        ],
      ),
    );
  }

  Widget _topItem(String _, String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        color: AppPalette.textMain,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _schoolStageLabel(Character c) {
    if (c.age <= 6) return '幼児';
    if (c.age <= 12) return '小学';
    if (c.age <= 15) return '中学';
    if (c.age <= 18) return '高校';
    if (c.age <= 22) return '青年';
    if (c.age >= 60) return '老年';
    return '社会人';
  }

  Widget _abilityRow() {
    final items = [
      _AbilityCell('頭脳', character.stats.brain, _delta('brain')),
      _AbilityCell('肉体', character.stats.body, _delta('body')),
      _AbilityCell('コミュ', character.stats.social, _delta('social')),
      _AbilityCell('センス', character.stats.sense, _delta('sense')),
      _AbilityCell('運', character.stats.luck, _delta('luck')),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border, width: 0.5),
      ),
      child: Row(
        children: [for (final item in items) Expanded(child: item)],
      ),
    );
  }

  int _delta(String key) {
    if (previousStats == null) return 0;
    final cur = character.stats;
    final prev = previousStats!;
    switch (key) {
      case 'brain':
        return cur.brain - prev.brain;
      case 'body':
        return cur.body - prev.body;
      case 'social':
        return cur.social - prev.social;
      case 'sense':
        return cur.sense - prev.sense;
      case 'luck':
        return cur.luck - prev.luck;
    }
    return 0;
  }

  Widget _resultRow() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border, width: 0.5),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _resultChip(ResultKind.status, character.results.status),
          _resultChip(ResultKind.happiness, character.results.happiness),
          _resultChip(ResultKind.health, character.results.health),
          _resultChip(ResultKind.humanity, character.results.humanity),
        ],
      ),
    );
  }

  Widget _resultChip(ResultKind kind, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(kind.display,
            style: const TextStyle(fontSize: 11, color: AppPalette.textSub)),
        const SizedBox(width: 4),
        Text(value.toString(),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: AppPalette.textMain)),
      ],
    );
  }

  static String _formatMoney(int yen) {
    if (yen.abs() >= 100000000) {
      return '¥${(yen / 100000000).toStringAsFixed(2)}億';
    }
    if (yen.abs() >= 10000) {
      return '¥${(yen / 10000).round()}万';
    }
    return '¥$yen';
  }
}

class _AbilityCell extends StatelessWidget {
  final String name;
  final int value;
  final int delta;

  const _AbilityCell(this.name, this.value, this.delta);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name,
            style: const TextStyle(fontSize: 9, color: AppPalette.textSub)),
        const SizedBox(height: 2),
        Text(value.toString(),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppPalette.textMain)),
        if (delta != 0)
          Text(
            (delta > 0 ? '+' : '') + delta.toString(),
            style: TextStyle(
              fontSize: 9,
              color: delta > 0 ? AppPalette.plus : AppPalette.minus,
            ),
          ),
      ],
    );
  }
}
