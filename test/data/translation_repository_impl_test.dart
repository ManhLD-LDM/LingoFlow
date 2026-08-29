import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/data/datasources/remote/google_translate_api.dart';
import 'package:lingo_flow/data/datasources/remote/deep_l_api.dart';
import 'package:lingo_flow/data/repositories/translation_repository_impl.dart';
import 'package:lingo_flow/domain/entities/translation_engine.dart';

class FakeGoogleTranslateApi extends GoogleTranslateApi {
  int callCount = 0;
  final String fakeResult;

  FakeGoogleTranslateApi({this.fakeResult = 'Bản dịch mẫu'});

  @override
  Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    callCount++;
    return '$fakeResult: $text';
  }
}

class FakeDeepLApi extends DeepLApi {
  int callCount = 0;
  bool shouldThrow = false;

  @override
  Future<String> translate({
    required String text,
    required String targetLang,
    required String apiKey,
    String? sourceLang,
  }) async {
    callCount++;
    if (shouldThrow) {
      throw Exception('DeepL quota exceeded');
    }
    return 'DeepL($text)';
  }
}

void main() {
  group('TranslationRepositoryImpl Tests', () {
    test('returns empty string for empty text without calling API', () async {
      final fakeGoogle = FakeGoogleTranslateApi();
      final repo = TranslationRepositoryImpl(googleTranslateApi: fakeGoogle);

      final result = await repo.translate(
        text: '   ',
        targetLanguage: 'vi',
      );

      expect(result, isEmpty);
      expect(fakeGoogle.callCount, equals(0));
    });

    test('caches translation results in memory and skips API on identical calls', () async {
      final fakeGoogle = FakeGoogleTranslateApi();
      final repo = TranslationRepositoryImpl(googleTranslateApi: fakeGoogle);

      final first = await repo.translate(
        text: 'Hello',
        targetLanguage: 'vi',
      );
      expect(fakeGoogle.callCount, equals(1));
      expect(first, equals('Bản dịch mẫu: Hello'));

      // Second identical call must be served from LRU cache
      final second = await repo.translate(
        text: 'Hello',
        targetLanguage: 'vi',
      );
      expect(fakeGoogle.callCount, equals(1));
      expect(second, equals(first));
    });

    test('routes to DeepL when configured and falls back to Google if DeepL fails', () async {
      final fakeGoogle = FakeGoogleTranslateApi();
      final fakeDeepL = FakeDeepLApi()..shouldThrow = true;
      final repo = TranslationRepositoryImpl(
        googleTranslateApi: fakeGoogle,
        deepLApi: fakeDeepL,
      );

      final result = await repo.translate(
        text: 'Fallback test',
        targetLanguage: 'vi',
        engine: TranslationEngine.deepl,
        apiKey: 'test-key-123',
      );

      expect(fakeDeepL.callCount, equals(1));
      expect(fakeGoogle.callCount, equals(1));
      expect(result, contains('Bản dịch mẫu: Fallback test'));
    });
  });
}
