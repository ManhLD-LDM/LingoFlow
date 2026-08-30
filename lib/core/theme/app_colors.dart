import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds & Surface
  static const Color bgDark = Color(0xFF080B11);
  static const Color surfaceShell = Color(0xFF0E1524);
  static const Color surfaceCore = Color(0xFF161F33);
  static const Color surfaceCard = Color(0xFF1A243B);
  static const Color surfaceModal = Color(0xFF131B2E);

  // Accents & Neons
  static const Color cyanPrimary = Color(0xFF00F2FE);
  static const Color cyanSecondary = Color(0xFF4FACFE);
  static const Color emeraldLive = Color(0xFF10B981);
  static const Color emeraldLiveGlow = Color(0xFF34D399);
  static const Color redRecord = Color(0xFFEF4444);
  static const Color amberStar = Color(0xFFF59E0B);
  static const Color violetAccent = Color(0xFF8B5CF6);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);

  // Glass & Borders
  static const Color glassWhite = Color(0x14FFFFFF); // 8% white
  static const Color borderLight = Color(0x1FFFFFFF); // 12% white
  static const Color borderSubtle = Color(0x0FFFFFFF); // 6% white
  static const Color borderCyan = Color(0x6600F2FE); // 40% cyan

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyanPrimary, cyanSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liveGradient = LinearGradient(
    colors: [emeraldLive, emeraldLiveGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161F33), Color(0xFF0E1524)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0A0F1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassOverlayGradient = LinearGradient(
    colors: [
      Color(0x2800F2FE),
      Color(0x054FACFE),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
