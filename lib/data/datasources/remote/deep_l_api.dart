import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_logger.dart';

class DeepLApi {
  final Dio _dio;
  static const String _tag = 'DeepLApi';

  DeepLApi({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<String> translate({
    required String text,
    required String targetLang,
    required String apiKey,
    String? sourceLang,
  }) async {
    if (text.trim().isEmpty) return '';
    if (apiKey.trim().isEmpty) {
      throw Exception('DeepL API Key is missing. Please configure it in Settings.');
    }

    final isFreeApi = apiKey.endsWith(':fx');
    final baseUrl = isFreeApi
        ? 'https://api-free.deepl.com/v2/translate'
        : 'https://api.deepl.com/v2/translate';

    // Map language codes to DeepL format (uppercase)
    var dTargetLang = targetLang.toUpperCase();
    if (dTargetLang == 'EN') dTargetLang = 'EN-US';

    try {
      final response = await _dio.post(
        baseUrl,
        data: {
          'text': [text],
          'target_lang': dTargetLang,
          if (sourceLang != null && sourceLang != 'auto')
            'source_lang': sourceLang.toUpperCase(),
        },
        options: Options(
          headers: {
            'Authorization': 'DeepL-Auth-Key $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final translations = response.data['translations'] as List<dynamic>?;
        if (translations != null && translations.isNotEmpty) {
          final translated = (translations[0]['text'] as String?) ?? text;
          AppLogger.debug('DeepL translated: "$text" -> "$translated"', tag: _tag);
          return translated;
        }
      }
      return text;
    } catch (e, stack) {
      AppLogger.error('DeepL translation error', tag: _tag, error: e, stackTrace: stack);
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 403) {
          throw Exception('DeepL API Key không hợp lệ hoặc đã hết hạn (Error 403).');
        } else if (status == 456) {
          throw Exception('DeepL API Key đã hết hạn mức ký tự dịch trong tháng (Quota Exceeded).');
        }
      }
      rethrow;
    }
  }

  /// Tests if a DeepL API key is valid
  Future<bool> validateKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    final isFreeApi = apiKey.endsWith(':fx');
    final baseUrl = isFreeApi
        ? 'https://api-free.deepl.com/v2/usage'
        : 'https://api.deepl.com/v2/usage';

    try {
      final response = await _dio.get(
        baseUrl,
        options: Options(
          headers: {'Authorization': 'DeepL-Auth-Key $apiKey'},
        ),
      );
      final isValid = response.statusCode == 200;
      AppLogger.info('DeepL key validation result: $isValid', tag: _tag);
      return isValid;
    } catch (e, stack) {
      AppLogger.warning('DeepL key validation failed', tag: _tag, error: e, stackTrace: stack);
      return false;
    }
  }
}
