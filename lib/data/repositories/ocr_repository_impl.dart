import 'dart:typed_data';
import 'dart:ui';
import '../../core/services/native_overlay_service.dart';
import '../../core/utils/bmp_encoder.dart';
import '../datasources/remote/cloud_ocr_api.dart';
import '../../domain/entities/ocr_result.dart';
import '../../domain/repositories/ocr_repository.dart';

class OcrRepositoryImpl implements OcrRepository {
  final CloudOcrApi _cloudOcrApi;

  OcrRepositoryImpl({CloudOcrApi? cloudOcrApi})
      : _cloudOcrApi = cloudOcrApi ?? CloudOcrApi();

  @override
  Future<OcrResult> recognizeFromRegion(Rect region, {String? languageHint}) async {
    // 1. Capture screen pixels directly via Win32 GDI BitBlt
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

        // Run multi-language OCR on captured screen bitmap
        final result = await _cloudOcrApi.recognizeImage(
          bmpBytes,
          language: languageHint,
        );

        if (result.fullText.isNotEmpty) {
          return result;
        }
      }
    }

    // 2. Fallback to Native OCR if present
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
  }) async {
    final rawBytes = Uint8List.fromList(bytes);
    final bmpBytes = BmpEncoder.encodeBgra(rawBytes, width, height);
    return _cloudOcrApi.recognizeImage(bmpBytes, language: languageHint);
  }
}
