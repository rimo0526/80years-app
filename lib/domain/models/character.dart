// ============================================================
// Character モデル / GDD §18.3.2 character ブロック準拠
// ============================================================
import '../../core/constants/enums.dart';

/// 9ステータス通称（実は 5+5=10 項目、GDD §1.2.1）
class Stats {
  final int brain;
  final int body;
  final int social;
  final int sense;
  final int luck;

  const Stats({
    this.brain = 10,
    this.body = 10,
    this.social = 10,
    this.sense = 10,
    this.luck = 10,
  });

  Stats copyWith({int? brain, int? body, int? social, int? sense, int? luck}) {
    return Stats(
      brain: brain ?? this.brain,
      body: body ?? this.body,
      social: social ?? this.social,
      sense: sense ?? this.sense,
      luck: luck ?? this.luck,
    );
  }

  Map<String, dynamic> toJson() => {
        '頭脳': brain,
        '肉体': body,
        'コミュ': social,
        'センス': sense,
        '運': luck,
      };

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        brain: (j['頭脳'] ?? 10) as int,
        body: (j['肉体'] ?? 10) as int,
        social: (j['コミュ'] ?? 10) as int,
        sense: (j['センス'] ?? 10) as int,
        luck: (j['運'] ?? 10) as int,
      );
}

/// 結果系ステータス（GDD §5.1.3）
class Results {
  final int asset;     // 資産（円相当、負許容）
  final int status;    // 社会的地位（0-100）
  final int happiness; // 幸福度（0-100）
  final int health;    // 健康度（0-100）
  final int humanity;  // 人間性（-50〜+50）

  const Results({
    this.asset = 0,
    this.status = 30,
    this.happiness = 50,
    this.health = 100,
    this.humanity = 0,
  });

  Results copyWith({int? asset, int? status, int? happiness, int? health, int? humanity}) {
    return Results(
      asset: asset ?? this.asset,
      status: status ?? this.status,
      happiness: happiness ?? this.happiness,
      health: health ?? this.health,
      humanity: humanity ?? this.humanity,
    );
  }

  Map<String, dynamic> toJson() => {
        '資産': asset,
        '社会的地位': status,
        '幸福度': happiness,
        '健康度': health,
        '人間性': humanity,
      };

  factory Results.fromJson(Map<String, dynamic> j) => Results(
        asset: (j['資産'] ?? 0) as int,
        // 互換性：旧キー（地位/幸福/健康）も読み取れるように
        status: (j['社会的地位'] ?? j['地位'] ?? 30) as int,
        happiness: (j['幸福度'] ?? j['幸福'] ?? 50) as int,
        health: (j['健康度'] ?? j['健康'] ?? 100) as int,
        humanity: (j['人間性'] ?? 0) as int,
      );
}

/// 顔パーツ構成（GDD §4.3.1）
class Avatar {
  final int hairId;       // 0-7
  final int hairColorId;  // 0-5
  final int eyeId;        // 0-5
  final int outlineId;    // 0-3
  final int skinId;       // 0-3

  const Avatar({
    this.hairId = 0,
    this.hairColorId = 0,
    this.eyeId = 0,
    this.outlineId = 0,
    this.skinId = 0,
  });

  Map<String, dynamic> toJson() => {
        'hair_id': hairId,
        'hair_color_id': hairColorId,
        'eye_id': eyeId,
        'outline_id': outlineId,
        'skin_id': skinId,
      };

  factory Avatar.fromJson(Map<String, dynamic> j) => Avatar(
        hairId: (j['hair_id'] ?? 0) as int,
        hairColorId: (j['hair_color_id'] ?? 0) as int,
        eyeId: (j['eye_id'] ?? 0) as int,
        outlineId: (j['outline_id'] ?? 0) as int,
        skinId: (j['skin_id'] ?? 0) as int,
      );
}

/// 親情報（GDD §4.4.2）
class ParentInfo {
  final String rarity;       // 標準/恵まれた/苦しい/特殊
  final String fatherJob;
  final String motherJob;
  final String wealthClass;  // 困窮/低所得/中流/上位中流/富裕
  final List<String> personality;
  final Map<String, int> geneticModifier; // 各能力に±5

  const ParentInfo({
    this.rarity = '標準',
    this.fatherJob = '会社員',
    this.motherJob = '専業主婦',
    this.wealthClass = '中流',
    this.personality = const [],
    this.geneticModifier = const {},
  });

  Map<String, dynamic> toJson() => {
        'rarity': rarity,
        'father_job': fatherJob,
        'mother_job': motherJob,
        'wealth_class': wealthClass,
        'personality': personality,
        'genetic_modifier': geneticModifier,
      };

  factory ParentInfo.fromJson(Map<String, dynamic> j) => ParentInfo(
        rarity: (j['rarity'] ?? '標準') as String,
        fatherJob: (j['father_job'] ?? '会社員') as String,
        motherJob: (j['mother_job'] ?? '専業主婦') as String,
        wealthClass: (j['wealth_class'] ?? '中流') as String,
        personality:
            (j['personality'] as List?)?.map((e) => e as String).toList() ?? [],
        geneticModifier: (j['genetic_modifier'] as Map?)
                ?.map((k, v) => MapEntry(k as String, v as int)) ??
            {},
      );
}

/// 履歴1件（GDD §18.3.2 history[]）
class HistoryEntry {
  final int year;
  final int month;
  final String eventId;
  final String summary;

  const HistoryEntry({
    required this.year,
    required this.month,
    required this.eventId,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'event_id': eventId,
        'summary': summary,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        year: (j['year'] ?? 0) as int,
        month: (j['month'] ?? 0) as int,
        eventId: (j['event_id'] ?? '') as String,
        summary: (j['summary'] ?? '') as String,
      );
}

/// 家計情報（GDD §18.3.2 household）
class Household {
  final int monthlyIncome;
  final int monthlyExpense;
  final int savings;
  final Map<String, int> investments; // deposit / stock / crypto など
  final List<Map<String, dynamic>> loans;

  const Household({
    this.monthlyIncome = 0,
    this.monthlyExpense = 0,
    this.savings = 0,
    this.investments = const {},
    this.loans = const [],
  });

  Map<String, dynamic> toJson() => {
        'monthly_income': monthlyIncome,
        'monthly_expense': monthlyExpense,
        'savings': savings,
        'investments': investments,
        'loans': loans,
      };

  factory Household.fromJson(Map<String, dynamic> j) => Household(
        monthlyIncome: (j['monthly_income'] ?? 0) as int,
        monthlyExpense: (j['monthly_expense'] ?? 0) as int,
        savings: (j['savings'] ?? 0) as int,
        investments: (j['investments'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            {},
        loans: (j['loans'] as List?)
                ?.map((e) => (e as Map).cast<String, dynamic>())
                .toList() ??
            [],
      );
}

/// 現在キャラクターの完全な状態
class Character {
  final String id;
  final int generation;
  final String name;
  final Gender gender;
  final AbilityKind strength;  // 強み（5択 + 隠し5）
  final String strengthLabel;  // 隠し強み「変人」等で「カスタム」が入る場合の保険
  final Avatar avatar;
  final ParentInfo parent;
  final Era era;
  final int yearIndex;   // ○年目
  final int age;
  final Stats stats;
  final Results results;
  final Map<SkillTree, int> skillPoints;
  final List<String> skillsUnlocked;
  final List<String> giftsUnlocked;     // 異才ノードID
  final Map<String, dynamic> flags;     // married, children, bankruptcy 等
  final Household household;
  final List<HistoryEntry> history;
  final int stress;

  const Character({
    required this.id,
    this.generation = 1,
    required this.name,
    required this.gender,
    required this.strength,
    this.strengthLabel = '',
    required this.avatar,
    required this.parent,
    required this.era,
    this.yearIndex = 0,
    this.age = 0,
    this.stats = const Stats(),
    this.results = const Results(),
    this.skillPoints = const {},
    this.skillsUnlocked = const [],
    this.giftsUnlocked = const [],
    this.flags = const {},
    this.household = const Household(),
    this.history = const [],
    this.stress = 0,
  });

  Character copyWith({
    String? id,
    int? generation,
    String? name,
    Gender? gender,
    AbilityKind? strength,
    Avatar? avatar,
    ParentInfo? parent,
    Era? era,
    int? yearIndex,
    int? age,
    Stats? stats,
    Results? results,
    Map<SkillTree, int>? skillPoints,
    List<String>? skillsUnlocked,
    List<String>? giftsUnlocked,
    Map<String, dynamic>? flags,
    Household? household,
    List<HistoryEntry>? history,
    int? stress,
  }) {
    return Character(
      id: id ?? this.id,
      generation: generation ?? this.generation,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      strength: strength ?? this.strength,
      avatar: avatar ?? this.avatar,
      parent: parent ?? this.parent,
      era: era ?? this.era,
      yearIndex: yearIndex ?? this.yearIndex,
      age: age ?? this.age,
      stats: stats ?? this.stats,
      results: results ?? this.results,
      skillPoints: skillPoints ?? this.skillPoints,
      skillsUnlocked: skillsUnlocked ?? this.skillsUnlocked,
      giftsUnlocked: giftsUnlocked ?? this.giftsUnlocked,
      flags: flags ?? this.flags,
      household: household ?? this.household,
      history: history ?? this.history,
      stress: stress ?? this.stress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'generation': generation,
        'name': name,
        'gender': gender.label,
        'strength': strength.label,
        'strength_label': strengthLabel,
        'avatar': avatar.toJson(),
        'parent': parent.toJson(),
        'era': era.label,
        'year_index': yearIndex,
        'age': age,
        'stats': stats.toJson(),
        'results': results.toJson(),
        'skill_points': skillPoints.map((k, v) => MapEntry(k.label, v)),
        'skills_unlocked': skillsUnlocked,
        'gifts_unlocked': giftsUnlocked,
        'flags': flags,
        'household': household.toJson(),
        'history': history.map((e) => e.toJson()).toList(),
        'stress': stress,
      };

  factory Character.fromJson(Map<String, dynamic> j) {
    final spJson = (j['skill_points'] as Map?)?.cast<String, dynamic>() ?? {};
    final skillPoints = <SkillTree, int>{};
    for (final tree in SkillTree.values) {
      final v = spJson[tree.label];
      if (v != null) skillPoints[tree] = (v as num).toInt();
    }

    return Character(
      id: (j['id'] ?? '') as String,
      generation: (j['generation'] ?? 1) as int,
      name: (j['name'] ?? '') as String,
      gender: Gender.fromString(j['gender'] as String?) ?? Gender.male,
      strength: AbilityKind.fromString(j['strength'] as String?) ?? AbilityKind.brain,
      strengthLabel: (j['strength_label'] ?? '') as String,
      avatar: Avatar.fromJson((j['avatar'] as Map?)?.cast<String, dynamic>() ?? {}),
      parent: ParentInfo.fromJson((j['parent'] as Map?)?.cast<String, dynamic>() ?? {}),
      era: Era.fromString((j['era'] ?? '令和') as String),
      yearIndex: (j['year_index'] ?? 0) as int,
      age: (j['age'] ?? 0) as int,
      stats: Stats.fromJson((j['stats'] as Map?)?.cast<String, dynamic>() ?? {}),
      results: Results.fromJson((j['results'] as Map?)?.cast<String, dynamic>() ?? {}),
      skillPoints: skillPoints,
      skillsUnlocked:
          (j['skills_unlocked'] as List?)?.map((e) => e as String).toList() ?? [],
      giftsUnlocked:
          (j['gifts_unlocked'] as List?)?.map((e) => e as String).toList() ?? [],
      flags: (j['flags'] as Map?)?.cast<String, dynamic>() ?? {},
      household: Household.fromJson(
          (j['household'] as Map?)?.cast<String, dynamic>() ?? {}),
      history: (j['history'] as List?)
              ?.map((e) =>
                  HistoryEntry.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          [],
      stress: (j['stress'] ?? 0) as int,
    );
  }
}
