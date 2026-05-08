// ============================================================
// EffectParser / 効果テキストの構造化パーサー
//
// xlsx 由来の自由テキスト「資産-30万 / 健康+15」等を
// Map<String, int> に変換する。
// GDD §10.3.2 の効果記法をパース対象とする。
// ============================================================

class EffectParseResult {
  final Map<String, int> effects;
  final List<String> flagsToSet;
  final List<String> warnings; // パース失敗箇所

  const EffectParseResult({
    this.effects = const {},
    this.flagsToSet = const [],
    this.warnings = const [],
  });
}

class EffectParser {
  /// 「資産-30万 / 健康+15」のような文字列をパース
  static EffectParseResult parse(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const EffectParseResult();
    }
    final effects = <String, int>{};
    final flags = <String>[];
    final warnings = <String>[];

    // セパレータで分割：「/」「、」「,」「・」
    final parts = text.split(RegExp(r'[/、,・]'));

    for (final raw in parts) {
      final part = raw.trim();
      if (part.isEmpty) continue;

      final parsed = _parseOne(part);
      if (parsed == null) {
        warnings.add(part);
        continue;
      }

      if (parsed.flag != null) {
        flags.add(parsed.flag!);
      } else if (parsed.statKey != null && parsed.delta != null) {
        // 内部キーに正規化（社会的地位→地位、幸福度→幸福、健康度→健康）
        final key = _canonicalize(parsed.statKey!);
        effects[key] = (effects[key] ?? 0) + parsed.delta!;
      } else {
        warnings.add(part);
      }
    }

    return EffectParseResult(
      effects: effects,
      flagsToSet: flags,
      warnings: warnings,
    );
  }

  /// 内部キー正規化
  /// Character のキーは「資産/地位/幸福/健康/人間性」（GDD §13.7.2）
  static String _canonicalize(String s) {
    if (s == '社会的地位') return '地位';
    if (s == '幸福度') return '幸福';
    if (s == '健康度') return '健康';
    if (s == 'コミュ力') return 'コミュ';
    return s;
  }

  /// 「資産-30万」「健康+15」「人間性-20」「+5万」「資産-30%」などをパース
  static _ParsedItem? _parseOne(String s) {
    // 1. ステータスキー＋数値変動の典型パターン
    final mStat = RegExp(
            r'(頭脳|肉体|コミュ力?|センス|運|資産|社会的地位|地位|幸福度|幸福|健康度|健康|人間性)\s*([+-]?[\d.]+)\s*([万億]?)\s*(円|%|％)?')
        .firstMatch(s);
    if (mStat != null) {
      final key = mStat.group(1)!;
      final raw = double.tryParse(mStat.group(2)!) ?? 0;
      final unit = mStat.group(3) ?? '';
      final suffix = mStat.group(4) ?? '';
      // %変動はサポート外（warningsで返すため null）
      if (suffix == '%' || suffix == '％') {
        return null;
      }
      final delta = _convertWithUnit(raw, unit, key);
      if (delta != null) {
        return _ParsedItem(statKey: key, delta: delta);
      }
    }

    // 2. 「+5万」「-100万円」のような頭部位（資産推定）
    final mShortMoney = RegExp(r'^([+-])\s*([\d.]+)\s*([万億])\s*円?$').firstMatch(s);
    if (mShortMoney != null) {
      final sign = mShortMoney.group(1) == '-' ? -1 : 1;
      final raw = double.tryParse(mShortMoney.group(2)!) ?? 0;
      final unit = mShortMoney.group(3)!;
      final delta = (sign *
              raw *
              (unit == '億'
                  ? 100000000
                  : unit == '万'
                      ? 10000
                      : 1))
          .round();
      return _ParsedItem(statKey: '資産', delta: delta);
    }

    // 3. 連鎖系・フラグ系（「無職」「結婚」「子育て開始」「破産」「犯罪歴」等）
    final flagPatterns = {
      '無職': 'unemployed',
      '結婚': 'married',
      '離婚': 'divorced',
      '子育て開始': 'child_started',
      '破産': 'bankruptcy',
      '犯罪歴': 'crime_record',
      '転職': 'job_changed',
      '再就職': 'job_resumed',
    };
    for (final entry in flagPatterns.entries) {
      if (s.contains(entry.key)) {
        return _ParsedItem(flag: entry.value);
      }
    }

    // 4. 「運次第」「運次第で〜」等は確率分岐扱い → 当面 unknown でフラグ化
    if (s.contains('運次第')) {
      return _ParsedItem(flag: 'luck_branch');
    }

    return null;
  }

  /// 単位変換
  /// 「資産-30万」 → -300000
  /// 「資産-30%」 → 比率なので別扱い（現状はnull）
  /// その他のステは単位なし整数
  static int? _convertWithUnit(double raw, String unit, String statKey) {
    if (unit == '%' || unit == '％') {
      // %変動は当面サポート外（現Character構造で表現できないため）
      return null;
    }
    if (statKey != '資産') {
      return raw.round();
    }
    // 資産の単位
    switch (unit) {
      case '億':
        return (raw * 100000000).round();
      case '万':
        return (raw * 10000).round();
      default:
        return raw.round();
    }
  }
}

class _ParsedItem {
  final String? statKey;
  final int? delta;
  final String? flag;

  _ParsedItem({this.statKey, this.delta, this.flag});
}
