// ============================================================
// EventResolver / GDD §10.2 イベント発火判定
//
// 責務：
//  - 全イベント一覧から、現キャラに発火可能なものをフィルタ
//  - applicable_eras / 年齢条件 / 既往フラグの評価
//  - 月次の確率判定（priority 順、クールダウン考慮）
//  - 連鎖イベント（chain_from）の処理
//  - 発火結果を返す
// ============================================================
import 'dart:math' as math;

import '../../core/constants/enums.dart';
import '../models/character.dart';
import '../models/event_definition.dart';

/// 直近発火履歴（クールダウン用）
class EventCooldownTracker {
  /// イベントID → 最後に発火した turn番号
  final Map<String, int> _lastFiredTurn = {};

  /// カテゴリ → 最後に発火した turn番号
  final Map<String, int> _lastFiredCategoryTurn = {};

  void recordFire(EventDefinition ev, int currentTurn) {
    _lastFiredTurn[ev.id] = currentTurn;
    _lastFiredCategoryTurn[ev.category] = currentTurn;
  }

  /// 直近12ヶ月以内に同IDが発火したか
  bool isSameIdCooldown(String id, int currentTurn) {
    final last = _lastFiredTurn[id];
    if (last == null) return false;
    return currentTurn - last < 12;
  }

  /// 直近3ヶ月以内に同カテゴリが発火したか（時代必発・隠しは除外）
  bool isSameCategoryCooldown(String category, int currentTurn) {
    final last = _lastFiredCategoryTurn[category];
    if (last == null) return false;
    return currentTurn - last < 3;
  }
}

/// 発火結果
class EventResolution {
  final EventDefinition? event;     // 発火したイベント（なければnull）
  final List<String> debugTrace;    // デバッグ用：候補一覧と判定結果

  const EventResolution({this.event, this.debugTrace = const []});
}

/// EventResolver：イベント発火判定エンジン
class EventResolver {
  final List<EventDefinition> _allEvents;
  final EventCooldownTracker _cooldown;
  final math.Random _random;

  EventResolver({
    required List<EventDefinition> events,
    EventCooldownTracker? cooldown,
    int? seed,
  })  : _allEvents = events,
        _cooldown = cooldown ?? EventCooldownTracker(),
        _random = math.Random(seed);

  /// 月次のイベント発火を判定（GDD §10.2.1 優先順位）
  /// currentTurn: キャラのターン数（age * 12 + month 等）
  EventResolution resolveMonthly(Character c, int currentTurn) {
    final candidates = _filterCandidates(c, currentTurn);
    if (candidates.isEmpty) return const EventResolution();

    // priority 順（小さいほど優先）にソート
    candidates.sort((a, b) => a.priority.compareTo(b.priority));

    final trace = <String>[];

    for (final ev in candidates) {
      // 月次率に補正をかけて判定
      final rate = _adjustedMonthlyRate(ev, c);

      // 必発は強制発火
      if (ev.rate.kind == TriggerRateKind.always) {
        _cooldown.recordFire(ev, currentTurn);
        trace.add('[FIRE-ALWAYS] ${ev.id} ${ev.name}');
        return EventResolution(event: ev, debugTrace: trace);
      }

      // 条件発動は外部トリガー専用なのでスキップ
      if (ev.rate.kind == TriggerRateKind.conditional) {
        trace.add('[SKIP-CONDITIONAL] ${ev.id}');
        continue;
      }

      final hit = _random.nextDouble() < rate;
      trace.add(
          '[${hit ? "FIRE" : "MISS"}] ${ev.id} ${ev.name} rate=${rate.toStringAsFixed(4)}');
      if (hit) {
        _cooldown.recordFire(ev, currentTurn);
        return EventResolution(event: ev, debugTrace: trace);
      }
    }

    return EventResolution(debugTrace: trace);
  }

  /// 連鎖イベントを発火（前イベントの結果から）
  /// GDD §10.3.4 連鎖イベント
  EventDefinition? resolveChain(String fromEventId, Character c, int currentTurn) {
    for (final ev in _allEvents) {
      if (ev.chainFrom == fromEventId &&
          ev.isAvailableInEra(c.era) &&
          ev.condition.matchesAge(c.age)) {
        _cooldown.recordFire(ev, currentTurn);
        return ev;
      }
    }
    return null;
  }

  /// 候補イベントをフィルタ
  List<EventDefinition> _filterCandidates(Character c, int currentTurn) {
    final result = <EventDefinition>[];

    for (final ev in _allEvents) {
      // 1. 時代制限チェック
      if (!ev.isAvailableInEra(c.era)) continue;

      // 2. 年齢条件
      if (!ev.condition.matchesAge(c.age)) continue;

      // 3. クールダウン（同ID 12ヶ月）
      if (_cooldown.isSameIdCooldown(ev.id, currentTurn)) continue;

      // 4. クールダウン（同カテゴリ 3ヶ月、ただし時代必発・隠しは抑制対象外）
      final categorySuppressible = ev.priority >= 50; // 確率系のみ抑制
      if (categorySuppressible &&
          _cooldown.isSameCategoryCooldown(ev.category, currentTurn)) {
        continue;
      }

      // 5. 連鎖イベントは自然発火させない（chain_from は外部トリガー専用）
      if (ev.chainFrom != null && ev.chainFrom!.isNotEmpty) continue;

      // 6. 隠しイベントの追加条件は将来 Phase 1 で詳細化
      //    現状は applicable_eras と年齢のみで判定

      result.add(ev);
    }
    return result;
  }

  /// 月次率に運・強み・時代補正を適用（GDD §10.2.4）
  double _adjustedMonthlyRate(EventDefinition ev, Character c) {
    var rate = ev.rate.monthlyRate;

    // 運による補正：±20%
    final luckBias = (c.stats.luck - 50) / 50 * 0.20;
    rate *= (1 + luckBias);

    // 強み一致で +10%
    if (_isStrengthMatch(ev, c)) {
      rate *= 1.10;
    }

    // 隠しイベントは発火率を控えめに（既に低い設定だがさらに抑制）
    if (ev.isHidden) {
      rate *= 0.5;
    }

    return rate.clamp(0, 1);
  }

  /// イベントカテゴリと強みが一致するか
  bool _isStrengthMatch(EventDefinition ev, Character c) {
    final cat = ev.category;
    switch (c.strength) {
      case AbilityKind.brain:
        return cat.contains('学') || cat.contains('知');
      case AbilityKind.body:
        return cat.contains('健康') || cat.contains('運動');
      case AbilityKind.social:
        return cat.contains('恋愛') || cat.contains('家族') || cat.contains('仕事');
      case AbilityKind.sense:
        return cat.contains('趣味') || cat.contains('創作') || cat.contains('投資');
      case AbilityKind.luck:
        return cat.contains('宗教') || cat.contains('運') || cat.contains('詐欺');
    }
  }
}
