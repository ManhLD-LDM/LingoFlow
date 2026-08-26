import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class GoogleTranslateApi {
  final Dio _dio;

  GoogleTranslateApi({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    if (text.trim().isEmpty) return '';

    try {
      final response = await _dio.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': sourceLang,
          'tl': targetLang,
          'dt': 't',
          'q': text,
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
        return buffer.toString();
      }
      return text;
    } catch (e) {
      // Return original text on network error
      return '[Error: $e] $text';
    }
  }
}
