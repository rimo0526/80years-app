// ============================================================
// 家系モデル / GDD §18.3.3 family ブロック準拠
// 最新10世代まで詳細保存（GDD §11.5.7）
// ============================================================
import '../../core/constants/enums.dart';

/// 家系メンバー1人（過去キャラ）
class FamilyMember {
  final int generation;
  final String id;
  final String name;
  final Gender gender;
  final Era era;
  final int birthYearIndex; // 何代目の何年目スタートか（基本0）
  final int deathAge;
  final String endingId;    // GDD §11.2.1 の14種ID
  final Map<String, int> peakStats;
  final int finalAssets;
  final List<String> giftsUnlocked;
  final String? tombImageRef;

  const FamilyMember({
    required this.generation,
    required this.id,
    required this.name,
    required this.gender,
    required this.era,
    this.birthYearIndex = 0,
    this.deathAge = 0,
    this.endingId = '',
    this.peakStats = const {},
    this.finalAssets = 0,
    this.giftsUnlocked = const [],
    this.tombImageRef,
  });

  Map<String, dynamic> toJson() => {
        'generation': generation,
        'id': id,
        'name': name,
        'gender': gender.label,
        'era': era.label,
        'birth_year_index': birthYearIndex,
        'death_age': deathAge,
        'ending_id': endingId,
        'peak_stats': peakStats,
        'final_assets': finalAssets,
        'gifts_unlocked': giftsUnlocked,
        if (tombImageRef != null) 'tomb_image_ref': tombImageRef,
      };

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        generation: (j['generation'] ?? 0) as int,
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        gender: Gender.fromString(j['gender'] as String?) ?? Gender.male,
        era: Era.fromString((j['era'] ?? '令和') as String),
        birthYearIndex: (j['birth_year_index'] ?? 0) as int,
        deathAge: (j['death_age'] ?? 0) as int,
        endingId: (j['ending_id'] ?? '') as String,
        peakStats: (j['peak_stats'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            {},
        finalAssets: (j['final_assets'] ?? 0) as int,
        giftsUnlocked:
            (j['gifts_unlocked'] as List?)?.map((e) => e as String).toList() ??
                [],
        tombImageRef: j['tomb_image_ref'] as String?,
      );
}

/// 家系（GDD §18.3.3）
class Family {
  final List<FamilyMember> members;
  final List<Map<String, dynamic>> compressedOld; // 11世代以前の圧縮データ
  final Map<String, dynamic> inheritanceForCurrent; // 現キャラへの継承情報

  const Family({
    this.members = const [],
    this.compressedOld = const [],
    this.inheritanceForCurrent = const {},
  });

  Family copyWith({
    List<FamilyMember>? members,
    List<Map<String, dynamic>>? compressedOld,
    Map<String, dynamic>? inheritanceForCurrent,
  }) {
    return Family(
      members: members ?? this.members,
      compressedOld: compressedOld ?? this.compressedOld,
      inheritanceForCurrent:
          inheritanceForCurrent ?? this.inheritanceForCurrent,
    );
  }

  Map<String, dynamic> toJson() => {
        'members': members.map((e) => e.toJson()).toList(),
        'compressed_old': compressedOld,
        'inheritance_for_current': inheritanceForCurrent,
      };

  factory Family.fromJson(Map<String, dynamic> j) => Family(
        members: (j['members'] as List?)
                ?.map((e) =>
                    FamilyMember.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        compressedOld: (j['compressed_old'] as List?)
                ?.map((e) => (e as Map).cast<String, dynamic>())
                .toList() ??
            [],
        inheritanceForCurrent:
            (j['inheritance_for_current'] as Map?)?.cast<String, dynamic>() ??
                {},
      );
}
