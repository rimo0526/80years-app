// ============================================================
// 列挙型 / GDD §1.2 用語集準拠
// ============================================================

/// 性別（GDD §4.2.1）
enum Gender {
  male('男'),
  female('女');

  final String label;
  const Gender(this.label);

  static Gender? fromString(String? s) {
    if (s == null) return null;
    return Gender.values.firstWhere(
      (e) => e.label == s || e.name == s,
      orElse: () => Gender.male,
    );
  }
}

/// 強み・能力5系統（GDD §4.2.2 / §1.2.1）
/// 強みも能力名も「肉体」で統一（v1.2 確定）
enum AbilityKind {
  brain('頭脳'),
  body('肉体'),
  social('コミュ'),
  sense('センス'),
  luck('運');

  final String label;
  const AbilityKind(this.label);

  static AbilityKind? fromString(String? s) {
    if (s == null) return null;
    for (final e in AbilityKind.values) {
      if (e.label == s || e.name == s) return e;
    }
    return null;
  }
}

/// 結果系ステータス（GDD §5.1.3）
/// 内部キーは label の通り（資産/地位/幸福/健康/人間性）
/// 表示時は ResultLabel.display で「社会的地位/幸福度/健康度」に変換
enum ResultKind {
  asset('資産', '資産'),
  status('地位', '社会的地位'),
  happiness('幸福', '幸福度'),
  health('健康', '健康度'),
  humanity('人間性', '人間性');

  final String key;
  final String display;
  const ResultKind(this.key, this.display);
}

/// 時代（GDD §7.1.1 v1.2 時代固定方式）
enum Era {
  showa('昭和', 72),
  heisei('平成', 78),
  reiwa('令和', 84),
  future('近未来', 90);

  final String label;
  final int baseLifespan; // 基本期待寿命（GDD §5.4.4 B-1）
  const Era(this.label, this.baseLifespan);

  static Era fromString(String s) {
    return Era.values.firstWhere(
      (e) => e.label == s || e.name == s,
      orElse: () => Era.reiwa,
    );
  }
}

/// 人生フェーズ（GDD §3.3.1 / §7.2.1）
enum LifePhase {
  childhood('子供期', 0, 14),
  youth('青年期', 15, 29),
  middle('壮年期', 30, 59),
  elder('老年期', 60, 130);

  final String label;
  final int minAge;
  final int maxAge;
  const LifePhase(this.label, this.minAge, this.maxAge);

  static LifePhase forAge(int age) {
    for (final p in LifePhase.values) {
      if (age >= p.minAge && age <= p.maxAge) return p;
    }
    return LifePhase.elder;
  }
}

/// スキルツリー系統（GDD §6.1）
enum SkillTree {
  brain('頭脳'),
  body('肉体'),
  social('コミュ'),
  sense('センス'),
  gift('異才');

  final String label;
  const SkillTree(this.label);
}
