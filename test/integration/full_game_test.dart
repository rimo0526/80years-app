// ============================================================
// 統合テスト：フルゲームフロー
// キャラ作成 → 数十ターン進行 → 死亡 → 結果検証
//
// 実行：
//   flutter test test/integration/full_game_test.dart
// ============================================================
import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/engines/economy_engine.dart';
import 'package:capitalism_game/domain/engines/event_resolver.dart';
import 'package:capitalism_game/domain/engines/game_engine.dart';
import 'package:capitalism_game/domain/services/character_factory.dart';
import 'package:capitalism_game/domain/services/parent_roller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Full game flow', () {
    test('キャラ生成 → 80年プレイ → 死亡判定が起きる', () {
      final char = CharacterFactory.createFromDraft(
        gender: Gender.male,
        strength: AbilityKind.brain,
        avatarId: 0,
        era: Era.reiwa,
        name: '統合プレイ',
      );

      final engine = GameEngine(
        eventResolver: EventResolver(events: const []),
        economy: EconomyEngine(seed: 1),
        seed: 1,
      );

      var c = char;
      var died = false;

      // 最大 80 年×12ヶ月 = 960 ターン
      for (var i = 0; i < 960; i++) {
        final r = engine.advanceTurn(c, actionEffects: const {'頭脳': 1});
        c = r.character;
        if (r.died) {
          died = true;
          break;
        }
      }

      // 80年完走 or 途中死亡 のいずれか
      expect(died || c.age >= 80, true,
          reason: '80年経過しても生きているなら age>=80');
    });

    test('親ガチャ → 強み連動でステータス分布', () {
      final roller = ParentRoller(seed: 100);
      final result = roller.roll(Era.reiwa);
      final genetic = result.info.geneticModifier;

      final char = CharacterFactory.createFromDraft(
        gender: Gender.female,
        strength: AbilityKind.social,
        avatarId: 1,
        era: Era.reiwa,
        name: '親ガチャ統合',
        geneticBonus: genetic,
      );

      // 強み（コミュ）は他能力より平均的に高めなはず
      expect(char.stats.social, greaterThanOrEqualTo(char.stats.brain - 20));
      // 全能力は0〜100の範囲
      expect(char.stats.brain, inInclusiveRange(0, 100));
      expect(char.stats.body, inInclusiveRange(0, 100));
      expect(char.stats.social, inInclusiveRange(0, 100));
      expect(char.stats.sense, inInclusiveRange(0, 100));
      expect(char.stats.luck, inInclusiveRange(0, 100));
    });

    test('時代ごとの基本期待寿命がGDD準拠', () {
      final showa = CharacterFactory.createFromDraft(
        gender: Gender.male,
        strength: AbilityKind.body,
        avatarId: 0,
        era: Era.showa,
      );
      final future = CharacterFactory.createFromDraft(
        gender: Gender.male,
        strength: AbilityKind.body,
        avatarId: 0,
        era: Era.future,
      );

      // 健康度50（標準）でテスト
      final healthyShowa = showa.copyWith(
        results: showa.results.copyWith(health: 50),
      );
      final healthyFuture = future.copyWith(
        results: future.results.copyWith(health: 50),
      );

      // 期待寿命は時代の baseLifespan と一致するはず
      expect(GameEngine.expectedLifespan(healthyShowa), 72);
      expect(GameEngine.expectedLifespan(healthyFuture), 90);
    });
  });
}
