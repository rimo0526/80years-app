// ============================================================
// AIシミュレーション基盤 / GDD §20.2.2
//
// 1000キャラ（または任意数）を自動プレイし、結果をCSV出力。
//   - 完走率（80年到達率）
//   - エンディング分布
//   - 能力到達率
//   - 平均寿命
//   - 破産発生率
//
// 実行方法：
//   dart run lib/dev/sim_runner.dart
//   dart run lib/dev/sim_runner.dart 5000   # 5000キャラ
//
// 注：Flutter UIには依存しない純粋ロジック層のテスト。
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../core/constants/enums.dart';
import '../domain/engines/economy_engine.dart';
import '../domain/engines/event_resolver.dart';
import '../domain/engines/game_engine.dart';
import '../domain/models/character.dart';
import '../domain/models/event_definition.dart';
import '../domain/services/character_factory.dart';

class SimResult {
  final String charId;
  final Era era;
  final AbilityKind strength;
  final Gender gender;
  final int finalAge;
  final int finalAsset;
  final int finalHealth;
  final int finalHappiness;
  final int finalStatus;
  final int finalHumanity;
  final int peakBrain;
  final int peakBody;
  final int peakSocial;
  final int peakSense;
  final int peakLuck;
  final String deathCause;
  final bool reachedAge80;
  final bool bankrupt;
  final int eventsFired;

  const SimResult({
    required this.charId,
    required this.era,
    required this.strength,
    required this.gender,
    required this.finalAge,
    required this.finalAsset,
    required this.finalHealth,
    required this.finalHappiness,
    required this.finalStatus,
    required this.finalHumanity,
    required this.peakBrain,
    required this.peakBody,
    required this.peakSocial,
    required this.peakSense,
    required this.peakLuck,
    required this.deathCause,
    required this.reachedAge80,
    required this.bankrupt,
    required this.eventsFired,
  });

  String toCsvRow() {
    return [
      charId,
      era.label,
      strength.label,
      gender.label,
      finalAge,
      finalAsset,
      finalHealth,
      finalHappiness,
      finalStatus,
      finalHumanity,
      peakBrain,
      peakBody,
      peakSocial,
      peakSense,
      peakLuck,
      deathCause,
      reachedAge80 ? 1 : 0,
      bankrupt ? 1 : 0,
      eventsFired,
    ].join(',');
  }

  static String csvHeader() {
    return [
      'char_id',
      'era',
      'strength',
      'gender',
      'final_age',
      'final_asset',
      'final_health',
      'final_happiness',
      'final_status',
      'final_humanity',
      'peak_brain',
      'peak_body',
      'peak_social',
      'peak_sense',
      'peak_luck',
      'death_cause',
      'reached_age_80',
      'bankrupt',
      'events_fired',
    ].join(',');
  }
}

class SimRunner {
  final List<EventDefinition> events;
  final math.Random random;

  SimRunner({this.events = const [], int? seed})
      : random = math.Random(seed);

  /// N キャラ自動プレイ → 結果リスト
  List<SimResult> runMany(int count) {
    final results = <SimResult>[];
    final eras = Era.values;
    final strengths = AbilityKind.values;
    final genders = [Gender.male, Gender.female];

    for (var i = 0; i < count; i++) {
      // バリエーション付きランダム選択
      final era = eras[random.nextInt(eras.length)];
      final strength = strengths[random.nextInt(strengths.length)];
      final gender = genders[random.nextInt(genders.length)];
      results.add(_runOne(i, era, strength, gender));
    }
    return results;
  }

  SimResult _runOne(int index, Era era, AbilityKind strength, Gender gender) {
    // ファクトリでキャラ生成
    var c = CharacterFactory.createFromDraft(
      gender: gender,
      strength: strength,
      avatarId: 0,
      era: era,
      name: 'sim_$index',
    );
    c = c.copyWith(
      results: c.results.copyWith(asset: 50000),
      flags: {...c.flags, 'employed': false},
    );

    // ピーク能力追跡
    var peakBrain = c.stats.brain;
    var peakBody = c.stats.body;
    var peakSocial = c.stats.social;
    var peakSense = c.stats.sense;
    var peakLuck = c.stats.luck;

    final engine = GameEngine(
      eventResolver: EventResolver(events: events),
      economy: EconomyEngine(seed: random.nextInt(0x7fffffff)),
      seed: random.nextInt(0x7fffffff),
    );

    var died = false;
    var deathCause = '不明';
    var eventCount = 0;

    // 月次ループ
    for (var month = 0; month < 80 * 12; month++) {
      // 大学生以降は employed ON にする簡易AI
      final newFlags = Map<String, dynamic>.from(c.flags);
      if (c.age >= 22 && !(newFlags['employed'] as bool? ?? false)) {
        newFlags['employed'] = true;
        c = c.copyWith(
          flags: newFlags,
          household: c.household,
        );
      }

      // ランダムにアクション選択（ライフフェーズ別簡易AI）
      final action = _aiSelectAction(c, strength);

      final result = engine.advanceTurn(c, actionEffects: action);
      c = result.character;

      // ピーク能力更新
      peakBrain = math.max(peakBrain, c.stats.brain);
      peakBody = math.max(peakBody, c.stats.body);
      peakSocial = math.max(peakSocial, c.stats.social);
      peakSense = math.max(peakSense, c.stats.sense);
      peakLuck = math.max(peakLuck, c.stats.luck);

      if (result.firedEvent != null) eventCount++;

      if (result.died) {
        died = true;
        deathCause = result.deathCause ?? '老衰';
        break;
      }
    }

    return SimResult(
      charId: 'sim_$index',
      era: era,
      strength: strength,
      gender: gender,
      finalAge: c.age,
      finalAsset: c.results.asset,
      finalHealth: c.results.health,
      finalHappiness: c.results.happiness,
      finalStatus: c.results.status,
      finalHumanity: c.results.humanity,
      peakBrain: peakBrain,
      peakBody: peakBody,
      peakSocial: peakSocial,
      peakSense: peakSense,
      peakLuck: peakLuck,
      deathCause: died ? deathCause : '生存（80歳完走）',
      reachedAge80: c.age >= 80,
      bankrupt: c.flags['bankruptcy'] == true,
      eventsFired: eventCount,
    );
  }

  /// 強み一致系のアクションを優先するシンプルAI
  Map<String, int> _aiSelectAction(Character c, AbilityKind preferred) {
    if (c.age < 6) return {};
    if (random.nextDouble() < 0.2) {
      return {'健康': 3, '幸福': 2}; // ゆっくり休む
    }
    switch (preferred) {
      case AbilityKind.brain:
        return {'頭脳': 1};
      case AbilityKind.body:
        return {'肉体': 1, '健康': 1};
      case AbilityKind.social:
        return {'コミュ': 1, '幸福': 1};
      case AbilityKind.sense:
        return {'センス': 1, '幸福': 2};
      case AbilityKind.luck:
        // v1.2: 運は直接育てられるアクション（祈祷／占い）を擬似的に表現
        // 月+0.5 ≒ 2ヶ月に1
        if (c.yearIndex % 2 == 0) {
          return {'運': 1, '人間性': 1};
        }
        return {'人間性': 1};
    }
  }
}

/// 集計結果
class SimSummary {
  final int totalChars;
  final int reachedAge80Count;
  final double reachedAge80Rate;
  final double avgLifespan;
  final double bankruptcyRate;
  final Map<String, int> deathCauseDist;
  final Map<Era, double> avgLifespanByEra;
  final Map<AbilityKind, double> avgLifespanByStrength;
  final double avgEventsFired;

  SimSummary._({
    required this.totalChars,
    required this.reachedAge80Count,
    required this.reachedAge80Rate,
    required this.avgLifespan,
    required this.bankruptcyRate,
    required this.deathCauseDist,
    required this.avgLifespanByEra,
    required this.avgLifespanByStrength,
    required this.avgEventsFired,
  });

  factory SimSummary.from(List<SimResult> results) {
    if (results.isEmpty) {
      return SimSummary._(
        totalChars: 0,
        reachedAge80Count: 0,
        reachedAge80Rate: 0,
        avgLifespan: 0,
        bankruptcyRate: 0,
        deathCauseDist: const {},
        avgLifespanByEra: const {},
        avgLifespanByStrength: const {},
        avgEventsFired: 0,
      );
    }

    final n = results.length;
    final reached = results.where((r) => r.reachedAge80).length;
    final avgAge = results.map((r) => r.finalAge).reduce((a, b) => a + b) / n;
    final bankrupt = results.where((r) => r.bankrupt).length;
    final avgEvents =
        results.map((r) => r.eventsFired).reduce((a, b) => a + b) / n;

    final causes = <String, int>{};
    for (final r in results) {
      causes[r.deathCause] = (causes[r.deathCause] ?? 0) + 1;
    }

    final byEra = <Era, double>{};
    for (final era in Era.values) {
      final list = results.where((r) => r.era == era).toList();
      if (list.isEmpty) continue;
      byEra[era] =
          list.map((r) => r.finalAge).reduce((a, b) => a + b) / list.length;
    }

    final byStrength = <AbilityKind, double>{};
    for (final s in AbilityKind.values) {
      final list = results.where((r) => r.strength == s).toList();
      if (list.isEmpty) continue;
      byStrength[s] =
          list.map((r) => r.finalAge).reduce((a, b) => a + b) / list.length;
    }

    return SimSummary._(
      totalChars: n,
      reachedAge80Count: reached,
      reachedAge80Rate: reached / n,
      avgLifespan: avgAge,
      bankruptcyRate: bankrupt / n,
      deathCauseDist: causes,
      avgLifespanByEra: byEra,
      avgLifespanByStrength: byStrength,
      avgEventsFired: avgEvents,
    );
  }

  String toReport() {
    final sb = StringBuffer();
    sb.writeln('=== AI Simulation Summary ===');
    sb.writeln('Total chars       : $totalChars');
    sb.writeln('Reached age 80    : $reachedAge80Count (${(reachedAge80Rate * 100).toStringAsFixed(1)}%)');
    sb.writeln('Avg lifespan      : ${avgLifespan.toStringAsFixed(1)}');
    sb.writeln('Bankruptcy rate   : ${(bankruptcyRate * 100).toStringAsFixed(1)}%');
    sb.writeln('Avg events fired  : ${avgEventsFired.toStringAsFixed(1)}');
    sb.writeln();
    sb.writeln('Avg lifespan by era:');
    for (final entry in avgLifespanByEra.entries) {
      sb.writeln('  ${entry.key.label}: ${entry.value.toStringAsFixed(1)}');
    }
    sb.writeln();
    sb.writeln('Avg lifespan by strength:');
    for (final entry in avgLifespanByStrength.entries) {
      sb.writeln('  ${entry.key.label}: ${entry.value.toStringAsFixed(1)}');
    }
    sb.writeln();
    sb.writeln('Death cause distribution:');
    final causes = deathCauseDist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in causes) {
      final pct = (entry.value / totalChars * 100).toStringAsFixed(1);
      sb.writeln('  ${entry.key}: ${entry.value} ($pct%)');
    }
    return sb.toString();
  }
}

/// events.json をディスクから読み込んで EventDefinition のリストを返す
List<EventDefinition> _loadEvents() {
  // 実行ディレクトリ（app_flutter/）の assets/data/events.json を読む
  final candidates = [
    'assets/data/events.json',
    '../assets/data/events.json',
    'app_flutter/assets/data/events.json',
  ];
  String? jsonStr;
  String? loadedFrom;
  for (final p in candidates) {
    final f = File(p);
    if (f.existsSync()) {
      jsonStr = f.readAsStringSync();
      loadedFrom = p;
      break;
    }
  }
  if (jsonStr == null) {
    print('WARNING: events.json が見つかりません（イベント発火なしで実行）');
    return const [];
  }

  final root = json.decode(jsonStr) as Map<String, dynamic>;
  final list = root['events'] as List?;
  if (list == null) return const [];
  final events = list
      .map((e) => EventDefinition.fromJson(e as Map<String, dynamic>))
      .toList();
  print('Loaded ${events.length} events from $loadedFrom');
  return events;
}

/// エントリポイント：dart run で起動
void main(List<String> args) {
  final count = args.isNotEmpty ? int.tryParse(args[0]) ?? 1000 : 1000;
  final outputCsv = args.length >= 2 ? args[1] : 'sim_results.csv';

  print('Starting simulation: $count chars');
  final events = _loadEvents();
  final runner = SimRunner(seed: 42, events: events);
  final stopwatch = Stopwatch()..start();
  final results = runner.runMany(count);
  stopwatch.stop();

  print('Done in ${stopwatch.elapsed.inSeconds}s');

  // CSV 出力
  final csv = StringBuffer();
  csv.writeln(SimResult.csvHeader());
  for (final r in results) {
    csv.writeln(r.toCsvRow());
  }
  File(outputCsv).writeAsStringSync(csv.toString());
  print('CSV written: $outputCsv');

  // サマリー
  final summary = SimSummary.from(results);
  print(summary.toReport());

  // サマリーもファイルに
  File('${outputCsv}.summary.txt').writeAsStringSync(summary.toReport());
}
