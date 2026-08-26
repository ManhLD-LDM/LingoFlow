import '../../domain/entities/translation_engine.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/remote/google_translate_api.dart';
import '../datasources/remote/deep_l_api.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final GoogleTranslateApi _googleTranslateApi;
  final DeepLApi _deepLApi;
  final Map<String, String> _memoryCache = {};

  TranslationRepositoryImpl({
    GoogleTranslateApi? googleTranslateApi,
    DeepLApi? deepLApi,
  })  : _googleTranslateApi = googleTranslateApi ?? GoogleTranslateApi(),
        _deepLApi = deepLApi ?? DeepLApi();

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    TranslationEngine engine = TranslationEngine.google,
    String? apiKey,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return '';

    final cacheKey = '${engine.id}_${sourceLanguage ?? "auto"}_${targetLanguage}_$cleanText';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    String translated;
    if (engine == TranslationEngine.deepl && apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        translated = await _deepLApi.translate(
          text: cleanText,
          targetLang: targetLanguage,
          sourceLang: sourceLanguage,
          apiKey: apiKey,
        );
      } catch (_) {
        // Fallback to Google if DeepL fails (e.g. quota exceeded)
        translated = await _googleTranslateApi.translate(
          text: cleanText,
          targetLang: targetLanguage,
          sourceLang: sourceLanguage ?? 'auto',
        );
      }
    } else {
      translated = await _googleTranslateApi.translate(
        text: cleanText,
        targetLang: targetLanguage,
        sourceLang: sourceLanguage ?? 'auto',
      );
    }

    _memoryCache[cacheKey] = translated;
    return translated;
  }
}
