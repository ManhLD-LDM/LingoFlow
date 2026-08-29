import '../../domain/entities/translation_engine.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/remote/google_translate_api.dart';
import '../datasources/remote/deep_l_api.dart';
import '../../core/utils/text_processor.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final GoogleTranslateApi _googleTranslateApi;
  final DeepLApi _deepLApi;

  /// LRU-style memory cache with a maximum size to prevent unbounded growth
  static const int _maxCacheSize = 200;
  final Map<String, String> _memoryCache = {};
  final List<String> _cacheOrder = [];

  TranslationRepositoryImpl({
    GoogleTranslateApi? googleTranslateApi,
    DeepLApi? deepLApi,
  })  : _googleTranslateApi = googleTranslateApi ?? GoogleTranslateApi(),
        _deepLApi = deepLApi ?? DeepLApi();

  void _putCache(String key, String value) {
    if (_memoryCache.containsKey(key)) {
      // Move to end (most recently used)
      _cacheOrder.remove(key);
      _cacheOrder.add(key);
      _memoryCache[key] = value;
    } else {
      // Evict oldest entry if at capacity
      if (_cacheOrder.length >= _maxCacheSize) {
        final evictKey = _cacheOrder.removeAt(0);
        _memoryCache.remove(evictKey);
      }
      _cacheOrder.add(key);
      _memoryCache[key] = value;
    }
  }

  @override
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    TranslationEngine engine = TranslationEngine.google,
    String? apiKey,
    Map<String, String>? glossary,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return '';

    final cacheKey = '${engine.id}_${sourceLanguage ?? "auto"}_${targetLanguage}_$cleanText';
    if (_memoryCache.containsKey(cacheKey)) {
      // Move to end on access (LRU touch)
      _cacheOrder.remove(cacheKey);
      _cacheOrder.add(cacheKey);
      final cached = _memoryCache[cacheKey]!;
      return glossary != null ? TextProcessor.applyGlossary(cached, glossary) : cached;
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

    _putCache(cacheKey, translated);
    return glossary != null ? TextProcessor.applyGlossary(translated, glossary) : translated;
  }
}
