// ============================================================
// SCR-06 メインゲーム画面 / GDD §12 本実装版
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/engines/game_engine.dart';
import '../../domain/models/character.dart';
import '../../domain/services/effect_parser.dart';
import '../providers/game_providers.dart';
import '../widgets/action_panel.dart';
import '../widgets/event_modal.dart';
import '../widgets/hud_widget.dart';

class MainGameScreen extends ConsumerStatefulWidget {
  const MainGameScreen({super.key});

  @override
  ConsumerState<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends ConsumerState<MainGameScreen> {
  Stats? _previousStats;
  final List<String> _log = [];
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    if (character == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoute.title);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppPalette.bgInner,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              HudWidget(
                character: character,
                previousStats: _previousStats,
              ),
              const SizedBox(height: 8),
              _sceneCard(character),
              const SizedBox(height: 8),
              if (_log.isNotEmpty) _logBox(),
              Expanded(
                child: SingleChildScrollView(
                  child: _busy
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : ActionPanel(
                          character: character,
                          onSelected: _onActionSelected,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sceneCard(Character c) {
    final season = GameEngine.seasonOfAge(c.age);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.bgSub,
              border: Border.all(color: AppPalette.border, width: 0.5),
            ),
            child: Center(
              child: Text(
                _moodEmoji(c.results.happiness),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.era.label}・$season の風',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPalette.textSub,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _flavorOf(c),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPalette.textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _moodEmoji(int happiness) {
    if (happiness >= 65) return '🙂';
    if (happiness <= 30) return '😟';
    return '😐';
  }

  String _flavorOf(Character c) {
    if (c.age <= 6) return '幼い日々を過ごす。';
    if (c.age <= 12) return '小学生として友達と遊ぶ毎日。';
    if (c.age <= 15) return '思春期の入り口。';
    if (c.age <= 18) return '進路決定の時期が近い。';
    if (c.age <= 22) return '大学・専門・就職の岐路。';
    if (c.age <= 40) return '社会人としての日々。';
    if (c.age <= 60) return '人生の中盤、責任が増えた。';
    return '老年期、ゆっくり過ごす日々。';
  }

  Widget _logBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 80),
      decoration: BoxDecoration(
        color: AppPalette.bgSub,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in _log.take(6))
              Text(line, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _onActionSelected(ActionDef action) async {
    final character = ref.read(characterProvider);
    if (character == null) return;

    setState(() {
      _busy = true;
      _previousStats = character.stats;
    });

    final result = ref
        .read(characterProvider.notifier)
        .advance(actionEffects: action.effects);

    if (result == null) {
      setState(() => _busy = false);
      return;
    }

    setState(() {
      _log.insert(0, '${action.label}：${character.age}歳');
      if (_log.length > 6) _log.removeRange(6, _log.length);
    });

    if (result.died) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go(AppRoute.ending);
      return;
    }

    if (result.firedEvent != null && mounted) {
      final ev = result.firedEvent!;
      final selected = await showEventModal(context, ev);
      if (selected != null && selected >= 0 && selected < ev.choices.length) {
        final choice = ev.choices[selected];
        // 効果テキストをパースして Character に反映
        final parsed = EffectParser.parse(choice.effectText);
        ref.read(characterProvider.notifier).applyEventEffect(
              parsed.effects,
              flags: parsed.flagsToSet,
            );
        setState(() {
          _log.insert(0, '${ev.name} → ${choice.label}');
          if (_log.length > 6) _log.removeRange(6, _log.length);
        });
      }
    }

    if (mounted) setState(() => _busy = false);
  }
}
