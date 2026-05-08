// ============================================================
// セーブリポジトリ最小ユニットテスト（GDD §20.1 ユニットテスト）
//
// 実行：flutter test test/save_repository_test.dart
//
// このテストは Codec のラウンドトリップ（encode→decode）が
// 一致することを検証する。Web/Mobile 実装は I/O を伴うため
// 別途 integration_test で検証。
// ============================================================
import 'package:capitalism_game/core/constants/enums.dart';
import 'package:capitalism_game/domain/models/character.dart';
import 'package:capitalism_game/domain/models/game_save_data.dart';
import 'package:capitalism_game/domain/services/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveCodec', () {
    test('plain export/import round-trip', () {
      final original = GameSaveData(
        savedAt: '2026-05-07T12:00:00+09:00',
        character: Character(
          id: 'test_001',
          name: '田中 太郎',
          gender: Gender.male,
          strength: AbilityKind.brain,
          avatar: const Avatar(),
          parent: const ParentInfo(),
          era: Era.reiwa,
          age: 30,
          stats: const Stats(brain: 75, body: 50, social: 60, sense: 40, luck: 30),
        ),
      );

      final exported = SaveCodec.exportPlain(original);
      final imported = SaveCodec.importPlain(exported);

      expect(imported, isNotNull);
      expect(imported!.character?.name, equals('田中 太郎'));
      expect(imported.character?.age, equals(30));
      expect(imported.character?.era, equals(Era.reiwa));
      expect(imported.character?.stats.brain, equals(75));
    });

    test('encoded round-trip with checksum', () {
      final original = GameSaveData(
        savedAt: '2026-05-07T12:00:00+09:00',
        character: Character(
          id: 'test_002',
          name: '山田 花子',
          gender: Gender.female,
          strength: AbilityKind.social,
          avatar: const Avatar(),
          parent: const ParentInfo(),
          era: Era.showa,
          age: 50,
        ),
      );

      final encoded = SaveCodec.encode(original);
      final decoded = SaveCodec.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.character?.name, equals('山田 花子'));
      expect(decoded.character?.era, equals(Era.showa));
      expect(decoded.checksum, isNotNull);
    });

    test('decode returns null on tampered data', () {
      final original = GameSaveData(savedAt: '2026-05-07T12:00:00+09:00');
      final encoded = SaveCodec.encode(original);
      // 改ざん：途中の文字を反転させる
      final pos = encoded.length ~/ 2;
      final tampered = encoded.substring(0, pos) + 'X' + encoded.substring(pos + 1);
      expect(SaveCodec.decode(tampered), isNull);
    });

    test('schema migration is no-op for current version', () {
      final json = <String, dynamic>{
        'schema_version': 1,
        'saved_at': '2026-05-07T12:00:00+09:00',
        'family': {
          'members': [],
          'compressed_old': [],
          'inheritance_for_current': {},
        },
        'achievements': {
          'unlocked': [],
          'tomb_decorations_unlocked': [],
          'hidden_strengths_unlocked': [],
          'hidden_eras_unlocked': [],
        },
        'settings': {},
        'statistics': {},
      };
      final migrated = migrate(json);
      expect(migrated['schema_version'], equals(1));
    });
  });
}
