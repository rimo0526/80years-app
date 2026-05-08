// ============================================================
// AchievementEvaluator のユニットテスト
// 主要パターン10件＋手動マッピング2件をカバー
// ============================================================
import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/models/character.dart';
import 'package:capitalism_game/domain/models/achievement_definition.dart';
import 'package:capitalism_game/domain/services/achievement_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AchievementEvaluator パターン解析', () {
    Character baseChar({
      int age = 30,
      int asset = 0,
      int status = 50,
      int happy = 50,
      int health = 80,
      int humanity = 0,
    }) =>
        Character(
          id: 't',
          name: 't',
          gender: Gender.male,
          strength: AbilityKind.brain,
          avatar: const Avatar(),
          parent: const ParentInfo(),
          era: Era.reiwa,
          age: age,
          results: Results(
            asset: asset,
            status: status,
            happiness: happy,
            health: health,
            humanity: humanity,
          ),
        );

    AchievementDefinition makeDef(String id, String cond) =>
        AchievementDefinition(
          id: id,
          category: 'test',
          grade: AchievementGrade.bronze,
          title: 't',
          description: 'd',
          unlockCondition: cond,
          applicableEras: const ['全時代'],
          reward: '',
        );

    test('資産>=1000万円相当 → 1000万円で達成', () {
      final ev = AchievementEvaluator([makeDef('A-001', '資産>=1000万円相当')]);
      final state = GameStateSummary(character: baseChar(asset: 10000000));
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.newlyUnlocked, ['A-001']);
    });

    test('資産>=1億円相当 → 1億円で達成', () {
      final ev = AchievementEvaluator([makeDef('A-002', '資産>=1億円相当')]);
      final state = GameStateSummary(character: baseChar(asset: 100000000));
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.newlyUnlocked, ['A-002']);
    });

    test('地位>=80', () {
      final ev = AchievementEvaluator([makeDef('A-003', '社会的地位>=80')]);
      final state = GameStateSummary(character: baseChar(status: 80));
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.newlyUnlocked, ['A-003']);
    });

    test('20歳到達', () {
      final ev = AchievementEvaluator([makeDef('A-004', '20歳到達＋大学進学ルート')]);
      final state = GameStateSummary(character: baseChar(age: 20));
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.newlyUnlocked, ['A-004']);
    });

    test('マイルストーン「結婚」発火', () {
      final ev = AchievementEvaluator(
          [makeDef('A-005', 'マイルストーン「結婚」発火')]);
      final state = GameStateSummary(
        character: baseChar(),
        milestoneCounts: const {'結婚': 1},
      );
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.newlyUnlocked, ['A-005']);
    });

    test('出産マイルストーン3回以上', () {
      final ev = AchievementEvaluator(
          [makeDef('A-006', '出産マイルストーン3回以上')]);
      final state = GameStateSummary(
        character: baseChar(),
        milestoneCounts: const {'出産': 3},
      );
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.newlyUnlocked, ['A-006']);
    });

    test('L-005 イベント発火', () {
      final ev = AchievementEvaluator(
          [makeDef('A-007', 'L-005「親の介護必要に」発火')]);
      final state = GameStateSummary(
        character: baseChar(),
        firedEventIds: const {'L-005'},
      );
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.newlyUnlocked, ['A-007']);
    });

    test('既に解放済は重複解放されない', () {
      final ev = AchievementEvaluator(
          [makeDef('A-008', '20歳到達')]);
      final state = GameStateSummary(character: baseChar(age: 25));
      final r = ev.evaluate(state: state, alreadyUnlocked: const {'A-008'});
      expect(r.newlyUnlocked, isEmpty);
    });

    test('死亡時、社会的地位>=80', () {
      final ev = AchievementEvaluator(
          [makeDef('A-011', '死亡時、社会的地位>=80')]);
      final alive = GameStateSummary(character: baseChar(status: 80));
      final dead = GameStateSummary(
          character: baseChar(status: 80), deathAge: 75, deathCause: '老衰');
      expect(ev.evaluate(state: alive, alreadyUnlocked: const {}).newlyUnlocked,
          isEmpty);
      expect(ev.evaluate(state: dead, alreadyUnlocked: const {}).newlyUnlocked,
          ['A-011']);
    });

    test('周回5代達成（手動マッピング）', () {
      final ev = AchievementEvaluator([
        AchievementDefinition(
          id: 'A-023',
          category: '家族',
          grade: AchievementGrade.platinum,
          title: '五代継承',
          description: 'd',
          unlockCondition: '周回5代達成',
          applicableEras: const ['全時代'],
          reward: '',
        ),
      ]);
      final state5 = GameStateSummary(character: baseChar(), generation: 5);
      final state4 = GameStateSummary(character: baseChar(), generation: 4);
      expect(ev.evaluate(state: state5, alreadyUnlocked: const {}).newlyUnlocked,
          ['A-023']);
      expect(ev.evaluate(state: state4, alreadyUnlocked: const {}).newlyUnlocked,
          isEmpty);
    });

    test('解析不能な条件は unparsedConditions に入る', () {
      final ev = AchievementEvaluator([
        makeDef('A-999', 'なんかうまく言えない条件'),
      ]);
      final state = GameStateSummary(character: baseChar());
      final r = ev.evaluate(state: state, alreadyUnlocked: const {});
      expect(r.unparsedConditions, contains('A-999'));
      expect(r.newlyUnlocked, isEmpty);
    });
  });
}
