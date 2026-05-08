// ============================================================
// 累計統計 / GDD §18.3.6 statistics ブロック準拠
// ============================================================

class StatisticsData {
  final int totalPlayTimeSeconds;
  final int totalGenerations;
  final List<String> endingsAchieved;
  final int longestLifespan;
  final int shortestLifespan;
  final int maxAssetsEver;
  final int bankruptcies;
  final int skillUnlocksLifetime;
  final int giftUnlocksLifetime;
  final int sharesCount;

  const StatisticsData({
    this.totalPlayTimeSeconds = 0,
    this.totalGenerations = 0,
    this.endingsAchieved = const [],
    this.longestLifespan = 0,
    this.shortestLifespan = 0,
    this.maxAssetsEver = 0,
    this.bankruptcies = 0,
    this.skillUnlocksLifetime = 0,
    this.giftUnlocksLifetime = 0,
    this.sharesCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'total_play_time_seconds': totalPlayTimeSeconds,
        'total_generations': totalGenerations,
        'endings_achieved': endingsAchieved,
        'longest_lifespan': longestLifespan,
        'shortest_lifespan': shortestLifespan,
        'max_assets_ever': maxAssetsEver,
        'bankruptcies': bankruptcies,
        'skill_unlocks_lifetime': skillUnlocksLifetime,
        'gift_unlocks_lifetime': giftUnlocksLifetime,
        'shares_count': sharesCount,
      };

  factory StatisticsData.fromJson(Map<String, dynamic> j) => StatisticsData(
        totalPlayTimeSeconds: (j['total_play_time_seconds'] ?? 0) as int,
        totalGenerations: (j['total_generations'] ?? 0) as int,
        endingsAchieved:
            (j['endings_achieved'] as List?)?.map((e) => e as String).toList() ??
                [],
        longestLifespan: (j['longest_lifespan'] ?? 0) as int,
        shortestLifespan: (j['shortest_lifespan'] ?? 0) as int,
        maxAssetsEver: (j['max_assets_ever'] ?? 0) as int,
        bankruptcies: (j['bankruptcies'] ?? 0) as int,
        skillUnlocksLifetime: (j['skill_unlocks_lifetime'] ?? 0) as int,
        giftUnlocksLifetime: (j['gift_unlocks_lifetime'] ?? 0) as int,
        sharesCount: (j['shares_count'] ?? 0) as int,
      );
}
