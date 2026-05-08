// ============================================================
// EventDefinition / events.json の Dart マッピング
// GDD §10 / §18.2.1 準拠
// ============================================================
import '../../core/constants/enums.dart';

/// イベント1件分の選択肢
class EventChoice {
  final String label;
  final String effectText; // 例「資産-30万 / 健康+15」自由テキスト

  const EventChoice({required this.label, required this.effectText});

  factory EventChoice.fromJson(Map<String, dynamic> j) => EventChoice(
        label: (j['label'] ?? '') as String,
        effectText: (j['effect_text'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'effect_text': effectText,
      };
}

/// 発生確率の種別（GDD §10.2.2）
enum TriggerRateKind {
  yearly,         // 年X%
  monthly,        // 月X%
  always,         // 必発 / 時代必発
  conditional,    // 条件発動（外部からトリガー）
  unknown,
}

class TriggerRate {
  final TriggerRateKind kind;
  final double monthlyRate; // 月率（kind=conditional/always以外で使用）

  const TriggerRate({required this.kind, this.monthlyRate = 0});

  /// raw文字列をパース：「年5%」「月3%」「必発」「条件発動」など
  factory TriggerRate.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const TriggerRate(kind: TriggerRateKind.unknown, monthlyRate: 0.05 / 12);
    }
    final s = raw.trim();
    if (s.contains('必発')) {
      return const TriggerRate(kind: TriggerRateKind.always, monthlyRate: 1.0);
    }
    if (s.contains('条件発動')) {
      return const TriggerRate(kind: TriggerRateKind.conditional);
    }
    if (s.contains('時代依存')) {
      return const TriggerRate(kind: TriggerRateKind.conditional);
    }
    if (s.contains('任意')) {
      return const TriggerRate(kind: TriggerRateKind.conditional);
    }
    // 「年X%」「月X%」を抽出
    final m = RegExp(r'(年|月)\s*([\d.]+)\s*%').firstMatch(s);
    if (m != null) {
      final unit = m.group(1)!;
      final pct = double.tryParse(m.group(2)!) ?? 5;
      final monthly = unit == '月' ? pct / 100 : pct / 100 / 12;
      return TriggerRate(
        kind: unit == '月' ? TriggerRateKind.monthly : TriggerRateKind.yearly,
        monthlyRate: monthly,
      );
    }
    // 「年X回」のような場合は1回／年として扱う
    if (s.contains('年1回')) {
      return const TriggerRate(kind: TriggerRateKind.yearly, monthlyRate: 1 / 12);
    }
    // フォールバック
    return const TriggerRate(kind: TriggerRateKind.unknown, monthlyRate: 0.05 / 12);
  }
}

/// 発生条件の最低限のパース（年齢のみ）
/// 例：「30歳〜 / 体力<50で発生率↑」 → minAge=30
class TriggerCondition {
  final int? minAge;
  final int? maxAge;
  final String? rawText;

  const TriggerCondition({this.minAge, this.maxAge, this.rawText});

  factory TriggerCondition.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const TriggerCondition();
    }
    final s = raw.trim();
    int? min;
    int? max;

    // 「N歳〜」「N歳〜M歳」「N歳以上」「N歳以下」等を抽出
    final mRange = RegExp(r'(\d+)\s*歳?\s*[〜～~]\s*(\d+)\s*歳').firstMatch(s);
    if (mRange != null) {
      min = int.tryParse(mRange.group(1)!);
      max = int.tryParse(mRange.group(2)!);
    } else {
      final mMin = RegExp(r'(\d+)\s*歳[〜～~以上]').firstMatch(s);
      if (mMin != null) min = int.tryParse(mMin.group(1)!);
      final mMax = RegExp(r'(\d+)\s*歳以下').firstMatch(s);
      if (mMax != null) max = int.tryParse(mMax.group(1)!);
    }
    return TriggerCondition(minAge: min, maxAge: max, rawText: s);
  }

  bool matchesAge(int age) {
    if (minAge != null && age < minAge!) return false;
    if (maxAge != null && age > maxAge!) return false;
    return true;
  }
}

/// イベント1件
class EventDefinition {
  final String id;          // L-001 / I-009 / E-005 / S-004 / T-014
  final String sheet;       // ライフイベント / 収入連動 / etc.
  final String category;
  final String name;
  final String description;
  final TriggerCondition condition;
  final TriggerRate rate;
  final List<EventChoice> choices;
  final List<String> applicableEras; // ["全時代"] / ["令和", "近未来"]
  final bool isHidden;
  final String? unlocksSkill;
  final String? chainFrom;
  final int priority;

  const EventDefinition({
    required this.id,
    required this.sheet,
    required this.category,
    required this.name,
    required this.description,
    required this.condition,
    required this.rate,
    required this.choices,
    required this.applicableEras,
    this.isHidden = false,
    this.unlocksSkill,
    this.chainFrom,
    this.priority = 60,
  });

  /// この時代に発火可能か
  bool isAvailableInEra(Era era) {
    if (applicableEras.contains('全時代')) return true;
    return applicableEras.contains(era.label);
  }

  factory EventDefinition.fromJson(Map<String, dynamic> j) {
    final choicesJson = (j['choices'] as List?) ?? [];
    final choices = choicesJson
        .map((e) => EventChoice.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return EventDefinition(
      id: (j['id'] ?? '') as String,
      sheet: (j['sheet'] ?? '') as String,
      category: (j['category'] ?? '') as String,
      name: (j['name'] ?? '') as String,
      description: (j['description'] ?? '') as String,
      condition: TriggerCondition.parse(j['trigger_condition'] as String?),
      rate: TriggerRate.parse(j['trigger_rate'] as String?),
      choices: choices,
      applicableEras: (j['applicable_eras'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          ['全時代'],
      isHidden: (j['is_hidden'] ?? false) as bool,
      unlocksSkill: j['unlocks_skill'] as String?,
      chainFrom: j['chain_from'] as String?,
      priority: ((j['priority'] ?? 60) as num).toInt(),
    );
  }
}
