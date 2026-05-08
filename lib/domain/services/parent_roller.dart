// ============================================================
// ParentRoller / GDD §4.4 親ガチャ抽選
//
// レアリティ4階層：
//  - 標準 50%
//  - 恵まれた 25%
//  - 苦しい 20%
//  - 特殊 5%（うち：富裕層／極貧／養子／海外帰国子女 が均等）
// ============================================================
import 'dart:math' as math;

import '../../core/constants/enums.dart';
import '../models/character.dart';

class ParentRollResult {
  final ParentInfo info;
  final int initialAsset;     // 初期所持金（円相当、時代別係数で実額化）
  final String description;   // プレイヤー向け説明文

  const ParentRollResult({
    required this.info,
    required this.initialAsset,
    required this.description,
  });
}

class ParentRoller {
  final math.Random _random;

  ParentRoller({int? seed}) : _random = math.Random(seed);

  /// 親ガチャを1回引く（GDD §4.4.3 レアリティ分布準拠）
  ParentRollResult roll(Era era) {
    final r = _random.nextDouble();
    if (r < 0.50) return _rollStandard(era);
    if (r < 0.75) return _rollBlessed(era);
    if (r < 0.95) return _rollDifficult(era);
    return _rollSpecial(era);
  }

  // ============================================================
  // 標準（50%）
  // ============================================================
  ParentRollResult _rollStandard(Era era) {
    final fatherJobs = ['会社員', '公務員', '自営業'];
    final motherJobs = ['会社員', '専業主婦', 'パート'];
    return ParentRollResult(
      info: ParentInfo(
        rarity: '標準',
        fatherJob: _pick(fatherJobs),
        motherJob: _pick(motherJobs),
        wealthClass: '中流',
        personality: ['平均的'],
        geneticModifier: _genetics(0),
      ),
      initialAsset: _eraAdjusted(era, 50000),
      description: 'ごく一般的な家庭。中流階級の安定した出発点。',
    );
  }

  // ============================================================
  // 恵まれた（25%）
  // ============================================================
  ParentRollResult _rollBlessed(Era era) {
    final fatherJobs = ['専門職', '大企業会社員', '医師', '弁護士'];
    final motherJobs = ['専業主婦', '専門職', '会社員'];
    return ParentRollResult(
      info: ParentInfo(
        rarity: '恵まれた',
        fatherJob: _pick(fatherJobs),
        motherJob: _pick(motherJobs),
        wealthClass: '上位中流',
        personality: ['教育熱心', '愛情深い'],
        geneticModifier: _genetics(2),
      ),
      initialAsset: _eraAdjusted(era, 150000),
      description: '潤沢な仕送りと教育機会。能力の伸びしろが大きい家庭。',
    );
  }

  // ============================================================
  // 苦しい（20%）
  // ============================================================
  ParentRollResult _rollDifficult(Era era) {
    final fatherJobs = ['フリーター', '工場勤務', '無職', '日雇い'];
    final motherJobs = ['パート', 'シングルマザー', '専業主婦'];
    return ParentRollResult(
      info: ParentInfo(
        rarity: '苦しい',
        fatherJob: _pick(fatherJobs),
        motherJob: _pick(motherJobs),
        wealthClass: '低所得',
        personality: ['苦労人', 'たくましい'],
        geneticModifier: _genetics(-1),
      ),
      initialAsset: _eraAdjusted(era, 10000),
      description: '家計は厳しいが、踏ん張りどころから始まる人生。',
    );
  }

  // ============================================================
  // 特殊（5%）：4種を均等に
  // ============================================================
  ParentRollResult _rollSpecial(Era era) {
    final variant = _random.nextInt(4);
    switch (variant) {
      case 0:
        return ParentRollResult(
          info: ParentInfo(
            rarity: '特殊・富裕層',
            fatherJob: '富裕層',
            motherJob: '富裕層',
            wealthClass: '富裕',
            personality: ['誇り高い', '世間知らず'],
            geneticModifier: _genetics(3),
          ),
          initialAsset: _eraAdjusted(era, 100000000),
          description: '資産家の家系。1億円相当の初期家計。',
        );
      case 1:
        return ParentRollResult(
          info: ParentInfo(
            rarity: '特殊・極貧',
            fatherJob: '不明',
            motherJob: '不明',
            wealthClass: '困窮',
            personality: ['たくましい', '抗う'],
            geneticModifier: _genetics(0),
          ),
          initialAsset: 0,
          description: '極貧スタート。最初の月から家計緊急事態。',
        );
      case 2:
        return ParentRollResult(
          info: ParentInfo(
            rarity: '特殊・養子',
            fatherJob: '不明',
            motherJob: '不明',
            wealthClass: '中流',
            personality: ['アイデンティティ', '探求心'],
            geneticModifier: _genetics(1),
          ),
          initialAsset: _eraAdjusted(era, 30000),
          description: '養子・孤児院出身。特殊イベントが解放される。',
        );
      default:
        return ParentRollResult(
          info: ParentInfo(
            rarity: '特殊・帰国子女',
            fatherJob: '海外駐在員',
            motherJob: '海外駐在員配偶者',
            wealthClass: '上位中流',
            personality: ['国際感覚', '柔軟'],
            geneticModifier: {
              ..._genetics(1),
              'コミュ': 10,
              '頭脳': 5,
            },
          ),
          initialAsset: _eraAdjusted(era, 200000),
          description: '海外帰国子女。コミュ＋10／頭脳＋5の特殊ボーナス。',
        );
    }
  }

  // ============================================================
  // ヘルパー
  // ============================================================

  String _pick(List<String> list) =>
      list[_random.nextInt(list.length)];

  /// 時代別の物価係数で初期資産を実額化（GDD §7.3.4）
  int _eraAdjusted(Era era, int baseYen) {
    final factor = switch (era) {
      Era.showa => 1.0,
      Era.heisei => 11.0,
      Era.reiwa => 15.0,
      Era.future => 20.0,
    };
    return (baseYen * factor).round();
  }

  /// 親遺伝の補正（各能力±5の中で偏り）
  Map<String, int> _genetics(int bias) {
    final keys = ['頭脳', '肉体', 'コミュ', 'センス', '運'];
    final result = <String, int>{};
    for (final k in keys) {
      result[k] = (_random.nextInt(11) - 5) + bias;
    }
    return result;
  }
}
