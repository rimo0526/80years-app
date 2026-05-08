// ============================================================
// GameEngine 本実装 / GDD §8.1 月次ターン処理の中核
//
// 6段階フロー：
//  1. 初期化（プレイヤーアクション反映）
//  2. 家計（EconomyEngine 経由）
//  3. イベント発火（EventResolver 経由）
//  4. ステータス更新（ストレス・幸福度・健康度の月次変動）
//  5. 死亡判定（動的寿命システム v1.1）
//  6. スキルポイント計算
//
// 数値設計は GDD §5（ステータス）/ §8（月次）/ §9（家計）/ §10（イベント）に従う。
// ============================================================
import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../models/character.dart';
import '../models/event_definition.dart';
import 'economy_engine.dart';
import 'event_resolver.dart';

/// 月次ターン処理の結果
class TurnResult {
  final Character character;
  final EventDefinition? firedEvent;
  final MonthlyBalance? balance;
  final bool died;
  final String? deathCause;
  final int stressBefore;
  final int stressAfter;
  final List<String> log;

  const TurnResult({
    required this.character,
    this.firedEvent,
    this.balance,
    this.died = false,
    this.deathCause,
    this.stressBefore = 0,
    this.stressAfter = 0,
    this.log = const [],
  });
}

/// GameEngine：月次ターン処理を行う純粋ロジック
class GameEngine {
  final EventResolver _eventResolver;
  final EconomyEngine _economy;
  final math.Random _random;

  GameEngine({
    required EventResolver eventResolver,
    required EconomyEngine economy,
    int? seed,
  })  : _eventResolver = eventResolver,
        _economy = economy,
        _random = math.Random(seed);

  /// プロト用：依存なしのスタブを作る簡易ファクトリ
  factory GameEngine.empty() {
    return GameEngine(
      eventResolver: EventResolver(events: const []),
      economy: EconomyEngine(),
    );
  }

  /// 1ターン進める（GDD §8.1.1 6段階フロー）
  TurnResult advanceTurn(
    Character c, {
    Map<String, int>? actionEffects,
  }) {
    final log = <String>[];
    var next = c;

    // ============================================================
    // Step 1: プレイヤーアクション反映
    // ============================================================
    if (actionEffects != null) {
      next = _applyActionEffects(next, actionEffects);
      log.add('Step1: action effects applied');
    }

    // ============================================================
    // Step 2: 家計計算（EconomyEngine）
    // ============================================================
    final balance = _economy.computeMonthly(next);
    next = next.copyWith(
      results: next.results.copyWith(asset: next.results.asset + balance.netCashflow),
      flags: {
        ...next.flags,
        if (balance.bankrupt) 'bankruptcy': true,
        if (balance.bankrupt) 'bankruptcy_year': next.yearIndex,
      },
    );
    log.add('Step2: balance net=${balance.netCashflow}');

    // ============================================================
    // Step 3: イベント発火判定
    // ============================================================
    final currentTurn = next.age * 12 + (next.yearIndex % 12);
    final resolution = _eventResolver.resolveMonthly(next, currentTurn);
    final firedEvent = resolution.event;
    if (firedEvent != null) {
      log.add('Step3: event fired ${firedEvent.id} ${firedEvent.name}');
    }

    // ============================================================
    // Step 4: ステータス月次変動（GDD §5.4.3 / §5.5）
    // ============================================================
    next = _applyMonthlyStatChanges(next, balance);
    log.add('Step4: monthly stat changes applied');

    // ============================================================
    // Step 5: 加齢
    // ============================================================
    next = next.copyWith(age: next.age + 1, yearIndex: next.yearIndex + 1);

    // ============================================================
    // Step 6: 死亡判定（動的寿命 GDD §5.4.4 v1.1）
    // ============================================================
    final lifespan = expectedLifespan(next);
    final mortalityResult = _checkMortality(next, lifespan);
    if (mortalityResult.died) {
      log.add('Step6: died at age ${next.age} (${mortalityResult.cause})');
      return TurnResult(
        character: next,
        firedEvent: firedEvent,
        balance: balance,
        died: true,
        deathCause: mortalityResult.cause,
        log: log,
      );
    }

    // ============================================================
    // Step 7: スキルポイント獲得（GDD §6.4.2）
    // ============================================================
    next = _awardSkillPoints(next, actionEffects);

    return TurnResult(
      character: next,
      firedEvent: firedEvent,
      balance: balance,
      died: false,
      stressBefore: c.stress,
      stressAfter: next.stress,
      log: log,
    );
  }

  // ============================================================
  // 動的寿命計算（GDD §5.4.4 v1.1）
  // ============================================================

  /// 期待寿命を算出（v1.2 強みボーナス追加）
  static int expectedLifespan(Character c) {
    final base = c.era.baseLifespan;
    final healthMod = ((c.results.health - 50) / 50 * 15).round();
    final humanityMod = (c.results.humanity / 50 * 5).round();
    final skillMod = _skillLifespanBonus(c);
    final economyMod = _economyLifespanBonus(c);
    final strengthMod = _strengthLifespanBonus(c);
    final raw = base + healthMod + humanityMod + skillMod + economyMod + strengthMod;

    final hasImmortal = c.giftsUnlocked.contains('不老');
    return raw.clamp(50, hasImmortal ? kMaxAgeWithImmortal : kMaxAgeNormal);
  }

  /// 強みベースの寿命ボーナス（GDD §5.2 v1.2）
  /// sim v1 で肉体強み一強だったのを是正：
  ///   肉体は他で health を稼ぐ構造のため strengthMod は 0
  ///   他強みには +3〜+5 の補正で平均寿命差を縮小
  static int _strengthLifespanBonus(Character c) {
    switch (c.strength) {
      case AbilityKind.body:
        return 0; // 健康度経由で既に長寿傾向
      case AbilityKind.brain:
        return 3; // 知識・健康知識で +3
      case AbilityKind.social:
        return 4; // 人間関係で長寿（research-backed）
      case AbilityKind.sense:
        return 3; // 趣味活動で長寿
      case AbilityKind.luck:
        return 5; // 運が良い人は事故・大病が少ない
    }
  }

  static int _skillLifespanBonus(Character c) {
    var bonus = 0;
    final hasSkill = (id) => c.skillsUnlocked.contains(id);
    if (hasSkill('BODY_T1_01')) bonus += 3; // 健康習慣
    if (hasSkill('BODY_T2_01')) bonus += 2; // 食生活管理
    if (hasSkill('BRAIN_T2_01')) bonus += 5; // 医療知識
    if (hasSkill('SENSE_T1_03')) bonus += 3; // ヨガ
    if (hasSkill('BRAIN_T3_01')) bonus += 5; // 長寿研究（近未来）
    if (c.giftsUnlocked.contains('不老')) bonus += 20;
    return bonus;
  }

  static int _economyLifespanBonus(Character c) {
    if (c.results.asset >= 100000000) return 5;
    if ((c.flags['bankruptcy'] == true) && c.results.asset < 1000000) {
      return -5;
    }
    return 0;
  }

  // ============================================================
  // 死亡判定
  // ============================================================
  ({bool died, String? cause}) _checkMortality(Character c, int expectedLifespan) {
    // 強制上限
    final hasImmortal = c.giftsUnlocked.contains('不老');
    final hardLimit = hasImmortal ? kMaxAgeWithImmortal : kMaxAgeNormal;
    if (c.age >= hardLimit) {
      return (died: true, cause: '寿命の限界');
    }

    // 健康度0で病死
    if (c.results.health <= 0) {
      return (died: true, cause: '病死');
    }

    // 月次死亡率（年率を月率に換算）
    final ratio = c.age / expectedLifespan;
    double yearMortal = 0.005;
    if (ratio >= 1.3) {
      yearMortal = 0.9;
    } else if (ratio >= 1.2) {
      yearMortal = 0.7;
    } else if (ratio >= 1.1) {
      yearMortal = 0.4;
    } else if (ratio >= 1.0) {
      yearMortal = 0.2;
    } else if (ratio >= 0.8) {
      yearMortal = 0.05;
    } else if (ratio >= 0.6) {
      yearMortal = 0.01;
    }

    final monthMortal = 1 - math.pow(1 - yearMortal, 1 / 12);
    if (_random.nextDouble() < monthMortal) {
      return (died: true, cause: ratio >= 1.0 ? '寿命' : '老衰');
    }
    return (died: false, cause: null);
  }

  // ============================================================
  // ステータス月次変動（GDD §5.4.3 幸福度 / §5.5 加齢減衰）
  // ============================================================
  Character _applyMonthlyStatChanges(Character c, MonthlyBalance balance) {
    var stats = c.stats;
    var results = c.results;

    // 1. 加齢減衰（GDD §5.5.1）
    if (c.age >= 25) {
      // 肉体は25歳から減衰（年-0.5 → 月-0.04 ≒ 0、12ヶ月で-0.5の整数化）
      if ((c.yearIndex % 12) == 0) {
        stats = stats.copyWith(body: math.max(0, stats.body - 1));
      }
    }
    if (c.age >= 45) {
      if ((c.yearIndex % 24) == 0) {
        stats = stats.copyWith(brain: math.max(0, stats.brain - 1));
      }
    }
    if (c.age >= 50) {
      if ((c.yearIndex % 30) == 0) {
        stats = stats.copyWith(sense: math.max(0, stats.sense - 1));
      }
    }

    // 2. 健康度月次減衰（GDD §5.5.2 v1.3 再調整）
    //    sim v3 で完走率91.4%と過剰だったため減衰を強化
    //    v1: 0.02 → v1.2: 0.01 → v1.3: 0.015 (中間)
    //    extraDecayElder: 0.05 → 0.03 → 0.045 (中間)
    final ageDecay = (0.015 * c.age).round();
    final extraDecayElder = c.age >= 55 ? (0.045 * c.age).round() : 0;
    results = results.copyWith(
      health: (results.health - ageDecay - extraDecayElder).clamp(0, 100),
    );

    // 2.5 健康度自然回復（30〜45歳）GDD §5.5.2 v1.3
    //    v1.2 で月+0.5 → v1.3 で 4ヶ月毎+1（月+0.25）に縮小
    //    完走率91% → 目標40%への調整
    if (c.age >= 30 && c.age <= 45) {
      if ((c.yearIndex % 4) == 0) {
        results = results.copyWith(
          health: math.min(100, results.health + 1),
        );
      }
    }

    // 3. 月次ストレス係数（GDD §8.4.4）
    final stress = _computeStress(c, balance);
    final newStress = ((c.stress + stress) ~/ 2).clamp(0, 10); // 平滑化

    // 4. ストレスから健康度の追加減衰
    if (newStress >= 10) {
      results = results.copyWith(health: math.max(0, results.health - 3));
    }

    // 5. 幸福度月次変動（GDD §5.4.3）
    final happinessDelta = _computeHappinessDelta(c, results, newStress);
    results = results.copyWith(
      happiness: (results.happiness + happinessDelta).clamp(0, 100),
    );

    // 6. 人間性 → 運の補正（GDD §5.4.2）
    //    内部処理用のため stats.luck には直接反映せず、必要に応じて _adjustedLuck() を使う
    //    （この実装では luck はベース値のみ保持）

    // 7. 社会的地位の自然変動
    final hasJob = (c.flags['employed'] as bool?) ?? false;
    if ((c.yearIndex % 12) == 0) {
      results = results.copyWith(
        status: (results.status + (hasJob ? 1 : -1)).clamp(0, 100),
      );
    }

    return c.copyWith(stats: stats, results: results, stress: newStress);
  }

  /// 月次ストレス係数（GDD §8.4.4）
  int _computeStress(Character c, MonthlyBalance balance) {
    var stress = 2; // 基礎値

    // 必須固定費が収入の50%超
    final fixedRatio = balance.totalIncome > 0
        ? balance.expenseBreakdown.values
                .fold<int>(0, (s, v) => s + v) /
            balance.totalIncome
        : 1.0;
    if (fixedRatio > 0.5) stress += 3;

    // 月次赤字
    if (balance.netCashflow < 0) stress += 5;

    // 大型支出月（簡易版：支出が収入の2倍超）
    if (balance.totalExpense > balance.totalIncome * 2) stress += 5;

    return stress.clamp(0, 10);
  }

  /// 幸福度月次変動（GDD §5.4.3）
  int _computeHappinessDelta(Character c, Results results, int stress) {
    var delta = 0.0;

    // + 0.05 × (健康度 - 50)
    delta += 0.05 * (results.health - 50);

    // + 0.02 × コミュ力
    delta += 0.02 * c.stats.social;

    // + 0.5 × log10(資産+1)
    if (results.asset > 0) {
      delta += 0.5 * (math.log(results.asset + 1) / math.ln10);
    }

    // + 0.01 × 社会的地位
    delta += 0.01 * results.status;

    // - ストレス係数
    delta -= 0.5 * stress;

    // - 年齢補正（70歳以降）
    if (c.age >= 70) delta -= 0.5;

    return delta.round();
  }

  // ============================================================
  // スキルポイント獲得（GDD §6.4.2）
  // ============================================================
  Character _awardSkillPoints(Character c, Map<String, int>? actionEffects) {
    if (actionEffects == null) return c;

    final newPoints = Map<SkillTree, int>.from(c.skillPoints);
    // 行動アクションに対応する系統に+1pt
    if (actionEffects.containsKey('頭脳')) {
      newPoints[SkillTree.brain] = (newPoints[SkillTree.brain] ?? 0) + 1;
    }
    if (actionEffects.containsKey('肉体')) {
      newPoints[SkillTree.body] = (newPoints[SkillTree.body] ?? 0) + 1;
    }
    if (actionEffects.containsKey('コミュ')) {
      newPoints[SkillTree.social] = (newPoints[SkillTree.social] ?? 0) + 1;
    }
    if (actionEffects.containsKey('センス')) {
      newPoints[SkillTree.sense] = (newPoints[SkillTree.sense] ?? 0) + 1;
    }
    return c.copyWith(skillPoints: newPoints);
  }

  // ============================================================
  // アクション効果の反映
  // ============================================================
  Character _applyActionEffects(Character c, Map<String, int> effects) {
    var stats = c.stats;
    var results = c.results;

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
        case '幸福度':
          results = results.copyWith(
              happiness: (results.happiness + delta).clamp(0, 100));
          break;
        case '健康':
        case '健康度':
          results = results.copyWith(health: (results.health + delta).clamp(0, 100));
          break;
        case '地位':
        case '社会的地位':
          results = results.copyWith(status: (results.status + delta).clamp(0, 100));
          break;
        case '人間性':
          results = results.copyWith(humanity: (results.humanity + delta).clamp(-50, 50));
          break;
      }
    }

    return c.copyWith(stats: stats, results: results);
  }

  // ============================================================
  // ユーティリティ
  // ============================================================

  /// 季節判定（demo.html v2 と整合）
  static String seasonOfAge(int age) {
    return ['春', '夏', '秋', '冬'][age % 4];
  }

  /// 人生フェーズ判定
  static LifePhase phaseOfAge(int age) => LifePhase.forAge(age);

  /// 人間性→運の補正（GDD §5.4.2 v1.3 さらに引き上げ）
  /// sim v3 で運peak max 68（avg 18.5）止まりだったため
  /// 0.33→0.5 (humanity ÷ 2) へ。humanity 50 → +25、天井 75
  /// 内部判定用：表示には使わない
  static int adjustedLuck(Character c) {
    return c.stats.luck + (c.results.humanity ~/ 2);
  }
}
