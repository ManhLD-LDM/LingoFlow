/// Defines the execution strategy for text recognition (OCR)
enum OcrEngineMode {
  autoFallback(
    id: 'auto_fallback',
    displayName: 'Tự động (Ưu tiên Cloud, dự phòng Native)',
    description: 'Chất lượng cao nhất khi có mạng, tự động dùng Native OCR khi mất kết nối.',
  ),
  cloudOnly(
    id: 'cloud_only',
    displayName: 'Chỉ dùng Cloud OCR.space',
    description: 'Tối ưu cho chữ tượng hình phức tạp (Kanji, Hán tự, Hangul).',
  ),
  offlineOnly(
    id: 'offline_only',
    displayName: 'Chỉ dùng Native / Offline OCR',
    description: 'Tốc độ cực nhanh, không tiêu tốn dung lượng mạng hay hạn mức API.',
  );

  final String id;
  final String displayName;
  final String description;

  const OcrEngineMode({
    required this.id,
    required this.displayName,
    required this.description,
  });

  static OcrEngineMode fromId(String id) {
    return OcrEngineMode.values.firstWhere(
      (e) => e.id == id,
      orElse: () => OcrEngineMode.autoFallback,
    );
  }
}
