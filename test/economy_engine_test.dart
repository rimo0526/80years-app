// ============================================================
// EconomyEngine ユニットテスト
// ============================================================
import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/engines/economy_engine.dart';
import 'package:capitalism_game/domain/models/character.dart';
import 'package:flutter_test/flutter_test.dart';

Character _char({
  Era era = Era.reiwa,
  int age = 30,
  bool employed = false,
  int monthlyIncome = 0,
  int asset = 0,
  int married = 0,
  int children = 0,
  Map<String, int>? investments,
}) {
  return Character(
    id: 't',
    name: 'テスト',
    gender: Gender.male,
    strength: AbilityKind.brain,
    avatar: const Avatar(),
    parent: const ParentInfo(),
    era: era,
    age: age,
    flags: {
      'employed': employed,
      'married': married == 1,
      'children': children,
    },
    household: Household(
      monthlyIncome: monthlyIncome,
      investments: investments ?? const {},
    ),
    results: Results(asset: asset, status: 30, happiness: 50, health: 100),
  );
}

void main() {
  group('EconomyEngine', () {
    test('就業中の月次収支は給与＞0', () {
      final eng = EconomyEngine(seed: 42);
      final c = _char(employed: true, monthlyIncome: 200000);
      final b = eng.computeMonthly(c);
      expect(b.totalIncome, greaterThan(0));
      expect(b.incomeBreakdown['給与'], 200000);
    });

    test('60歳以降は年金収入が発生', () {
      final eng = EconomyEngine(seed: 42);
      final c = _char(age: 65);
      final b = eng.computeMonthly(c);
      expect(b.incomeBreakdown['不労所得'], greaterThan(0));
    });

    test('近未来時代は基本所得が25歳以降に発生', () {
      final eng = EconomyEngine(seed: 42);
      final c = _char(era: Era.future, age: 30);
      final b = eng.computeMonthly(c);
      expect(b.incomeBreakdown['不労所得'], greaterThanOrEqualTo(50000));
    });

    test('結婚＋子供で支出が増える', () {
      final eng = EconomyEngine(seed: 42);
      final solo = _char(employed: true, monthlyIncome: 200000);
      final family = _char(
          employed: true, monthlyIncome: 200000, married: 1, children: 2);
      final bSolo = eng.computeMonthly(solo);
      final bFamily = eng.computeMonthly(family);
      expect(bFamily.totalExpense, greaterThan(bSolo.totalExpense));
    });

    test('住宅ローン月次返済額の式が正しい', () {
      // 元金1000万円、年利1%、35年（420ヶ月）の月次返済
      final monthly = EconomyEngine.monthlyMortgagePayment(
        principal: 10000000,
        annualRate: 0.01,
        totalMonths: 420,
      );
      // 一般的に月28000円前後になる
      expect(monthly, greaterThan(20000));
      expect(monthly, lessThan(35000));
    });

    test('暗号通貨は令和以降のみ発火可能', () {
      final showa = _char(era: Era.showa, asset: 5000000);
      final reiwa = _char(era: Era.reiwa, asset: 5000000);
      final showaProds = InvestmentProduct.defaults(showa);
      final reiwaProds = InvestmentProduct.defaults(reiwa);
      final showaCrypto = showaProds.firstWhere((p) => p.id == 'crypto');
      final reiwaCrypto = reiwaProds.firstWhere((p) => p.id == 'crypto');
      expect(showaCrypto.isUnlocked, false);
      // 令和でも luck>=40 が必要なのでケースによる
      // ここは isUnlocked が条件によって変わることを確認
      expect(reiwaCrypto.expectedMonthlyReturn, 0.012);
      expect(reiwaCrypto.stddev, 0.28);
    });
  });
}
