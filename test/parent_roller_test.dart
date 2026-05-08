// ============================================================
// ParentRoller ユニットテスト
// ============================================================
import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/services/parent_roller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParentRoller', () {
    test('1回引いて結果が返る', () {
      final r = ParentRoller(seed: 1);
      final result = r.roll(Era.reiwa);
      expect(result.info.rarity, isNotEmpty);
      expect(result.initialAsset, greaterThanOrEqualTo(0));
    });

    test('レアリティ分布：1000回で各階層が想定範囲', () {
      final counts = {'標準': 0, '恵まれた': 0, '苦しい': 0, '特殊': 0};
      for (var seed = 0; seed < 1000; seed++) {
        final result = ParentRoller(seed: seed).roll(Era.reiwa);
        final r = result.info.rarity;
        if (r == '標準') counts['標準'] = counts['標準']! + 1;
        else if (r == '恵まれた') counts['恵まれた'] = counts['恵まれた']! + 1;
        else if (r == '苦しい') counts['苦しい'] = counts['苦しい']! + 1;
        else counts['特殊'] = counts['特殊']! + 1;
      }
      // ±10%のブレを許容
      expect(counts['標準'], greaterThan(400));
      expect(counts['標準'], lessThan(600));
      expect(counts['恵まれた'], greaterThan(150));
      expect(counts['恵まれた'], lessThan(350));
      expect(counts['苦しい'], greaterThan(100));
      expect(counts['苦しい'], lessThan(300));
      expect(counts['特殊'], greaterThan(20));
      expect(counts['特殊'], lessThan(100));
    });

    test('時代別の初期資産係数：昭和は令和より少ない（同レア）', () {
      // 同シードで同じレアになることを利用
      // 違うレアなら比較できないので、シードを固定して同レアを引く
      var foundComparable = false;
      for (var s = 0; s < 100; s++) {
        final showa = ParentRoller(seed: s).roll(Era.showa);
        final reiwa = ParentRoller(seed: s).roll(Era.reiwa);
        if (showa.info.rarity == reiwa.info.rarity &&
            showa.initialAsset > 0 &&
            reiwa.initialAsset > 0) {
          expect(showa.initialAsset, lessThan(reiwa.initialAsset));
          foundComparable = true;
          break;
        }
      }
      expect(foundComparable, true,
          reason: '同レアの組合せが100seed内で見つかること');
    });

    test('特殊レアのいずれかは富裕層・極貧・養子・帰国子女', () {
      final variants = <String>{};
      for (var seed = 0; seed < 2000; seed++) {
        final result = ParentRoller(seed: seed).roll(Era.reiwa);
        if (result.info.rarity.startsWith('特殊')) {
          variants.add(result.info.rarity);
        }
      }
      // 4種すべて出現するはず
      expect(variants.length, greaterThanOrEqualTo(3),
          reason: '4種のうち少なくとも3種が観測される');
    });
  });
}
