import 'dart:typed_data';

class BmpEncoder {
  /// Encodes 32-bit BGRA/RGBA raw pixels into a standard BMP image file in memory
  static Uint8List encodeBgra(Uint8List rawPixels, int width, int height) {
    final imageSize = width * height * 4;
    final fileSize = 54 + imageSize;

    final header = Uint8List(54);
    final bd = ByteData.view(header.buffer);

    // Bitmap File Header (14 bytes)
    header[0] = 0x42; // 'B'
    header[1] = 0x4D; // 'M'
    bd.setUint32(2, fileSize, Endian.little);
    bd.setUint32(6, 0, Endian.little); // Reserved
    bd.setUint32(10, 54, Endian.little); // Pixel data offset

    // DIB Header (BITMAPINFOHEADER - 40 bytes)
    bd.setUint32(14, 40, Endian.little); // Header size
    bd.setInt32(18, width, Endian.little);
    bd.setInt32(22, -height, Endian.little); // Top-down BMP
    bd.setUint16(26, 1, Endian.little); // Color planes
    bd.setUint16(28, 32, Endian.little); // 32 bits per pixel (BGRA)
    bd.setUint32(30, 0, Endian.little); // No compression (BI_RGB)
    bd.setUint32(34, imageSize, Endian.little);
    bd.setInt32(38, 2835, Endian.little); // Horizontal resolution (72 DPI)
    bd.setInt32(42, 2835, Endian.little); // Vertical resolution (72 DPI)
    bd.setUint32(46, 0, Endian.little);
    bd.setUint32(50, 0, Endian.little);

    final result = BytesBuilder(copy: false);
    result.add(header);
    result.add(rawPixels);
    return result.toBytes();
  }
}
