import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_logger.dart';

class GoogleTranslateApi {
  final Dio _dio;
  static const String _tag = 'GoogleTranslateApi';

  GoogleTranslateApi({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return '';

    try {
      final response = await _dio.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': sourceLang,
          'tl': targetLang,
          'dt': 't',
          'q': clean,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List dynamicList = response.data[0];
        final buffer = StringBuffer();
        for (var item in dynamicList) {
          if (item != null && item[0] != null) {
            buffer.write(item[0]);
          }
        }
        final translated = buffer.toString();
        AppLogger.debug('Google translated: "$clean" -> "$translated"', tag: _tag);
        return translated;
      }
      return clean;
    } catch (e, stack) {
      AppLogger.error('Google translation request failed', tag: _tag, error: e, stackTrace: stack);
      return '[Error: $e] $clean';
    }
  }
}
