import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/core/utils/text_processor.dart';

void main() {
  group('TextProcessor Tests', () {
    test('cleans and merges CJK characters across spaces and newlines', () {
      const input = 'こん にちは\n世界';
      final result = TextProcessor.cleanOcrText(input, language: 'ja');
      expect(result, equals('こんにちは世界'));
    });

    test('cleans Japanese dialogue quotation marks properly', () {
      const input = '「  俺は海賊王になる男だ！  」';
      final result = TextProcessor.cleanOcrText(input, language: 'ja');
      expect(result, equals('「俺は海賊王になる男だ！」'));
    });

    test('removes OCR noise artifacts like pipes, underscores, and tildes', () {
      const input = '| これは_テスト~です `';
      final result = TextProcessor.cleanOcrText(input, language: 'ja');
      expect(result, equals('これは テスト です'));
    });

    test('dehyphenates broken English words across lines', () {
      const input = 'This is a trans-\nlation test for multi-\nline text.';
      final result = TextProcessor.cleanOcrText(input, language: 'en');
      expect(result, equals('This is a translation test for multiline text.'));
    });

    test('replaces soft linebreaks in Western text with spaces', () {
      const input = 'First line\nsecond line\nthird line.';
      final result = TextProcessor.cleanOcrText(input, language: 'en');
      expect(result, equals('First line second line third line.'));
    });

    test('handles empty or whitespace-only inputs gracefully', () {
      expect(TextProcessor.cleanOcrText(''), equals(''));
      expect(TextProcessor.cleanOcrText('   \n\t  '), equals(''));
    });
  });
}
