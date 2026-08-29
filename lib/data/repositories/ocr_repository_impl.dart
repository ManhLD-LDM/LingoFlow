import 'dart:typed_data';
import 'dart:ui';
import '../../core/services/native_overlay_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/bmp_encoder.dart';
import '../datasources/remote/cloud_ocr_api.dart';
import '../../domain/entities/ocr_result.dart';
import '../../domain/entities/ocr_engine_mode.dart';
import '../../domain/repositories/ocr_repository.dart';

class OcrRepositoryImpl implements OcrRepository {
  final CloudOcrApi _cloudOcrApi;
  static const String _tag = 'OcrRepositoryImpl';

  OcrRepositoryImpl({CloudOcrApi? cloudOcrApi})
      : _cloudOcrApi = cloudOcrApi ?? CloudOcrApi();

  @override
  Future<OcrResult> recognizeFromRegion(
    Rect region, {
    String? languageHint,
    String? apiKey,
    OcrEngineMode mode = OcrEngineMode.autoFallback,
  }) async {
    // 1. If user explicitly wants offline only, go straight to native OCR
    if (mode == OcrEngineMode.offlineOnly) {
      return _recognizeNative(region, languageHint);
    }

    // 2. Capture screen pixels directly via Win32 GDI BitBlt
    final captureData = await NativeOverlayService.captureScreen(
      x: region.left.toInt(),
      y: region.top.toInt(),
      width: region.width.toInt(),
      height: region.height.toInt(),
    );

    if (captureData != null) {
      final width = (captureData['width'] as num?)?.toInt() ?? 0;
      final height = (captureData['height'] as num?)?.toInt() ?? 0;
      final rawList = captureData['bytes'] as List<dynamic>?;

      if (rawList != null && rawList.isNotEmpty && width > 0 && height > 0) {
        final rawBytes = Uint8List.fromList(rawList.cast<int>());
        final bmpBytes = BmpEncoder.encodeBgra(rawBytes, width, height);

        // Run multi-language Cloud OCR
        final result = await _cloudOcrApi.recognizeImage(
          bmpBytes,
          language: languageHint,
          apiKey: apiKey,
        );

        if (result.fullText.isNotEmpty) {
          AppLogger.debug('Cloud OCR recognized ${result.blocks.length} blocks', tag: _tag);
          return result;
        }
      }
    }

    // 3. Fallback to Native OCR if mode allows auto fallback
    if (mode == OcrEngineMode.autoFallback) {
      AppLogger.info('Cloud OCR returned empty, falling back to Native OCR', tag: _tag);
      return _recognizeNative(region, languageHint);
    }

    return OcrResult.empty;
  }

  Future<OcrResult> _recognizeNative(Rect region, String? languageHint) async {
    final nativeResult = await NativeOverlayService.recognizeText(
      x: region.left.toInt(),
      y: region.top.toInt(),
      width: region.width.toInt(),
      height: region.height.toInt(),
      language: languageHint,
    );

    if (nativeResult != null) {
      final fullText = (nativeResult['fullText'] as String?) ?? '';
      if (fullText.trim().isNotEmpty) {
        return OcrResult(
          fullText: fullText.trim(),
          blocks: [OcrBlock(text: fullText.trim(), boundingBox: region)],
          imageWidth: region.width.toInt(),
          imageHeight: region.height.toInt(),
        );
      }
    }
    return OcrResult.empty;
  }

  @override
  Future<OcrResult> recognizeFromBytes(
    List<int> bytes,
    int width,
    int height, {
    String? languageHint,
    String? apiKey,
    OcrEngineMode mode = OcrEngineMode.autoFallback,
  }) async {
    final rawBytes = Uint8List.fromList(bytes);
    final bmpBytes = BmpEncoder.encodeBgra(rawBytes, width, height);
    return _cloudOcrApi.recognizeImage(bmpBytes, language: languageHint, apiKey: apiKey);
  }
}
