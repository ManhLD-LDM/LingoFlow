import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/core/services/tts_service.dart';

void main() {
  group('TtsService Tests', () {
    test('getAudioStreamUrl generates valid encoded query parameter', () {
      const text = 'こんにちは世界';
      final url = TtsService.getAudioStreamUrl(text, language: 'ja');

      expect(url, contains('https://translate.google.com/translate_tts'));
      expect(url, contains('tl=ja'));
      expect(url, contains('client=tw-ob'));
      expect(url, contains(Uri.encodeComponent(text)));
    });

    test('getAudioStreamUrl defaults auto language to ja', () {
      final url = TtsService.getAudioStreamUrl('Hello', language: 'auto');
      expect(url, contains('tl=ja'));
    });

    test('getAudioStreamUrl returns empty string for blank input', () {
      expect(TtsService.getAudioStreamUrl(''), isEmpty);
      expect(TtsService.getAudioStreamUrl('   \n  '), isEmpty);
    });

    test('speak returns false for empty string', () async {
      final result = await TtsService.speak('');
      expect(result, isFalse);
    });
  });
}
