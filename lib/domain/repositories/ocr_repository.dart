import 'dart:ui';
import '../entities/ocr_result.dart';

abstract class OcrRepository {
  /// Recognize text within a specific rectangular region on the screen
  Future<OcrResult> recognizeFromRegion(Rect region, {String? languageHint, String? apiKey});

  /// Recognize text from raw RGBA/BGRA bytes
  Future<OcrResult> recognizeFromBytes(
    List<int> bytes,
    int width,
    int height, {
    String? languageHint,
    String? apiKey,
  });
}
