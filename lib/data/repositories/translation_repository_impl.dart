import '../../domain/repositories/translation_repository.dart';
import '../datasources/remote/google_translate_api.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final GoogleTranslateApi _googleTranslateApi;
  final Map<String, String> _memoryCache = {};

  TranslationRepositoryImpl({GoogleTranslateApi? googleTranslateApi})
      : _googleTranslateApi = googleTranslateApi ?? GoogleTranslateApi();

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return '';

    final cacheKey = '${sourceLanguage ?? "auto"}_${targetLanguage}_$cleanText';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    final translated = await _googleTranslateApi.translate(
      text: cleanText,
      targetLang: targetLanguage,
      sourceLang: sourceLanguage ?? 'auto',
    );

    _memoryCache[cacheKey] = translated;
    return translated;
  }
}
