import 'dart:ui';

/// Represents a single line or block of recognized text with its coordinates
class OcrLine {
  final String text;
  final Rect boundingBox;

  const OcrLine({
    required this.text,
    required this.boundingBox,
  });
}

/// Represents a cluster/block of text (e.g. speech bubble or paragraph)
class OcrBlock {
  final String text;
  final Rect boundingBox;
  final List<OcrLine> lines;

  const OcrBlock({
    required this.text,
    required this.boundingBox,
    this.lines = const [],
  });
}

/// Complete OCR result from a captured frame
class OcrResult {
  final String fullText;
  final List<OcrBlock> blocks;
  final int imageWidth;
  final int imageHeight;

  const OcrResult({
    required this.fullText,
    required this.blocks,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  static const OcrResult empty = OcrResult(
    fullText: '',
    blocks: [],
    imageWidth: 0,
    imageHeight: 0,
  );
}
