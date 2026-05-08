// ============================================================
// Riverpod プロバイダー集約 / GDD §17.3.4 状態管理層
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engines/economy_engine.dart';
import '../../domain/engines/event_resolver.dart';
import '../../domain/engines/game_engine.dart';
import '../../domain/models/character.dart';
import '../../domain/models/event_definition.dart';
import '../../domain/models/game_save_data.dart';

/// マスターデータ：events.json から読み込んだ全イベント
/// main.dart で override される
final eventDefinitionsProvider = Provider<List<EventDefinition>>((ref) {
  return const [];
});

/// EventResolver
final eventResolverProvider = Provider<EventResolver>((ref) {
  final events = ref.watch(eventDefinitionsProvider);
  return EventResolver(events: events);
});

/// EconomyEngine
final economyEngineProvider = Provider<EconomyEngine>((ref) {
  return EconomyEngine();
});

/// GameEngine（依存注入で組み立て）
final gameEngineProvider = Provider<GameEngine>((ref) {
  return GameEngine(
    eventResolver: ref.watch(eventResolverProvider),
    economy: ref.watch(economyEngineProvider),
  );
});

/// 現在のキャラクター state
class CharacterNotifier extends StateNotifier<Character?> {
  final GameEngine _engine;
  CharacterNotifier(this._engine) : super(null);

  void start(Character c) => state = c;

  /// 1ターン進める
  TurnResult? advance({Map<String, int>? actionEffects}) {
    final cur = state;
    if (cur == null) return null;
    final result = _engine.advanceTurn(cur, actionEffects: actionEffects);
    state = result.character;
    return result;
  }

  /// イベント結果（選択肢の効果）をキャラに反映
  void applyEventEffect(Map<String, int> effects, {List<String>? flags}) {
    final cur = state;
    if (cur == null) return;
    var stats = cur.stats;
    var results = cur.results;

    for (final entry in effects.entries) {
      final delta = entry.value;
      switch (entry.key) {
        case '頭脳':
          stats = stats.copyWith(brain: (stats.brain + delta).clamp(0, 100));
          break;
        case '肉体':
          stats = stats.copyWith(body: (stats.body + delta).clamp(0, 100));
          break;
        case 'コミュ':
          stats = stats.copyWith(social: (stats.social + delta).clamp(0, 100));
          break;
        case 'センス':
          stats = stats.copyWith(sense: (stats.sense + delta).clamp(0, 100));
          break;
        case '運':
          stats = stats.copyWith(luck: (stats.luck + delta).clamp(0, 100));
          break;
        case '資産':
          results = results.copyWith(asset: results.asset + delta);
          break;
        case '幸福':
          results = results.copyWith(
              happiness: (results.happiness + delta).clamp(0, 100));
          break;
        case '健康':
          results = results.copyWith(
              health: (results.health + delta).clamp(0, 100));
          break;
        case '地位':
          results = results.copyWith(
              status: (results.status + delta).clamp(0, 100));
          break;
        case '人間性':
          results = results.copyWith(
              humanity: (results.humanity + delta).clamp(-50, 50));
          break;
      }
    }

    final newFlags = Map<String, dynamic>.from(cur.flags);
    if (flags != null) {
      for (final f in flags) {
        newFlags[f] = true;
      }
    }

    state = cur.copyWith(stats: stats, results: results, flags: newFlags);
  }

  void reset() => state = null;
}

final characterProvider =
    StateNotifierProvider<CharacterNotifier, Character?>((ref) {
  return CharacterNotifier(ref.watch(gameEngineProvider));
});

/// セーブデータ全体（character以外も含む）
final saveDataProvider = StateProvider<GameSaveData>((ref) {
  return GameSaveData.fresh();
});

/// キャラクター作成中の draft
class CharDraft {
  final String? gender;
  final String? strength;
  final int? avatarId;       // legacy（簡易プリセット）
  final int hairId;
  final int hairColorId;
  final int eyeId;
  final int outlineId;
  final int skinId;
  final Map<String, dynamic>? parent;
  final String? era;

  const CharDraft({
    this.gender,
    this.strength,
    this.avatarId,
    this.hairId = 0,
    this.hairColorId = 0,
    this.eyeId = 0,
    this.outlineId = 0,
    this.skinId = 0,
    this.parent,
    this.era,
  });

  CharDraft copyWith({
    String? gender,
    String? strength,
    int? avatarId,
    int? hairId,
    int? hairColorId,
    int? eyeId,
    int? outlineId,
    int? skinId,
    Map<String, dynamic>? parent,
    String? era,
  }) {
    return CharDraft(
      gender: gender ?? this.gender,
      strength: strength ?? this.strength,
      avatarId: avatarId ?? this.avatarId,
      hairId: hairId ?? this.hairId,
      hairColorId: hairColorId ?? this.hairColorId,
      eyeId: eyeId ?? this.eyeId,
      outlineId: outlineId ?? this.outlineId,
      skinId: skinId ?? this.skinId,
      parent: parent ?? this.parent,
      era: era ?? this.era,
    );
  }

  bool get isComplete =>
      gender != null && strength != null && era != null;
}

final charDraftProvider = StateProvider<CharDraft>((ref) => const CharDraft());
