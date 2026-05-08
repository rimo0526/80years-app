// ============================================================
// EventResolver ユニットテスト
// ============================================================
import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/engines/event_resolver.dart';
import 'package:capitalism_game/domain/models/character.dart';
import 'package:capitalism_game/domain/models/event_definition.dart';
import 'package:flutter_test/flutter_test.dart';

Character _testChar({
  Era era = Era.reiwa,
  int age = 30,
  Stats? stats,
}) {
  return Character(
    id: 't_001',
    name: 'テスト',
    gender: Gender.male,
    strength: AbilityKind.brain,
    avatar: const Avatar(),
    parent: const ParentInfo(),
    era: era,
    age: age,
    stats: stats ?? const Stats(brain: 50, body: 50, social: 50, sense: 50, luck: 50),
  );
}

EventDefinition _evt({
  String id = 'L-001',
  String category = '健康・病気',
  String? rate = '年5%',
  int? minAge,
  int? maxAge,
  List<String> applicableEras = const ['全時代'],
  bool isHidden = false,
  int priority = 60,
  String? chainFrom,
}) {
  return EventDefinition(
    id: id,
    sheet: 'ライフイベント',
    category: category,
    name: 'テストイベント $id',
    description: '説明',
    condition: TriggerCondition(minAge: minAge, maxAge: maxAge),
    rate: TriggerRate.parse(rate),
    choices: const [
      EventChoice(label: 'A', effectText: 'a'),
      EventChoice(label: 'B', effectText: 'b'),
    ],
    applicableEras: applicableEras,
    isHidden: isHidden,
    priority: priority,
    chainFrom: chainFrom,
  );
}

void main() {
  group('TriggerRate.parse', () {
    test('「年5%」 → 月率 約0.00417', () {
      final r = TriggerRate.parse('年5%');
      expect(r.kind, TriggerRateKind.yearly);
      expect(r.monthlyRate, closeTo(0.05 / 12, 1e-6));
    });

    test('「月3%」 → 月率 0.03', () {
      final r = TriggerRate.parse('月3%');
      expect(r.kind, TriggerRateKind.monthly);
      expect(r.monthlyRate, closeTo(0.03, 1e-6));
    });

    test('「必発」 → kind=always', () {
      final r = TriggerRate.parse('必発');
      expect(r.kind, TriggerRateKind.always);
      expect(r.monthlyRate, 1.0);
    });

    test('「条件発動」 → kind=conditional', () {
      final r = TriggerRate.parse('条件発動');
      expect(r.kind, TriggerRateKind.conditional);
    });
  });

  group('TriggerCondition.parse', () {
    test('「30歳〜」 → minAge=30', () {
      final c = TriggerCondition.parse('30歳〜 / 体力<50で発生率↑');
      expect(c.minAge, 30);
      expect(c.maxAge, isNull);
    });

    test('「20歳〜25歳」 → range', () {
      final c = TriggerCondition.parse('20歳〜25歳');
      expect(c.minAge, 20);
      expect(c.maxAge, 25);
    });

    test('matchesAge は範囲チェック', () {
      final c = TriggerCondition(minAge: 30, maxAge: 60);
      expect(c.matchesAge(40), true);
      expect(c.matchesAge(20), false);
      expect(c.matchesAge(70), false);
    });
  });

  group('EventResolver', () {
    test('時代外のイベントは候補から除外', () {
      final resolver = EventResolver(
        events: [
          _evt(id: 'L-001', applicableEras: ['昭和']),
          _evt(id: 'L-002', applicableEras: ['全時代']),
        ],
        seed: 42,
      );
      final c = _testChar(era: Era.reiwa, age: 30);
      // L-001 は除外、L-002 のみ候補
      // 確率発火なので毎回ヒットするわけではないが、
      // resolve実行が問題なく動くこと
      final result = resolver.resolveMonthly(c, 360);
      // L-001 が発火することはない
      expect(result.event?.id, isNot('L-001'));
    });

    test('年齢条件外は除外', () {
      final resolver = EventResolver(
        events: [
          _evt(id: 'L-100', minAge: 50),
        ],
        seed: 42,
      );
      final c = _testChar(age: 30);
      // 何度回しても L-100 は発火しないはず
      var fired = false;
      for (var i = 0; i < 100; i++) {
        final r = resolver.resolveMonthly(c, 360 + i);
        if (r.event != null) fired = true;
      }
      expect(fired, false);
    });

    test('必発イベントは確実に発火', () {
      final resolver = EventResolver(
        events: [
          _evt(id: 'T-001', rate: '時代必発', priority: 10),
        ],
        seed: 42,
      );
      final c = _testChar();
      final r = resolver.resolveMonthly(c, 360);
      expect(r.event?.id, 'T-001');
    });

    test('クールダウン後は再発火可能', () {
      final resolver = EventResolver(
        events: [
          _evt(id: 'T-001', rate: '時代必発'),
        ],
        seed: 42,
      );
      final c = _testChar();
      // 1ターン目で発火
      resolver.resolveMonthly(c, 100);
      // 同IDは12ヶ月CD
      final r2 = resolver.resolveMonthly(c, 105);
      expect(r2.event, isNull);
      // 12ヶ月後は発火可能
      final r3 = resolver.resolveMonthly(c, 113);
      expect(r3.event?.id, 'T-001');
    });

    test('連鎖イベントは自然発火しない', () {
      final resolver = EventResolver(
        events: [
          _evt(id: 'I-021', rate: '条件発動', chainFrom: 'L-008'),
        ],
        seed: 42,
      );
      final c = _testChar();
      var fired = false;
      for (var i = 0; i < 50; i++) {
        final r = resolver.resolveMonthly(c, 100 + i * 20);
        if (r.event != null) fired = true;
      }
      expect(fired, false);
      // resolveChain で発火可能
      final chained = resolver.resolveChain('L-008', c, 100);
      expect(chained?.id, 'I-021');
    });
  });
}
