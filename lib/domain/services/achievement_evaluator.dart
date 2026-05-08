// ============================================================
// AchievementEvaluator / 実績の達成判定エンジン
// GDD §16.2 / §18.3.4 準拠
//
// achievements.json の unlock_condition（自由テキスト）を
// 構造化された Predicate に変換し、ゲーム状態（GameStateSummary）
// に対して評価する。
//
// 設計：
//  - 100件中、約70%は規則的なパターン（数値閾値・イベント発火・年齢）
//  - 残り30%は柔軟な表現で、明示的なIDマッピングで処理
// ============================================================
import '../models/character.dart';
import '../models/achievement_definition.dart';

/// 実績判定時にエンジンへ渡す「現在ゲーム状態の要約」
class GameStateSummary {
  final Character character;
  final Set<String> firedEventIds;
  final Map<String, int> milestoneCounts;
  final Set<String> flags;
  final int generation; // 周回数（1=初代）
  final int? deathAge;  // 死亡している場合の年齢
  final String? deathCause;
  final Map<String, int> incomeStreakYears; // カテゴリ別連続収入年数
  final int unlockedSkillCount;             // 解放スキル数
  final int unlockedExoticCount;            // 異才ノード解放数（家系合算）
  final Set<String> unlockedExoticNames;    // 異才の名前
  final Set<String> achievedEndings;        // 達成済エンディング種別
  final String? lastEndingKind;             // 直近のエンディング種別
  final Map<String, int> monthlyIncomes;    // 副業/家賃/暗号通貨/給与/年金/不労所得
  final int totalPlayMinutes;               // 累計プレイ分
  final int consecutiveLoginDays;           // 連続ログイン日数
  final bool isHiddenEventFired;            // 隠しイベント発火経験
  final Map<String, int> investmentAllocation; // 投資配分（株式等）

  const GameStateSummary({
    required this.character,
    this.firedEventIds = const {},
    this.milestoneCounts = const {},
    this.flags = const {},
    this.generation = 1,
    this.deathAge,
    this.deathCause,
    this.incomeStreakYears = const {},
    this.unlockedSkillCount = 0,
    this.unlockedExoticCount = 0,
    this.unlockedExoticNames = const {},
    this.achievedEndings = const {},
    this.lastEndingKind,
    this.monthlyIncomes = const {},
    this.totalPlayMinutes = 0,
    this.consecutiveLoginDays = 0,
    this.isHiddenEventFired = false,
    this.investmentAllocation = const {},
  });

  bool get isDead => deathAge != null;

  /// 全能力 = 頭脳・肉体・コミュ・センス・運
  List<int> get allAbilities => [
        character.stats.brain,
        character.stats.body,
        character.stats.social,
        character.stats.sense,
        character.stats.luck,
      ];

  int get minAbility => allAbilities.reduce((a, b) => a < b ? a : b);
  int get maxAbility => allAbilities.reduce((a, b) => a > b ? a : b);
}

/// 評価結果
class AchievementCheckResult {
  /// 新たに解放された achievement の id 一覧
  final List<String> newlyUnlocked;
  /// 解析できなかった条件（要手動実装）一覧
  final List<String> unparsedConditions;

  const AchievementCheckResult({
    this.newlyUnlocked = const [],
    this.unparsedConditions = const [],
  });
}

/// メイン評価エンジン
class AchievementEvaluator {
  final List<AchievementDefinition> all;
  AchievementEvaluator(this.all);

  /// 状態と既存解放リストを与え、新たに解放できる id を返す
  AchievementCheckResult evaluate({
    required GameStateSummary state,
    required Set<String> alreadyUnlocked,
  }) {
    final newly = <String>[];
    final unparsed = <String>[];

    for (final a in all) {
      if (alreadyUnlocked.contains(a.id)) continue;
      final pred = _parsePredicate(a);
      if (pred == null) {
        unparsed.add(a.id);
        continue;
      }
      if (pred(state)) {
        newly.add(a.id);
      }
    }

    return AchievementCheckResult(
      newlyUnlocked: newly,
      unparsedConditions: unparsed,
    );
  }

  // ========================================================
  // パーサー本体
  // ========================================================

  /// unlock_condition を真偽判定関数に変換。解析不能なら null。
  bool Function(GameStateSummary)? _parsePredicate(AchievementDefinition def) {
    final cond = def.unlockCondition.trim();

    // 1) ID 別の手動マッピング（複雑な条件用）
    final manual = _manualMapping[def.id];
    if (manual != null) return manual;

    // 0) 「死亡時、X」プレフィックスは最優先で剥がして再帰
    //    （後続パターンが「地位>=80」だけマッチしてしまうのを防ぐ）
    if (cond.startsWith('死亡時')) {
      final sub = cond.replaceFirst(RegExp(r'^死亡時[、,\s]*'), '');
      final inner = _parsePredicateFromText(sub);
      if (inner != null) {
        return (s) => s.isDead && inner(s);
      }
    }

    // 2) 「資産>=Nの単位付き」
    final mAsset = RegExp(r'資産\s*[>＞]=?\s*([\d,]+)\s*([万億])?').firstMatch(cond);
    if (mAsset != null) {
      final n = int.tryParse(mAsset.group(1)!.replaceAll(',', '')) ?? 0;
      final unit = mAsset.group(2);
      final threshold = _yenWithUnit(n, unit);
      return (s) => s.character.results.asset >= threshold;
    }

    // 3) 「社会的地位>=N」「地位>=N」
    final mStatus =
        RegExp(r'(社会的)?地位\s*[>＞]=?\s*(\d+)').firstMatch(cond);
    if (mStatus != null) {
      final n = int.parse(mStatus.group(2)!);
      return (s) => s.character.results.status >= n;
    }

    // 4) 「幸福度>=N」「健康度>=N」
    final mHappy = RegExp(r'幸福度?\s*[>＞]=?\s*(\d+)').firstMatch(cond);
    if (mHappy != null) {
      final n = int.parse(mHappy.group(1)!);
      return (s) => s.character.results.happiness >= n;
    }
    final mHealth = RegExp(r'健康度?\s*[>＞]=?\s*(\d+)').firstMatch(cond);
    if (mHealth != null) {
      final n = int.parse(mHealth.group(1)!);
      return (s) => s.character.results.health >= n;
    }
    final mHumanity = RegExp(r'人間性\s*[>＞]=?\s*(\d+)').firstMatch(cond);
    if (mHumanity != null) {
      final n = int.parse(mHumanity.group(1)!);
      return (s) => s.character.results.humanity >= n;
    }

    // 5) 「N歳到達」
    final mAge = RegExp(r'(\d+)歳到達').firstMatch(cond);
    if (mAge != null) {
      final n = int.parse(mAge.group(1)!);
      return (s) => s.character.age >= n;
    }

    // 6) 「マイルストーン「X」発火」
    final mMile = RegExp(r'マイルストーン「(.+?)」(?:発火|完了)?').firstMatch(cond);
    if (mMile != null) {
      final name = mMile.group(1)!;
      return (s) => (s.milestoneCounts[name] ?? 0) >= 1;
    }

    // 7) 「マイルストーンN回（以上）」付随パターン
    final mMileN =
        RegExp(r'(\S+?)マイルストーン(\d+)回(?:以上)?').firstMatch(cond);
    if (mMileN != null) {
      final name = mMileN.group(1)!;
      final n = int.parse(mMileN.group(2)!);
      return (s) => (s.milestoneCounts[name] ?? 0) >= n;
    }

    // 8) 「L-XXX」「S-XXX」「T-XXX」「M-XXX」イベント発火
    final mEvent =
        RegExp(r'((?:L|S|T|M|G|R|EX)-\d{3})\b').firstMatch(cond);
    if (mEvent != null) {
      final id = mEvent.group(1)!;
      return (s) => s.firedEventIds.contains(id);
    }

    // 9) 「フラグ X 発生」「X フラグ」
    final mFlag = RegExp(r'(\S+)フラグ(?:発生|ON|有り|あり)?').firstMatch(cond);
    if (mFlag != null) {
      final name = mFlag.group(1)!;
      return (s) => s.flags.contains(name);
    }

    // 10) 「周回N代達成」「N周目」「N代継承」
    final mGen = RegExp(r'周回\s*(\d+)代|(\d+)周目|(\d+)代継承').firstMatch(cond);
    if (mGen != null) {
      final n = int.parse(
          mGen.group(1) ?? mGen.group(2) ?? mGen.group(3) ?? '1');
      return (s) => s.generation >= n;
    }

    // 12) 「全能力>=N」「全能力==N」
    final mAllAbil =
        RegExp(r'全能力\s*([>＞=]+|==)\s*(\d+)').firstMatch(cond);
    if (mAllAbil != null) {
      final op = mAllAbil.group(1)!;
      final n = int.parse(mAllAbil.group(2)!);
      if (op == '==') return (s) => s.allAbilities.every((a) => a == n);
      return (s) => s.allAbilities.every((a) => a >= n);
    }

    // 13) 「能力（任意）>=N」 — 最低1つの能力が N 以上
    final mAnyAbil =
        RegExp(r'能力（任意）\s*[>＞]=?\s*(\d+)').firstMatch(cond);
    if (mAnyAbil != null) {
      final n = int.parse(mAnyAbil.group(1)!);
      return (s) => s.maxAbility >= n;
    }

    // 14) 「解放スキル数>=N」
    final mSkill = RegExp(r'解放スキル数\s*[>＞]=?\s*(\d+)').firstMatch(cond);
    if (mSkill != null) {
      final n = int.parse(mSkill.group(1)!);
      return (s) => s.unlockedSkillCount >= n;
    }

    // 15) 「異才ノード解放数>=N」「異才ノード解放数==N」
    final mExo = RegExp(r'異才ノード解放数\s*([>＞=]+|==)\s*(\d+)').firstMatch(cond);
    if (mExo != null) {
      final op = mExo.group(1)!;
      final n = int.parse(mExo.group(2)!);
      if (op == '==') return (s) => s.unlockedExoticCount == n;
      return (s) => s.unlockedExoticCount >= n;
    }

    // 16) 「異才「X」ノード解放」
    final mExoNamed = RegExp(r'異才「(.+?)」ノード解放').firstMatch(cond);
    if (mExoNamed != null) {
      final name = mExoNamed.group(1)!;
      return (s) => s.unlockedExoticNames.contains(name);
    }

    // 17) 「エンディング種別=X」
    final mEndKind = RegExp(r'エンディング種別\s*=\s*(.+?)(?:[（(]|$)').firstMatch(cond);
    if (mEndKind != null) {
      final kind = mEndKind.group(1)!.trim();
      return (s) => s.lastEndingKind == kind;
    }

    // 18) 「達成エンディング種別>=N」「==N」
    final mEndCount =
        RegExp(r'達成エンディング種別\s*([>＞=]+|==)\s*(\d+)').firstMatch(cond);
    if (mEndCount != null) {
      final op = mEndCount.group(1)!;
      final n = int.parse(mEndCount.group(2)!);
      if (op == '==') return (s) => s.achievedEndings.length == n;
      return (s) => s.achievedEndings.length >= n;
    }

    // 19) 「エンディングN回到達」
    final mEndN = RegExp(r'エンディング(\d+)回到達').firstMatch(cond);
    if (mEndN != null) {
      final n = int.parse(mEndN.group(1)!);
      return (s) => s.achievedEndings.length >= n;
    }

    // 20) 「月次総収入>N万円相当」「月の副業収入>給与」
    final mIncomeTotal =
        RegExp(r'月次総収入\s*[>＞]=?\s*([\d,]+)\s*([万億])?').firstMatch(cond);
    if (mIncomeTotal != null) {
      final n = int.parse(mIncomeTotal.group(1)!.replaceAll(',', ''));
      final unit = mIncomeTotal.group(2);
      final threshold = _yenWithUnit(n, unit);
      return (s) {
        final total = s.monthlyIncomes.values.fold<int>(0, (a, b) => a + b);
        return total >= threshold;
      };
    }

    // 21) 「副業収入>0」「家賃収入>0」「年金収入>0」
    final mIncomeKind = RegExp(r'(\S+?)収入\s*[>＞]\s*0').firstMatch(cond);
    if (mIncomeKind != null) {
      final kind = mIncomeKind.group(1)!;
      return (s) => (s.monthlyIncomes[kind] ?? 0) > 0;
    }

    // 22) 「累計プレイ時間>=N時間」
    final mPlay = RegExp(r'累計プレイ時間\s*[>＞]=?\s*(\d+)時間').firstMatch(cond);
    if (mPlay != null) {
      final hours = int.parse(mPlay.group(1)!);
      return (s) => s.totalPlayMinutes >= hours * 60;
    }

    // 23) 「連続ログインN日」
    final mLogin = RegExp(r'連続ログイン(\d+)日').firstMatch(cond);
    if (mLogin != null) {
      final n = int.parse(mLogin.group(1)!);
      return (s) => s.consecutiveLoginDays >= n;
    }

    // 24) 「is_hidden=TRUE のイベント1件以上発火」
    if (cond.contains('is_hidden=TRUE') && cond.contains('発火')) {
      return (s) => s.isHiddenEventFired;
    }

    // 25) 「投資配分で株式が0以上になる」
    final mInvest =
        RegExp(r'投資配分で(\S+?)が(\d+)以上').firstMatch(cond);
    if (mInvest != null) {
      final kind = mInvest.group(1)!;
      final n = int.parse(mInvest.group(2)!);
      return (s) => (s.investmentAllocation[kind] ?? 0) >= n;
    }

    // 26) 「1キャラ完走」
    if (cond.contains('1キャラ完走')) {
      return (s) => s.isDead;
    }

    // 27) 「暗号通貨保有額が一時N倍化」 → フラグ系
    final mCryptoX = RegExp(r'暗号通貨保有額が一時(\d+)倍化').firstMatch(cond);
    if (mCryptoX != null) {
      final n = int.parse(mCryptoX.group(1)!);
      return (s) => s.flags.contains('crypto_${n}x');
    }

    // 28) 「複合条件 + 区切り」 — 起業ルート＋資産1億 等
    if (cond.contains('＋') || cond.contains('+')) {
      final parts = cond.split(RegExp(r'[＋+]'));
      final preds = <bool Function(GameStateSummary)>[];
      for (final p in parts) {
        final inner = _parsePredicateFromText(p.trim());
        if (inner != null) preds.add(inner);
      }
      if (preds.isNotEmpty && preds.length == parts.length) {
        return (s) => preds.every((p) => p(s));
      }
    }

    // パターン未マッチ
    return null;
  }

  /// テキストから直接 Predicate を作る（11の死亡時付きから再帰呼出）
  bool Function(GameStateSummary)? _parsePredicateFromText(String text) {
    final pseudoDef = AchievementDefinition(
      id: '__inline__',
      category: '',
      grade: AchievementGrade.bronze,
      title: '',
      description: '',
      unlockCondition: text,
      applicableEras: const [],
      reward: '',
    );
    return _parsePredicate(pseudoDef);
  }

  /// 資産単位を円換算
  int _yenWithUnit(int n, String? unit) {
    switch (unit) {
      case '億':
        return n * 100000000;
      case '万':
        return n * 10000;
      default:
        return n;
    }
  }

  // ========================================================
  // 手動マッピング — 条件が自由文で複雑なものを ID 単位で実装
  // ========================================================
  static final Map<String, bool Function(GameStateSummary)> _manualMapping = {
    // ----- キャリア・複合 -----
    'A-004': (s) =>
        s.flags.contains('side_job_done') ||
        s.firedEventIds.any((id) => id.startsWith('L-')),
    'A-008': (s) {
      final side = s.monthlyIncomes['副業'] ?? 0;
      final salary = s.monthlyIncomes['給与'] ?? 0;
      return side > salary && salary > 0;
    },
    // A-013：8職業すべて経験
    'A-013': (s) {
      const required = [
        '公務員', '会社員', '専門職', '自営業',
        'フリーター', '起業家', '不労所得', '退職',
      ];
      return required.every((j) => s.flags.contains('job_$j'));
    },
    // A-019：結婚から60年＋離婚なし
    'A-019': (s) => s.flags.contains('married_60y_kept'),
    'A-020': (s) => s.flags.contains('three_generations'),
    'A-022': (s) => s.flags.contains('all_children_graduated'),
    'A-023': (s) => s.generation >= 5,
    // ----- 5年連続系 -----
    'A-012': (s) => s.flags.contains('multi_income_5y'),
    // ----- 全種類利確 -----
    'A-035': (s) {
      const types = ['預金', '定期', '株式', '個別', 'リスク', '不動産', '暗号通貨'];
      return types.every((t) => s.flags.contains('profit_$t'));
    },
    // ----- プレイ系（周回数 / 共有数） -----
    'A-070': (s) => s.flags.contains('tomb_shared_1'),
    'A-071': (s) => s.generation >= 1,
    'A-072': (s) => s.generation >= 5,
    'A-075': (s) => s.generation >= 20,
    'A-077': (s) => s.generation >= 100,
    // ----- 時代別エンディング -----
    'A-078': (s) => s.flags.contains('ending_in_昭和'),
    'A-079': (s) => s.flags.contains('ending_in_平成'),
    'A-080': (s) => s.flags.contains('ending_in_令和'),
    'A-081': (s) => s.flags.contains('ending_in_近未来'),
    'A-082': (s) => ['昭和', '平成', '令和', '近未来']
        .every((era) => s.flags.contains('ending_in_$era')),
    // 全T-イベント
    'A-085': (s) {
      final tEvents = s.firedEventIds.where((id) => id.startsWith('T-')).toSet();
      return tEvents.length >= 39; // GDD §10 の T-イベント総数
    },
    // 20通り組合せ
    'A-087': (s) => s.flags.contains('20_combinations_completed'),
    // ----- 隠しカテゴリ -----
    'A-092': (s) => s.flags.contains('rest_12_consecutive'),
    'A-093': (s) => s.flags.contains('chain_10_in_one_turn'),
    'A-094': (s) {
      // 全5アクション系統 >= 10pt（カテゴリ別pt はゲーム状態側で集計）
      return s.flags.contains('all_actions_10pt');
    },
    // 周回継続系の隠しエンディング
    'A-095': (s) => s.flags.contains('all_endings_seen_15plus'),
    'A-096': (s) => s.generation >= 10,
    'A-097': (s) => s.flags.contains('no_auto_progress_960'),
    'A-098': (s) => s.unlockedExoticCount == 10,
    // 隠しカテゴリ全達成
    'A-099': (s) {
      const hiddenIds = [
        'A-088', 'A-089', 'A-090', 'A-091', 'A-092', 'A-093',
        'A-094', 'A-095', 'A-096', 'A-097', 'A-098',
      ];
      // この判定は呼出側（Game側）で過去解放実績と突き合わせて事前計算する
      return s.flags.contains('all_hidden_unlocked');
    },
    // 全達成
    'A-100': (s) => s.flags.contains('all_99_unlocked'),
  };
}
