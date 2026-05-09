// ============================================================
// AI Playtest: Random Bot（Phase C v0.1）
//
// 既存 lib/dev/sim_runner.dart の API パターンに合わせて、
// 1セッション単位の詳細ログを JSON で出力する。
//
// sim_runner.dart は1000体のCSV集計に特化、こちらは数百体規模で
// セッション毎のターン別軌跡を JSON で残し、後段の Claude API 分析に渡す。
//
// 実行方法：
//   dart run tools/ai_playtest/random_bot.dart
//   dart run tools/ai_playtest/random_bot.dart --sessions=100 --max-turns=960 --seed=42
//
// 出力：
//   tools/ai_playtest/logs/{YYYY-MM-DD}/session_{seed}_{i}.json
//   tools/ai_playtest/logs/{YYYY-MM-DD}/_summary.json
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/engines/economy_engine.dart';
import 'package:capitalism_game/domain/engines/event_resolver.dart';
import 'package:capitalism_game/domain/engines/game_engine.dart';
import 'package:capitalism_game/domain/models/character.dart';
import 'package:capitalism_game/domain/models/event_definition.dart';
import 'package:capitalism_game/domain/services/character_factory.dart';

/// 引数パーサ（依存なし、最小限）
class _Args {
  int sessions = 10;
  int maxTurns = 960; // 80年 × 12月
  int? seed;
  String outputDir = 'tools/ai_playtest/logs';
  bool verbose = false;
  int snapshotEvery = 12; // 何ターン毎にスナップショットを取るか（default: 1年）

  _Args.parse(List<String> argv) {
    for (final a in argv) {
      if (a.startsWith('--sessions=')) {
        sessions = int.parse(a.substring('--sessions='.length));
      } else if (a.startsWith('--max-turns=')) {
        maxTurns = int.parse(a.substring('--max-turns='.length));
      } else if (a.startsWith('--seed=')) {
        seed = int.parse(a.substring('--seed='.length));
      } else if (a.startsWith('--output=')) {
        outputDir = a.substring('--output='.length);
      } else if (a.startsWith('--snapshot-every=')) {
        snapshotEvery = int.parse(a.substring('--snapshot-every='.length));
      } else if (a == '--verbose' || a == '-v') {
        verbose = true;
      } else if (a == '--help' || a == '-h') {
        _printUsage();
        exit(0);
      }
    }
  }

  static void _printUsage() {
    stderr.writeln('Usage: dart run tools/ai_playtest/random_bot.dart [options]');
    stderr.writeln('  --sessions=N         プレイ数（default: 10）');
    stderr.writeln('  --max-turns=N        最大ターン数（default: 960 = 80年×12月）');
    stderr.writeln('  --seed=N             乱数シード（default: 時刻ベース）');
    stderr.writeln('  --output=PATH        出力ディレクトリ（default: tools/ai_playtest/logs）');
    stderr.writeln('  --snapshot-every=N   N ターンごとにスナップショット記録（default: 12）');
    stderr.writeln('  --verbose, -v        詳細出力');
  }
}

/// セッション1回分のログ
class SessionLog {
  final String sessionId;
  final int seed;
  final List<Map<String, dynamic>> snapshots = [];
  Map<String, dynamic>? result;
  late final DateTime startedAt;
  DateTime? finishedAt;
  String? errorMessage;

  SessionLog({required this.sessionId, required this.seed}) {
    startedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'seed': seed,
        'snapshot_count': snapshots.length,
        'snapshots': snapshots,
        'result': result,
        'error': errorMessage,
        'started_at': startedAt.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
        'duration_ms': finishedAt == null
            ? null
            : finishedAt!.difference(startedAt).inMilliseconds,
      };
}

Map<String, dynamic> _snapshotOf(Character c, int turn) => {
      'turn': turn,
      'age': c.age,
      'year_index': c.yearIndex,
      'asset': c.results.asset,
      'status': c.results.status,
      'health': c.results.health,
      'happiness': c.results.happiness,
      'humanity': c.results.humanity,
      'stress': c.stress,
      'brain': c.stats.brain,
      'body': c.stats.body,
      'social': c.stats.social,
      'sense': c.stats.sense,
      'luck': c.stats.luck,
    };

/// 1セッション実行（sim_runner.dart の _runOne パターンに準拠）
SessionLog runSession({
  required String sessionId,
  required int seed,
  required int maxTurns,
  required int snapshotEvery,
  required List<EventDefinition> events,
  bool verbose = false,
}) {
  final log = SessionLog(sessionId: sessionId, seed: seed);
  final rng = math.Random(seed);

  try {
    // ランダムにバリエーション選択
    final era = Era.values[rng.nextInt(Era.values.length)];
    final strength = AbilityKind.values[rng.nextInt(AbilityKind.values.length)];
    final gender = [Gender.male, Gender.female][rng.nextInt(2)];

    var c = CharacterFactory.createFromDraft(
      gender: gender,
      strength: strength,
      avatarId: 0,
      era: era,
      name: sessionId,
    );
    c = c.copyWith(
      results: c.results.copyWith(asset: 50000),
      flags: {...c.flags, 'employed': false},
    );

    final engine = GameEngine(
      eventResolver: EventResolver(events: events),
      economy: EconomyEngine(seed: rng.nextInt(0x7fffffff)),
      seed: rng.nextInt(0x7fffffff),
    );

    int turn = 0;
    String? deathCause;
    bool died = false;
    int eventsFired = 0;

    // 初期スナップショット
    log.snapshots.add(_snapshotOf(c, turn));

    while (!died && turn < maxTurns) {
      final result = engine.advanceTurn(c);
      c = result.character;
      if (result.firedEvent != null) eventsFired++;

      if (result.died) {
        died = true;
        deathCause = result.deathCause;
      }

      turn++;
      if (turn % snapshotEvery == 0 || verbose || died) {
        log.snapshots.add(_snapshotOf(c, turn));
      }
    }

    log.result = {
      'final_turn': turn,
      'final_age': c.age,
      'final_asset': c.results.asset,
      'final_status': c.results.status,
      'final_health': c.results.health,
      'final_happiness': c.results.happiness,
      'final_humanity': c.results.humanity,
      'final_stress': c.stress,
      'died': died,
      'death_cause': deathCause,
      'reached_age_80': c.age >= 80,
      'bankrupt': c.flags.containsKey('bankruptcy'),
      'events_fired': eventsFired,
      'reached_max_turn': turn >= maxTurns,
      'era': era.label,
      'strength': strength.label,
      'gender': gender.label,
    };
  } catch (e, st) {
    log.errorMessage = '$e\n$st';
    if (verbose) stderr.writeln('[session $sessionId] error: $e');
  }

  log.finishedAt = DateTime.now();
  return log;
}

Future<void> main(List<String> argv) async {
  final args = _Args.parse(argv);
  final baseSeed = args.seed ?? DateTime.now().millisecondsSinceEpoch;
  final today = DateTime.now().toIso8601String().substring(0, 10);

  final outDir = Directory('${args.outputDir}/$today');
  outDir.createSync(recursive: true);

  stdout.writeln(
      '[ai_playtest] sessions=${args.sessions} maxTurns=${args.maxTurns} '
      'seed=$baseSeed snapshotEvery=${args.snapshotEvery}');
  stdout.writeln('[ai_playtest] output: ${outDir.path}');

  // v0.1 ではイベント定義を空で開始（GDD §10 で本実装ロード予定）
  // 既存の events_database.xlsx 連動は Phase C v0.2 で。
  final List<EventDefinition> events = const [];

  final summary = <Map<String, dynamic>>[];
  int okCount = 0;
  int errCount = 0;
  int reachedAge80Count = 0;
  int bankruptCount = 0;
  final overallStart = DateTime.now();

  for (var i = 0; i < args.sessions; i++) {
    final sid = 'session_${baseSeed}_$i';
    final log = runSession(
      sessionId: sid,
      seed: baseSeed + i,
      maxTurns: args.maxTurns,
      snapshotEvery: args.snapshotEvery,
      events: events,
      verbose: args.verbose,
    );

    final f = File('${outDir.path}/$sid.json');
    f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(log.toJson()));

    final ok = log.errorMessage == null;
    if (ok) {
      okCount++;
    } else {
      errCount++;
    }

    final r = log.result;
    if (r != null) {
      if (r['reached_age_80'] == true) reachedAge80Count++;
      if (r['bankrupt'] == true) bankruptCount++;
    }

    summary.add({
      'session_id': sid,
      'ok': ok,
      'error': log.errorMessage?.split('\n').first,
      'final_turn': r?['final_turn'],
      'final_age': r?['final_age'],
      'reached_age_80': r?['reached_age_80'],
      'bankrupt': r?['bankrupt'],
      'duration_ms': log.toJson()['duration_ms'],
    });

    if (args.verbose || (i + 1) % 10 == 0 || i == args.sessions - 1) {
      stdout.writeln(
          '  [${i + 1}/${args.sessions}] $sid: ${ok ? "OK" : "ERR"} '
          'age=${r?['final_age']} ${r?['bankrupt'] == true ? "bankrupt" : ""}');
    }
  }

  final duration = DateTime.now().difference(overallStart);

  // サマリJSON
  final summaryFile = File('${outDir.path}/_summary.json');
  summaryFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'generated_at': DateTime.now().toIso8601String(),
    'total_sessions': args.sessions,
    'ok': okCount,
    'errors': errCount,
    'reached_age_80': reachedAge80Count,
    'bankrupt': bankruptCount,
    'reached_age_80_rate': args.sessions == 0
        ? 0.0
        : reachedAge80Count / args.sessions,
    'bankrupt_rate':
        args.sessions == 0 ? 0.0 : bankruptCount / args.sessions,
    'total_duration_ms': duration.inMilliseconds,
    'avg_duration_ms':
        args.sessions == 0 ? 0 : duration.inMilliseconds ~/ args.sessions,
    'sessions': summary,
  }));

  stdout.writeln('\n[ai_playtest] done: ok=$okCount err=$errCount '
      'aged80=$reachedAge80Count bankrupt=$bankruptCount '
      'duration=${duration.inMilliseconds}ms');
  stdout.writeln('[ai_playtest] summary: ${summaryFile.path}');

  // CI 連携：エラー率 > 50% なら exit 1
  if (errCount > okCount && args.sessions >= 4) {
    stderr.writeln(
        '[ai_playtest] FAIL: error rate too high ($errCount/${args.sessions})');
    exit(1);
  }
}
