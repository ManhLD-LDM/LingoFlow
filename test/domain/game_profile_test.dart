import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/domain/entities/game_profile.dart';

void main() {
  group('GameProfile Tests', () {
    test('toJson and fromJson roundtrip correctly', () {
      const profile = GameProfile(
        id: 'genshin_01',
        name: 'Genshin Impact',
        sourceLanguage: 'ja',
        targetLanguage: 'vi',
        translationEngineId: 'deepl',
        subtitleThemeId: 'manga_white',
        lensX: 200,
        lensY: 300,
        lensWidth: 600,
        lensHeight: 250,
        glossary: {
          '原神': 'Genshin Impact',
          '旅人': 'Nhà Lữ Hành (Traveler)',
        },
      );

      final json = profile.toJson();
      final restored = GameProfile.fromJson(json);

      expect(restored.id, equals('genshin_01'));
      expect(restored.name, equals('Genshin Impact'));
      expect(restored.sourceLanguage, equals('ja'));
      expect(restored.targetLanguage, equals('vi'));
      expect(restored.translationEngineId, equals('deepl'));
      expect(restored.subtitleThemeId, equals('manga_white'));
      expect(restored.lensX, equals(200));
      expect(restored.lensY, equals(300));
      expect(restored.lensWidth, equals(600));
      expect(restored.lensHeight, equals(250));
      expect(restored.glossary['原神'], equals('Genshin Impact'));
      expect(restored.glossary['旅人'], equals('Nhà Lữ Hành (Traveler)'));
    });

    test('copyWith updates specific attributes without mutating existing', () {
      const original = GameProfile.defaultProfile;
      final modified = original.copyWith(
        name: 'Updated Name',
        sourceLanguage: 'zh',
        glossary: {'HP': 'Máu'},
      );

      expect(modified.id, equals(original.id));
      expect(modified.name, equals('Updated Name'));
      expect(modified.sourceLanguage, equals('zh'));
      expect(modified.glossary['HP'], equals('Máu'));
      expect(original.name, equals('Game / Manga Mặc định'));
    });
  });
}
