// ============================================================
// CharacterFactory / GDD §4 キャラ作成
// draft（性別/強み/顔/親/時代）→ Character 生成
// ============================================================
import 'dart:math' as math;

import '../../core/constants/enums.dart';
import '../models/character.dart';

class CharacterFactory {
  static int _generateUuid() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// draft から Character を生成
  static Character createFromDraft({
    required Gender gender,
    required AbilityKind strength,
    required int avatarId,
    required Era era,
    String name = '名無し',
    int generation = 1,
    Map<String, int>? geneticBonus, // 周回継承による補正
  }) {
    final id = 'char_${_generateUuid()}';

    // GDD §4.2.3 初期能力：基礎値10 + 強みボーナス+15 + 親ガチャ±5
    final rng = math.Random();
    int parentMod() => rng.nextInt(11) - 5; // -5..+5

    var stats = Stats(
      brain: _calcInitial(strength == AbilityKind.brain, parentMod(), geneticBonus?['頭脳'] ?? 0),
      body: _calcInitial(strength == AbilityKind.body, parentMod(), geneticBonus?['肉体'] ?? 0),
      social: _calcInitial(strength == AbilityKind.social, parentMod(), geneticBonus?['コミュ'] ?? 0),
      sense: _calcInitial(strength == AbilityKind.sense, parentMod(), geneticBonus?['センス'] ?? 0),
      luck: _calcInitial(strength == AbilityKind.luck, parentMod(), geneticBonus?['運'] ?? 0),
    );

    // クランプ
    stats = Stats(
      brain: stats.brain.clamp(0, 100),
      body: stats.body.clamp(0, 100),
      social: stats.social.clamp(0, 100),
      sense: stats.sense.clamp(0, 100),
      luck: stats.luck.clamp(0, 100),
    );

    return Character(
      id: id,
      generation: generation,
      name: name,
      gender: gender,
      strength: strength,
      avatar: Avatar(skinId: avatarId.clamp(0, 5)),
      parent: const ParentInfo(),
      era: era,
      yearIndex: 0,
      age: 0,
      stats: stats,
      results: const Results(),
      flags: const {
        'married': false,
        'children': 0,
        'bankruptcy': false,
        'employed': false,
      },
    );
  }

  /// 初期能力値の計算（GDD §4.2.3）
  static int _calcInitial(bool isStrength, int parentMod, int geneticMod) {
    const base = 10;
    final strengthBonus = isStrength ? 15 : 0;
    return base + strengthBonus + parentMod + geneticMod;
  }
}
