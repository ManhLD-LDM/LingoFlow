import 'dart:ui';
import '../../core/services/native_overlay_service.dart';
import '../../domain/entities/ocr_result.dart';
import '../../domain/repositories/ocr_repository.dart';

class OcrRepositoryImpl implements OcrRepository {
  @override
  Future<OcrResult> recognizeFromRegion(Rect region, {String? languageHint}) async {
    final nativeResult = await NativeOverlayService.recognizeText(
      x: region.left.toInt(),
      y: region.top.toInt(),
      width: region.width.toInt(),
      height: region.height.toInt(),
      language: languageHint,
    );

    if (nativeResult == null) {
      return OcrResult.empty;
    }

    final fullText = (nativeResult['fullText'] as String?) ?? '';
    final rawBlocks = nativeResult['blocks'] as List<dynamic>? ?? [];

    final blocks = <OcrBlock>[];
    for (var rawBlock in rawBlocks) {
      if (rawBlock is Map) {
        final text = (rawBlock['text'] as String?) ?? '';
        final x = ((rawBlock['x'] ?? 0) as num).toDouble();
        final y = ((rawBlock['y'] ?? 0) as num).toDouble();
        final w = ((rawBlock['width'] ?? 100) as num).toDouble();
        final h = ((rawBlock['height'] ?? 30) as num).toDouble();

        blocks.add(
          OcrBlock(
            text: text,
            boundingBox: Rect.fromLTWH(x, y, w, h),
          ),
        );
      }
    }

    // If native OCR returned full text but didn't segment blocks, create 1 block spanning the region
    if (blocks.isEmpty && fullText.trim().isNotEmpty) {
      blocks.add(
        OcrBlock(
          text: fullText.trim(),
          boundingBox: region,
        ),
      );
    }

    return OcrResult(
      fullText: fullText,
      blocks: blocks,
      imageWidth: region.width.toInt(),
      imageHeight: region.height.toInt(),
    );
  }

  @override
  Future<OcrResult> recognizeFromBytes(
    List<int> bytes,
    int width,
    int height, {
    String? languageHint,
  }) async {
    return OcrResult.empty;
  }
}
