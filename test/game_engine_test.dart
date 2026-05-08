// ============================================================
// GameEngine ユニットテスト
// ============================================================
import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/engines/economy_engine.dart';
import 'package:capitalism_game/domain/engines/event_resolver.dart';
import 'package:capitalism_game/domain/engines/game_engine.dart';
import 'package:capitalism_game/domain/models/character.dart';
import 'package:flutter_test/flutter_test.dart';

Character _testChar({
  Era era = Era.reiwa,
  int age = 30,
  int health = 100,
  int humanity = 0,
  List<String> giftsUnlocked = const [],
}) {
  return Character(
    id: 't',
    name: 'テスト',
    gender: Gender.male,
    strength: AbilityKind.brain,
    avatar: const Avatar(),
    parent: const ParentInfo(),
    era: era,
    age: age,
    stats: const Stats(brain: 50, body: 50, social: 50, sense: 50, luck: 50),
    results: Results(health: health, humanity: humanity, asset: 0, status: 30, happiness: 50),
    giftsUnlocked: giftsUnlocked,
  );
}

GameEngine _engine({int seed = 42}) {
  return GameEngine(
    eventResolver: EventResolver(events: const []),
    economy: EconomyEngine(seed: seed),
    seed: seed,
  );
}

void main() {
  group('GameEngine.expectedLifespan', () {
    test('令和・健康度50・ニュートラル・頭脳強み → 87歳', () {
      // base 84 + 強み(brain)+3 = 87
      final c = _testChar(era: Era.reiwa, health: 50);
      expect(GameEngine.expectedLifespan(c), 87);
    });

    test('健康度100 → +15歳補正で 102歳', () {
      // base 84 + health+15 + 強み+3 = 102
      final c = _testChar(era: Era.reiwa, health: 100);
      expect(GameEngine.expectedLifespan(c), 102);
    });

    test('健康度0 → -15歳補正で 72歳', () {
      // base 84 + health-15 + 強み+3 = 72
      final c = _testChar(era: Era.reiwa, health: 0);
      expect(GameEngine.expectedLifespan(c), 72);
    });

    test('人間性+50 → +5歳補正', () {
      // base 84 + humanity+5 + 強み+3 = 92
      final c = _testChar(era: Era.reiwa, humanity: 50, health: 50);
      expect(GameEngine.expectedLifespan(c), 92);
    });

    test('近未来＋健康度100＋不老 → 上限130', () {
      final c = _testChar(
          era: Era.future, health: 100, giftsUnlocked: ['不老']);
      // 90 + 15 + 0 + 20 + 強み(brain)+3 = 128 → 上限130内
      expect(GameEngine.expectedLifespan(c), 128);
    });

    test('期待寿命の上限は通常115、不老で130', () {
      // 健康度100＋人間性+50＋富裕（asset>=1億）でテスト
      final c = Character(
        id: 't',
        name: 't',
        gender: Gender.male,
        strength: AbilityKind.brain,
        avatar: const Avatar(),
        parent: const ParentInfo(),
        era: Era.future,
        age: 0,
        stats: const Stats(),
        results: const Results(asset: 200000000, health: 100, humanity: 50, status: 80, happiness: 90),
        giftsUnlocked: const ['不老'],
      );
      // 90 + 15 + 5 + 20 + 5 = 135 → 上限130
      expect(GameEngine.expectedLifespan(c), 130);
    });
  });

  group('GameEngine.advanceTurn', () {
    test('1ターン進めると age+1, yearIndex+1', () {
      final eng = _engine();
      final c = _testChar(age: 30);
      final result = eng.advanceTurn(c);
      expect(result.character.age, 31);
      expect(result.character.yearIndex, 1);
      expect(result.died, false);
    });

    test('健康度0なら死亡判定が発火', () {
      final eng = _engine();
      final c = _testChar(age: 30, health: 0);
      final result = eng.advanceTurn(c);
      expect(result.died, true);
    });

    test('100歳超なら強制死亡（不老なし）', () {
      final eng = _engine();
      final c = _testChar(age: 115);
      final result = eng.advanceTurn(c);
      expect(result.died, true);
    });

    test('アクション効果で能力が上がる', () {
      final eng = _engine();
      final c = _testChar(age: 30);
      final result = eng.advanceTurn(c, actionEffects: {'頭脳': 5});
      expect(result.character.stats.brain, greaterThan(c.stats.brain));
    });
  });

  group('GameEngine.adjustedLuck', () {
    test('人間性+50 で実効運+25（v1.3 係数 ÷2）', () {
      // 50 / 2 = 25
      final c = _testChar(humanity: 50);
      expect(GameEngine.adjustedLuck(c), c.stats.luck + 25);
    });

    test('人間性0 で補正なし', () {
      final c = _testChar(humanity: 0);
      expect(GameEngine.adjustedLuck(c), c.stats.luck);
    });

    test('人間性30 で実効運+15', () {
      // 30 / 2 = 15
      final c = _testChar(humanity: 30);
      expect(GameEngine.adjustedLuck(c), c.stats.luck + 15);
    });
  });
}
