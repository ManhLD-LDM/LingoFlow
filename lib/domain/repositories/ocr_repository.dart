import 'dart:ui';
import '../entities/ocr_result.dart';
import '../entities/ocr_engine_mode.dart';

abstract class OcrRepository {
  /// Recognize text within a specific rectangular region on the screen
  Future<OcrResult> recognizeFromRegion(
    Rect region, {
    String? languageHint,
    String? apiKey,
    OcrEngineMode mode = OcrEngineMode.autoFallback,
  });

  /// Recognize text from raw RGBA/BGRA bytes
  Future<OcrResult> recognizeFromBytes(
    List<int> bytes,
    int width,
    int height, {
    String? languageHint,
    String? apiKey,
    OcrEngineMode mode = OcrEngineMode.autoFallback,
  });
}
