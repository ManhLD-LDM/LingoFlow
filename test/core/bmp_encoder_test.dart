import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/core/utils/bmp_encoder.dart';

void main() {
  group('BmpEncoder Tests', () {
    test('encodes raw BGRA pixels into valid 32-bit BMP structure', () {
      const width = 10;
      const height = 5;
      final rawPixels = Uint8List(width * height * 4); // 200 bytes

      // Fill with blue pixels (B: 255, G: 0, R: 0, A: 255)
      for (var i = 0; i < rawPixels.length; i += 4) {
        rawPixels[i] = 255;
        rawPixels[i + 1] = 0;
        rawPixels[i + 2] = 0;
        rawPixels[i + 3] = 255;
      }

      final bmpBytes = BmpEncoder.encodeBgra(rawPixels, width, height);

      // Total size must be 54 (header) + 200 (pixel data) = 254 bytes
      expect(bmpBytes.length, equals(254));

      // Header Magic Bytes 'BM'
      expect(bmpBytes[0], equals(0x42)); // 'B'
      expect(bmpBytes[1], equals(0x4D)); // 'M'

      final bd = ByteData.view(bmpBytes.buffer);

      // File size in header
      expect(bd.getUint32(2, Endian.little), equals(254));

      // Pixel data offset
      expect(bd.getUint32(10, Endian.little), equals(54));

      // DIB header size
      expect(bd.getUint32(14, Endian.little), equals(40));

      // Width and negative height (top-down)
      expect(bd.getInt32(18, Endian.little), equals(width));
      expect(bd.getInt32(22, Endian.little), equals(-height));

      // 32-bit color planes
      expect(bd.getUint16(26, Endian.little), equals(1));
      expect(bd.getUint16(28, Endian.little), equals(32));

      // First pixel in data matches input
      expect(bmpBytes[54], equals(255)); // B
      expect(bmpBytes[55], equals(0)); // G
      expect(bmpBytes[56], equals(0)); // R
      expect(bmpBytes[57], equals(255)); // A
    });
  });
}
