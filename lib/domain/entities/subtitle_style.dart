import 'package:flutter/material.dart';

enum SubtitleTheme {
  cyberpunk(
    id: 'cyberpunk',
    name: 'Cyberpunk Cyan (Mặc định)',
    textColor: Colors.white,
    borderColor: Colors.cyanAccent,
    backgroundColor: Color(0xFF0F172A),
  ),
  classicYellow(
    id: 'classic_yellow',
    name: 'Classic Cinema Yellow (Phim ảnh)',
    textColor: Color(0xFFFFEB3B),
    borderColor: Color(0xFFFFD54F),
    backgroundColor: Color(0xFF1E1E1E),
  ),
  mangaWhite(
    id: 'manga_white',
    name: 'Manga Balloon (Bong bóng truyện)',
    textColor: Colors.black87,
    borderColor: Colors.black54,
    backgroundColor: Colors.white,
  ),
  minimalDark(
    id: 'minimal_dark',
    name: 'Minimalist Dark (Tối giản)',
    textColor: Colors.white,
    borderColor: Colors.white24,
    backgroundColor: Color(0xFF1E293B),
  );

  final String id;
  final String name;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;

  const SubtitleTheme({
    required this.id,
    required this.name,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  static SubtitleTheme fromId(String id) {
    return SubtitleTheme.values.firstWhere(
      (e) => e.id == id,
      orElse: () => SubtitleTheme.cyberpunk,
    );
  }
}

enum SubtitlePlacement {
  inPlace('Đè lên vị trí gốc (In-place Bounding Box)'),
  bottomCenter('Căn giữa phía dưới màn hình (Movie Subtitle Mode)');

  final String label;
  const SubtitlePlacement(this.label);
}
