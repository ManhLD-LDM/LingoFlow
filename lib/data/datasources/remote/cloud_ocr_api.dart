import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/ocr_result.dart';

class CloudOcrApi {
  final Dio _dio;
  static const String _tag = 'CloudOcrApi';

  CloudOcrApi({Dio? dio}) : _dio = dio ?? DioClient.instance;

  /// Resolves the OCR API key from: explicit parameter > .env > empty (will fail gracefully)
  static String _resolveApiKey({String? explicitKey}) {
    if (explicitKey != null && explicitKey.trim().isNotEmpty) {
      return explicitKey.trim();
    }
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['OCR_API_KEY'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  static String _mapLanguageCode(String? lang) {
    final code = lang?.toLowerCase() ?? 'ja';
    switch (code) {
      case 'ja':
      case 'jp':
        return 'jpn';
      case 'zh':
      case 'cn':
        return 'chs';
      case 'ko':
      case 'kr':
        return 'kor';
      case 'en':
        return 'eng';
      case 'vi':
        return 'vie';
      default:
        return 'jpn';
    }
  }

  /// Sends a BMP image to OCR.space API and parses recognized lines and bounding boxes
  Future<OcrResult> recognizeImage(
    Uint8List bmpBytes, {
    String? language,
    String? apiKey,
  }) async {
    final resolvedKey = _resolveApiKey(explicitKey: apiKey);
    if (resolvedKey.isEmpty) {
      AppLogger.warning('OCR API key is missing. Skipping cloud OCR request.', tag: _tag);
      return OcrResult.empty;
    }

    try {
      final base64Image = 'data:image/bmp;base64,${base64Encode(bmpBytes)}';
      final ocrLang = _mapLanguageCode(language);

      final formData = FormData.fromMap({
        'base64Image': base64Image,
        'language': ocrLang,
        'isOverlayRequired': 'true',
        'OCREngine': '2', // OCR Engine 2 is optimized for Japanese, Chinese & Asian characters
        'scale': 'true',
        'isTable': 'false',
      });

      final response = await _dio.post(
        'https://api.ocr.space/parse/image',
        data: formData,
        options: Options(
          headers: {
            'apikey': resolvedKey,
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final parsedResults = data['ParsedResults'] as List<dynamic>?;

        if (parsedResults != null && parsedResults.isNotEmpty) {
          final firstResult = parsedResults[0];
          final parsedText = (firstResult['ParsedText'] as String?)?.trim() ?? '';

          final blocks = <OcrBlock>[];
          final textOverlay = firstResult['TextOverlay'] as Map<String, dynamic>?;
          final lines = textOverlay?['Lines'] as List<dynamic>?;

          if (lines != null) {
            for (var line in lines) {
              final lineText = (line['LineText'] as String?)?.trim() ?? '';
              if (lineText.isEmpty) continue;

              final words = line['Words'] as List<dynamic>?;
              double minL = double.infinity, minT = double.infinity;
              double maxR = 0, maxB = 0;

              if (words != null && words.isNotEmpty) {
                for (var w in words) {
                  final left = (w['Left'] as num?)?.toDouble() ?? 0;
                  final top = (w['Top'] as num?)?.toDouble() ?? 0;
                  final width = (w['Width'] as num?)?.toDouble() ?? 0;
                  final height = (w['Height'] as num?)?.toDouble() ?? 0;

                  if (left < minL) minL = left;
                  if (top < minT) minT = top;
                  if (left + width > maxR) maxR = left + width;
                  if (top + height > maxB) maxB = top + height;
                }
              }

              final rect = (minL != double.infinity && maxR > minL)
                  ? Rect.fromLTRB(minL, minT, maxR, maxB)
                  : const Rect.fromLTWH(0, 0, 100, 30);

              blocks.add(OcrBlock(text: lineText, boundingBox: rect));
            }
          }

          AppLogger.debug('Cloud OCR success: ${parsedText.length} chars found', tag: _tag);
          return OcrResult(
            fullText: parsedText,
            blocks: blocks,
            imageWidth: 0,
            imageHeight: 0,
          );
        }
      }
      return OcrResult.empty;
    } catch (e, stack) {
      AppLogger.error('Cloud OCR recognition error', tag: _tag, error: e, stackTrace: stack);
      return OcrResult.empty;
    }
  }
}
