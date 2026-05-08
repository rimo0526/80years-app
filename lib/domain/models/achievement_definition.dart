// ============================================================
// AchievementDefinition / achievements.json の Dart マッピング
// GDD §16.2 / §18.2.3 準拠
// ============================================================

enum AchievementGrade {
  bronze('ブロンズ'),
  silver('シルバー'),
  gold('ゴールド'),
  platinum('プラチナ');

  final String label;
  const AchievementGrade(this.label);

  static AchievementGrade fromLabel(String s) {
    for (final g in AchievementGrade.values) {
      if (g.label == s) return g;
    }
    return AchievementGrade.bronze;
  }
}

class AchievementDefinition {
  final String id;            // A-001..A-100
  final String category;      // キャリア / 家族 / ... / 隠し
  final AchievementGrade grade;
  final String title;
  final String description;
  final String unlockCondition;
  final List<String> applicableEras;
  final bool isHidden;
  final String reward;
  final String? notes;

  const AchievementDefinition({
    required this.id,
    required this.category,
    required this.grade,
    required this.title,
    required this.description,
    required this.unlockCondition,
    required this.applicableEras,
    this.isHidden = false,
    required this.reward,
    this.notes,
  });

  factory AchievementDefinition.fromJson(Map<String, dynamic> j) =>
      AchievementDefinition(
        id: (j['id'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        grade: AchievementGrade.fromLabel(j['grade'] as String? ?? 'ブロンズ'),
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        unlockCondition: (j['unlock_condition'] ?? '') as String,
        applicableEras: (j['applicable_eras'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            ['全時代'],
        isHidden: (j['is_hidden'] ?? false) as bool,
        reward: (j['reward'] ?? '') as String,
        notes: j['notes'] as String?,
      );
}
