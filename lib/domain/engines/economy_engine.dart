// ============================================================
// EconomyEngine / GDD §9 家計・経済システム本実装
//
// 月次収支の計算：
//  - 給与・副業・投資・年金の収入
//  - 住居・食費・交通・通信・娯楽・交際・保険・その他の支出
//  - 投資商品7種の月次リターン抽選（正規分布乱数）
//  - 住宅ローン返済額計算
//  - 破産判定
// ============================================================
import 'dart:math' as math;

import '../../core/constants/enums.dart';
import '../models/character.dart';

/// 月次収支結果
class MonthlyBalance {
  final int totalIncome;
  final int totalExpense;
  final int netCashflow; // 黒字なら+、赤字なら-
  final Map<String, int> incomeBreakdown;
  final Map<String, int> expenseBreakdown;
  final Map<String, int> investmentReturns; // 商品ID別リターン
  final bool bankrupt;

  const MonthlyBalance({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.investmentReturns,
    this.bankrupt = false,
  });
}

/// 投資商品の定義（GDD §9.5.2 + §9.5.6 暗号通貨）
class InvestmentProduct {
  final String id;
  final String name;
  final double expectedMonthlyReturn;
  final double stddev;
  final bool isUnlocked;

  const InvestmentProduct({
    required this.id,
    required this.name,
    required this.expectedMonthlyReturn,
    required this.stddev,
    this.isUnlocked = true,
  });

  static List<InvestmentProduct> defaults(Character c) {
    final eraDepositRate = _eraDepositRate(c.era);
    final isReiwaOrLater =
        c.era == Era.reiwa || c.era == Era.future;

    return [
      InvestmentProduct(
        id: 'deposit',
        name: '預金（普通）',
        expectedMonthlyReturn: eraDepositRate / 12,
        stddev: 0,
      ),
      InvestmentProduct(
        id: 'deposit_term',
        name: '預金（定期）',
        expectedMonthlyReturn: (eraDepositRate * 1.5) / 12,
        stddev: 0,
        isUnlocked: c.household.investments['deposit'] != null &&
            c.household.investments['deposit']! >= 1000000,
      ),
      InvestmentProduct(
        id: 'stock',
        name: '株式（標準）',
        expectedMonthlyReturn: 0.004,
        stddev: 0.04,
        isUnlocked: c.results.asset >= 500000,
      ),
      InvestmentProduct(
        id: 'stock_individual',
        name: '株式（個別銘柄）',
        expectedMonthlyReturn: 0.005,
        stddev: 0.08,
        isUnlocked: (c.household.investments['stock'] ?? 0) >= 1000000 &&
            c.stats.brain >= 50,
      ),
      InvestmentProduct(
        id: 'risk',
        name: 'リスク資産',
        expectedMonthlyReturn: 0.008,
        stddev: 0.12,
        isUnlocked: c.results.asset >= 2000000 && c.stats.luck >= 40,
      ),
      InvestmentProduct(
        id: 'real_estate',
        name: '不動産',
        expectedMonthlyReturn: 0.003,
        stddev: 0.01,
        isUnlocked: c.results.asset >= 10000000,
      ),
      InvestmentProduct(
        id: 'crypto',
        name: '暗号通貨',
        expectedMonthlyReturn: 0.012,
        stddev: 0.28,
        isUnlocked: isReiwaOrLater &&
            c.results.asset >= 1000000 &&
            c.stats.luck >= 40,
      ),
    ];
  }

  /// 時代別預金金利（年率、GDD §7.3.5）
  static double _eraDepositRate(Era era) {
    switch (era) {
      case Era.showa:
        return 0.05;
      case Era.heisei:
        return 0.04;
      case Era.reiwa:
        return 0.00001;
      case Era.future:
        return 0.01;
    }
  }
}

class EconomyEngine {
  final math.Random _random;

  EconomyEngine({int? seed}) : _random = math.Random(seed);

  /// 月次計算（GDD §9）
  MonthlyBalance computeMonthly(Character c) {
    final income = _computeIncome(c);
    final expense = _computeExpense(c);
    final invReturns = _computeInvestmentReturns(c);

    // 投資リターンも収入扱い
    final invTotal = invReturns.values.fold<int>(0, (s, v) => s + v);
    income['投資'] = (income['投資'] ?? 0) + invTotal;

    final totalIncome = income.values.fold<int>(0, (s, v) => s + v);
    final totalExpense = expense.values.fold<int>(0, (s, v) => s + v);
    final net = totalIncome - totalExpense;

    final newAsset = c.results.asset + net;

    // 破産判定（GDD §9.6.4）
    final bankruptcyAlready = (c.flags['bankruptcy'] == true);
    final bankrupt = !bankruptcyAlready &&
        (newAsset <= -5000000 || _bankruptcyCondition(c, totalIncome, totalExpense));

    return MonthlyBalance(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashflow: net,
      incomeBreakdown: income,
      expenseBreakdown: expense,
      investmentReturns: invReturns,
      bankrupt: bankrupt,
    );
  }

  /// 月次収入の内訳
  Map<String, int> _computeIncome(Character c) {
    final income = <String, int>{
      '給与': 0,
      '副業': 0,
      '投資': 0,
      '不労所得': 0,
      '臨時収入': 0,
      'その他': 0,
    };

    // 給与（職業フラグから）：簡易実装。本格的には Job クラスを別途
    if ((c.flags['employed'] as bool?) ?? false) {
      income['給与'] = c.household.monthlyIncome;
    }

    // 年金（60歳以降）
    if (c.age >= 60) {
      income['不労所得'] = (income['不労所得'] ?? 0) + _pensionAmount(c);
    }

    // 近未来の基本所得制度
    if (c.era == Era.future && c.age >= 25) {
      income['不労所得'] = (income['不労所得'] ?? 0) + 50000;
    }

    return income;
  }

  /// 年金額（時代別＋過去収入実績ベース、簡易版）
  int _pensionAmount(Character c) {
    final base = switch (c.era) {
      Era.showa => 80000,
      Era.heisei => 130000,
      Era.reiwa => 150000,
      Era.future => 180000,
    };
    return base;
  }

  /// 月次支出の内訳（GDD §9.2）
  Map<String, int> _computeExpense(Character c) {
    final priceIndex = _eraPriceIndex(c.era, c.yearIndex);
    final base = (c.household.monthlyIncome * 0.8).round();
    final expense = <String, int>{
      '住居': (base * 0.25).round(),
      '食費': (base * 0.15).round(),
      '交通': (base * 0.05).round(),
      '通信': (base * 0.05).round(),
      '娯楽': (base * 0.10).round(),
      '交際': (base * 0.05).round(),
      '保険': (base * 0.05).round(),
      'その他': (base * 0.10).round(),
    };

    // 子供の教育費・養育費（GDD §9.2.4）
    final children = (c.flags['children'] as int?) ?? 0;
    if (children > 0) {
      expense['その他'] = (expense['その他'] ?? 0) + children * 30000;
    }

    // 結婚で住居・食費が増加
    final married = (c.flags['married'] as bool?) ?? false;
    if (married) {
      expense['住居'] = ((expense['住居'] ?? 0) * 1.3).round();
      expense['食費'] = ((expense['食費'] ?? 0) * 1.5).round();
    }

    // ローン返済（GDD §9.6.3）
    int loanPayment = 0;
    for (final loan in c.household.loans) {
      loanPayment += ((loan['monthly_payment'] as num?) ?? 0).toInt();
    }
    if (loanPayment > 0) {
      expense['住居'] = (expense['住居'] ?? 0) + loanPayment;
    }

    // 物価指数で調整（時代を跨がないので軽い影響）
    final adjusted = expense.map((k, v) =>
        MapEntry(k, (v * priceIndex / _eraPriceIndex(c.era, 0)).round()));
    return adjusted;
  }

  /// 時代×年代の物価指数（GDD §7.3.1）
  double _eraPriceIndex(Era era, int yearIndex) {
    final start = switch (era) {
      Era.showa => 1.0,
      Era.heisei => 11.0,
      Era.reiwa => 15.0,
      Era.future => 20.0,
    };
    final end = switch (era) {
      Era.showa => 12.0,
      Era.heisei => 16.0,
      Era.reiwa => 22.0,
      Era.future => 35.0,
    };
    final progress = (yearIndex / 80).clamp(0.0, 1.0);
    return start + (end - start) * progress;
  }

  /// 投資の月次リターン抽選（正規分布乱数）
  Map<String, int> _computeInvestmentReturns(Character c) {
    final returns = <String, int>{};
    final products = InvestmentProduct.defaults(c);
    for (final p in products) {
      final invested = c.household.investments[p.id] ?? 0;
      if (invested == 0) continue;
      final rate = _normalRandom(p.expectedMonthlyReturn, p.stddev);
      returns[p.id] = (invested * rate).round();
    }
    return returns;
  }

  /// 正規分布乱数（Box-Muller法）
  double _normalRandom(double mean, double stddev) {
    if (stddev == 0) return mean;
    final u1 = math.max(_random.nextDouble(), 1e-9);
    final u2 = _random.nextDouble();
    final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    return mean + z * stddev;
  }

  /// 破産発火条件（GDD §9.6.4）：必須固定費未払い 2ヶ月連続
  bool _bankruptcyCondition(Character c, int income, int expense) {
    final fixedCost = expense * 0.4; // 必須固定費は支出の約4割と仮定
    final missed = (c.flags['fixed_cost_missed_months'] as int?) ?? 0;
    if (income < fixedCost) {
      return missed >= 1; // 今月で2ヶ月目
    }
    return false;
  }

  /// 住宅ローンの月次返済額計算（GDD §9.6.3）
  /// 元利均等返済の式
  static int monthlyMortgagePayment({
    required int principal,
    required double annualRate,
    required int totalMonths,
  }) {
    final r = annualRate / 12;
    if (r <= 0) {
      return (principal / totalMonths).round();
    }
    final pow = math.pow(1 + r, totalMonths);
    return (principal * r * pow / (pow - 1)).round();
  }
}
