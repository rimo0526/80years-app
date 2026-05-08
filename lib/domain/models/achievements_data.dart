// ============================================================
// 実績達成データ / GDD §18.3.4 achievements ブロック準拠
// ============================================================

class AchievementsData {
  final List<String> unlocked;                  // achievement_id (A-001等)
  final List<String> tombDecorationsUnlocked;
  final List<String> hiddenStrengthsUnlocked;
  final List<String> hiddenErasUnlocked;

  const AchievementsData({
    this.unlocked = const [],
    this.tombDecorationsUnlocked = const [],
    this.hiddenStrengthsUnlocked = const [],
    this.hiddenErasUnlocked = const [],
  });

  AchievementsData copyWith({
    List<String>? unlocked,
    List<String>? tombDecorationsUnlocked,
    List<String>? hiddenStrengthsUnlocked,
    List<String>? hiddenErasUnlocked,
  }) {
    return AchievementsData(
      unlocked: unlocked ?? this.unlocked,
      tombDecorationsUnlocked:
          tombDecorationsUnlocked ?? this.tombDecorationsUnlocked,
      hiddenStrengthsUnlocked:
          hiddenStrengthsUnlocked ?? this.hiddenStrengthsUnlocked,
      hiddenErasUnlocked: hiddenErasUnlocked ?? this.hiddenErasUnlocked,
    );
  }

  Map<String, dynamic> toJson() => {
        'unlocked': unlocked,
        'tomb_decorations_unlocked': tombDecorationsUnlocked,
        'hidden_strengths_unlocked': hiddenStrengthsUnlocked,
        'hidden_eras_unlocked': hiddenErasUnlocked,
      };

  factory AchievementsData.fromJson(Map<String, dynamic> j) => AchievementsData(
        unlocked:
            (j['unlocked'] as List?)?.map((e) => e as String).toList() ?? [],
        tombDecorationsUnlocked: (j['tomb_decorations_unlocked'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        hiddenStrengthsUnlocked: (j['hidden_strengths_unlocked'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        hiddenErasUnlocked: (j['hidden_eras_unlocked'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
