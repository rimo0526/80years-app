// ============================================================
// SCR-02〜05 + SCR-08 キャラクター作成 5ステップ
// GDD §4.1.1 / §7.1.2
// ============================================================
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/constants/enums.dart';
import '../../domain/models/character.dart';
import '../../domain/services/character_factory.dart';
import '../../domain/services/parent_roller.dart';
import '../providers/game_providers.dart';
import '../widgets/avatar_picker.dart';

enum CreateStep { gender, strength, avatar, parent, era }

class CharacterCreateScreen extends ConsumerWidget {
  final CreateStep step;
  const CharacterCreateScreen({required this.step, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepNum = step.index + 1;
    return Scaffold(
      backgroundColor: AppPalette.bgInner,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $stepNum / 5',
                style: const TextStyle(fontSize: 12, color: AppPalette.textSub),
              ),
              const SizedBox(height: 8),
              Text(_titleOf(step), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Expanded(child: _buildStepBody(context, ref)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _goBack(context),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleOf(CreateStep s) {
    switch (s) {
      case CreateStep.gender:
        return 'あなたは？';
      case CreateStep.strength:
        return 'あなたの強みは？';
      case CreateStep.avatar:
        return '顔を選ぶ';
      case CreateStep.parent:
        return '親ガチャ';
      case CreateStep.era:
        return '時代を選ぶ';
    }
  }

  Widget _buildStepBody(BuildContext context, WidgetRef ref) {
    switch (step) {
      case CreateStep.gender:
        return _GenderStep();
      case CreateStep.strength:
        return _StrengthStep();
      case CreateStep.avatar:
        return _AvatarStep();
      case CreateStep.parent:
        return _ParentStep();
      case CreateStep.era:
        return _EraStep();
    }
  }

  void _goBack(BuildContext context) {
    switch (step) {
      case CreateStep.gender:
        context.go(AppRoute.title);
        break;
      case CreateStep.strength:
        context.go(AppRoute.createGender);
        break;
      case CreateStep.avatar:
        context.go(AppRoute.createStrength);
        break;
      case CreateStep.parent:
        context.go(AppRoute.createAvatar);
        break;
      case CreateStep.era:
        context.go(AppRoute.createParent);
        break;
    }
  }
}

class _GenderStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(charDraftProvider);
    return Row(
      children: [
        for (final g in [Gender.male, Gender.female])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _OptCard(
                icon: g.label,
                name: g.label,
                sub: '${g == Gender.male ? "男性" : "女性"}として人生開始',
                selected: draft.gender == g.label,
                onTap: () {
                  ref.read(charDraftProvider.notifier).update(
                        (s) => s.copyWith(gender: g.label),
                      );
                  context.go(AppRoute.createStrength);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _StrengthStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(charDraftProvider);
    final items = [
      ['頭脳', '脳', '勉強・研究で活躍'],
      ['肉体', '体', 'スポーツ・長寿'],
      ['コミュ', '話', '人脈・営業'],
      ['センス', '芸', '芸術・経営感覚'],
      ['運', '運', '人生の分岐に有利'],
    ];
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 0.95,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final i in items)
          _OptCard(
            icon: i[1],
            name: i[0],
            sub: i[2],
            selected: draft.strength == i[0],
            onTap: () {
              ref.read(charDraftProvider.notifier).update(
                    (s) => s.copyWith(strength: i[0]),
                  );
              context.go(AppRoute.createAvatar);
            },
          ),
      ],
    );
  }
}

class _AvatarStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(charDraftProvider);
    final value = AvatarPickerValue(
      hairId: draft.hairId,
      hairColorId: draft.hairColorId,
      eyeId: draft.eyeId,
      outlineId: draft.outlineId,
      skinId: draft.skinId,
    );
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: AvatarPicker(
              value: value,
              onChanged: (v) {
                ref.read(charDraftProvider.notifier).update((s) => s.copyWith(
                      hairId: v.hairId,
                      hairColorId: v.hairColorId,
                      eyeId: v.eyeId,
                      outlineId: v.outlineId,
                      skinId: v.skinId,
                      avatarId: v.skinId, // 互換のため
                    ));
              },
              onRandomize: () {
                final rnd = math.Random();
                ref.read(charDraftProvider.notifier).update((s) => s.copyWith(
                      hairId: rnd.nextInt(8),
                      hairColorId: rnd.nextInt(6),
                      eyeId: rnd.nextInt(6),
                      outlineId: rnd.nextInt(4),
                      skinId: rnd.nextInt(4),
                    ));
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.go(AppRoute.createParent),
          child: const Text('次へ'),
        ),
      ],
    );
  }
}

class _ParentStep extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ParentStep> createState() => _ParentStepState();
}

class _ParentStepState extends ConsumerState<_ParentStep> {
  ParentRollResult? _current;
  int _rerollCount = 0;
  static const int _maxReroll = 3;

  @override
  void initState() {
    super.initState();
    _roll();
  }

  void _roll() {
    final draft = ref.read(charDraftProvider);
    final era = Era.fromString(draft.era ?? '令和');
    final roller = ParentRoller();
    setState(() {
      _current = roller.roll(era);
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _current;
    if (result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppPalette.goldBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.info.rarity,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppPalette.goldText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('父：${result.info.fatherJob}',
                        style: const TextStyle(fontSize: 13)),
                    Text('母：${result.info.motherJob}',
                        style: const TextStyle(fontSize: 13)),
                    Text('世帯：${result.info.wealthClass}',
                        style: const TextStyle(fontSize: 13)),
                    if (result.info.personality.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('性格：${result.info.personality.join("、")}',
                          style: const TextStyle(fontSize: 12, color: AppPalette.textSub)),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('初期所持金',
                            style: TextStyle(fontSize: 12, color: AppPalette.textSub)),
                        Text(
                          _formatYen(result.initialAsset),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppPalette.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(result.description,
                        style: const TextStyle(fontSize: 12, color: AppPalette.textMain)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_rerollCount < _maxReroll)
          OutlinedButton(
            onPressed: () {
              setState(() => _rerollCount++);
              _roll();
            },
            child: Text('もう一度引く（残り ${_maxReroll - _rerollCount}）'),
          ),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () {
            // 親情報を draft に確定
            ref.read(charDraftProvider.notifier).update((s) => s.copyWith(
                  parent: {
                    'rarity': result.info.rarity,
                    'father_job': result.info.fatherJob,
                    'mother_job': result.info.motherJob,
                    'wealth_class': result.info.wealthClass,
                    'genetic_modifier': result.info.geneticModifier,
                    'initial_asset': result.initialAsset,
                  },
                ));
            context.go(AppRoute.createEra);
          },
          child: const Text('この家庭で確定'),
        ),
      ],
    );
  }

  static String _formatYen(int yen) {
    if (yen.abs() >= 100000000) return '¥${(yen / 100000000).toStringAsFixed(2)}億';
    if (yen.abs() >= 10000) return '¥${(yen / 10000).round()}万';
    return '¥$yen';
  }
}

class _EraStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(charDraftProvider);
    return Column(
      children: [
        const Text(
          '選んだ時代の世界観が80年間ずっと続きます。\n各時代は独立した「並行世界」です。',
          style: TextStyle(fontSize: 12, color: AppPalette.textSub),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final era in Era.values)
                _EraCard(
                  era: era,
                  selected: draft.era == era.label,
                  onTap: () {
                    ref
                        .read(charDraftProvider.notifier)
                        .update((s) => s.copyWith(era: era.label));
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: draft.era == null
              ? null
              : () => _startGame(context, ref),
          child: const Text('この時代で人生開始'),
        ),
      ],
    );
  }
}

/// startGame：draft → Character 生成 → メインゲーム画面へ
void _startGame(BuildContext context, WidgetRef ref) {
  final draft = ref.read(charDraftProvider);
  if (!draft.isComplete) return;

  final genetic = (draft.parent?['genetic_modifier'] as Map?)
          ?.map((k, v) => MapEntry(k as String, (v as num).toInt()));
  final initialAsset =
      (draft.parent?['initial_asset'] as int?) ?? 50000;

  final char = CharacterFactory.createFromDraft(
    gender: Gender.fromString(draft.gender) ?? Gender.male,
    strength:
        AbilityKind.fromString(draft.strength) ?? AbilityKind.brain,
    avatarId: draft.skinId,
    era: Era.fromString(draft.era ?? '令和'),
    name: draft.gender == '男' ? '山田 太郎' : '山田 花子',
    geneticBonus: genetic,
  );

  // 初期所持金を反映
  final updated = char.copyWith(
    results: char.results.copyWith(asset: initialAsset),
    avatar: Avatar(
      hairId: draft.hairId,
      hairColorId: draft.hairColorId,
      eyeId: draft.eyeId,
      outlineId: draft.outlineId,
      skinId: draft.skinId,
    ),
  );

  ref.read(characterProvider.notifier).start(updated);
  context.go(AppRoute.main);
}

class _EraCard extends StatelessWidget {
  final Era era;
  final bool selected;
  final VoidCallback onTap;

  const _EraCard({
    required this.era,
    required this.selected,
    required this.onTap,
  });

  String get _catch {
    switch (era) {
      case Era.showa:
        return '終身雇用と家族第一';
      case Era.heisei:
        return '価値観の揺らぎ';
      case Era.reiwa:
        return '多様化と不確実性';
      case Era.future:
        return 'AIと長寿の時代';
    }
  }

  String get _difficulty {
    switch (era) {
      case Era.showa:
        return '中';
      case Era.heisei:
        return '高';
      case Era.reiwa:
        return '中';
      case Era.future:
        return '低〜中';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppPalette.accentBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppPalette.accent : AppPalette.border,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(era.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 4),
              Text(_catch,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                '難度：$_difficulty　基本期待寿命：${era.baseLifespan}歳',
                style:
                    const TextStyle(fontSize: 11, color: AppPalette.textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptCard extends StatelessWidget {
  final String icon;
  final String name;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _OptCard({
    required this.icon,
    required this.name,
    required this.sub,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppPalette.accentBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppPalette.accent : AppPalette.border,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                )),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(sub,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 11, color: AppPalette.textSub)),
            ],
          ],
        ),
      ),
    );
  }
}
