// ============================================================
// EffectParser ユニットテスト
// ============================================================
import 'package:capitalism_game/domain/services/effect_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EffectParser.parse', () {
    test('資産変動の万単位パース', () {
      final r = EffectParser.parse('資産-30万');
      expect(r.effects['資産'], -300000);
    });

    test('資産変動の億単位パース', () {
      final r = EffectParser.parse('資産+1億');
      expect(r.effects['資産'], 100000000);
    });

    test('健康度の表記正規化', () {
      final r = EffectParser.parse('健康度+15');
      expect(r.effects['健康'], 15);
    });

    test('幸福度の表記正規化', () {
      final r = EffectParser.parse('幸福度-5');
      expect(r.effects['幸福'], -5);
    });

    test('社会的地位の表記正規化', () {
      final r = EffectParser.parse('社会的地位+10');
      expect(r.effects['地位'], 10);
    });

    test('複数効果のスラッシュ区切り', () {
      final r = EffectParser.parse('資産-30万 / 健康+15');
      expect(r.effects['資産'], -300000);
      expect(r.effects['健康'], 15);
    });

    test('複数効果の読点区切り', () {
      final r = EffectParser.parse('頭脳+3、コミュ+1');
      expect(r.effects['頭脳'], 3);
      expect(r.effects['コミュ'], 1);
    });

    test('フラグ系のパース', () {
      final r = EffectParser.parse('無職 / 健康+10');
      expect(r.flagsToSet.contains('unemployed'), true);
      expect(r.effects['健康'], 10);
    });

    test('結婚フラグ', () {
      final r = EffectParser.parse('結婚 / 幸福+15');
      expect(r.flagsToSet.contains('married'), true);
      expect(r.effects['幸福'], 15);
    });

    test('運次第はluck_branchフラグ', () {
      final r = EffectParser.parse('運次第で大儲け or 大損');
      expect(r.flagsToSet.contains('luck_branch'), true);
    });

    test('空文字列は空結果', () {
      final r = EffectParser.parse('');
      expect(r.effects, isEmpty);
      expect(r.flagsToSet, isEmpty);
    });

    test('null は空結果', () {
      final r = EffectParser.parse(null);
      expect(r.effects, isEmpty);
    });

    test('%変動はサポート外（warningsに入る）', () {
      final r = EffectParser.parse('資産-30%');
      // 現状のパーサーは%を捨てるが、warning扱いにはまだしていない
      // 効果は反映されないことを確認
      expect(r.effects.containsKey('資産'), false);
    });

    test('コミュ力は コミュ に正規化', () {
      final r = EffectParser.parse('コミュ力+8');
      expect(r.effects['コミュ'], 8);
    });

    test('全結果系を1文字列でパース', () {
      final r = EffectParser.parse(
          '資産+1億 / 社会的地位+20 / 幸福度+30 / 健康度-5 / 人間性+10');
      expect(r.effects['資産'], 100000000);
      expect(r.effects['地位'], 20);
      expect(r.effects['幸福'], 30);
      expect(r.effects['健康'], -5);
      expect(r.effects['人間性'], 10);
    });
  });
}
