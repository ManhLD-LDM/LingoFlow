import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';

class WordDefinition {
  final String word;
  final String reading; // Romaji, Pinyin, or Furigana
  final String definition;
  final List<String> examples;

  const WordDefinition({
    required this.word,
    required this.reading,
    required this.definition,
    this.examples = const [],
  });
}

class DictionaryService {
  final Dio _dio;
  static const String _tag = 'DictionaryService';

  DictionaryService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  /// Look up a word's meaning and pronunciation
  Future<WordDefinition> lookupWord({
    required String word,
    required String sourceLang,
    required String targetLang,
  }) async {
    final cleanWord = word.trim();
    if (cleanWord.isEmpty) {
      return const WordDefinition(word: '', reading: '', definition: '');
    }

    try {
      // Use Google Dictionary/Translation detailed endpoint
      final response = await _dio.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': sourceLang,
          'tl': targetLang,
          'dt': ['t', 'bd', 'rm'], // t=translation, bd=dictionary, rm=transliteration
          'q': cleanWord,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        String reading = '';
        String definition = '';

        // Extract translation text
        if (response.data[0] != null && response.data[0] is List) {
          final transList = response.data[0] as List;
          final buf = StringBuffer();
          for (var item in transList) {
            if (item != null && item[0] != null) {
              buf.write(item[0]);
            }
            if (item != null && item.length > 3 && item[3] != null) {
              reading = item[3].toString(); // Romaji/Pinyin transliteration
            } else if (item != null && item.length > 2 && item[2] != null) {
              reading = item[2].toString();
            }
          }
          definition = buf.toString();
        }

        // Extract dictionary pos entries if available
        final examples = <String>[];
        if (response.data.length > 1 && response.data[1] != null && response.data[1] is List) {
          final dictList = response.data[1] as List;
          for (var entry in dictList) {
            if (entry != null && entry is List && entry.length >= 2) {
              final pos = entry[0]?.toString() ?? '';
              final terms = (entry[1] as List?)?.map((e) => e.toString()).take(3).join(', ') ?? '';
              if (pos.isNotEmpty && terms.isNotEmpty) {
                examples.add('[$pos] $terms');
              }
            }
          }
        }

        return WordDefinition(
          word: cleanWord,
          reading: reading,
          definition: definition,
          examples: examples,
        );
      }
    } catch (e, stack) {
      AppLogger.warning('Dictionary lookup failed for "$cleanWord"', tag: _tag, error: e, stackTrace: stack);
    }

    return WordDefinition(
      word: cleanWord,
      reading: '',
      definition: cleanWord,
    );
  }
}
