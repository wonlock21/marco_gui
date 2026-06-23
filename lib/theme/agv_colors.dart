import 'package:flutter/material.dart';

/// Endüstriyel dark dashboard renk paleti.
/// AGV operatör paneli için merkezi token'lar.
class AgvColors {
  AgvColors._();

  // Arka plan katmanları
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF131A22);
  static const Color surfaceElevated = Color(0xFF1B232D);
  static const Color surfaceOverlay = Color(0xFF222D39);

  // Border / ayırıcılar
  static const Color borderSubtle = Color(0x1FFFFFFF); // ~12% white
  static const Color borderStrong = Color(0x33FFFFFF); // ~20% white
  static const Color divider = Color(0x14FFFFFF);

  // Metin
  static const Color textPrimary = Color(0xFFE8EEF5);
  static const Color textSecondary = Color(0xFF9AA7B5);
  static const Color textMuted = Color(0xFF5C6A78);
  static const Color textDisabled = Color(0xFF3A4654);

  // Aksent renkleri
  static const Color accent = Color(0xFF00D4AA); // Teal/Mint — bağlı, OK
  static const Color accentSoft = Color(0x3300D4AA);
  static const Color info = Color(0xFF4DA3FF);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4757);
  static const Color dangerSoft = Color(0x33FF4757);

  // Durum bazlı (semantic)
  static const Color connected = accent;
  static const Color connecting = warning;
  static const Color disconnected = danger;
  static const Color autonomy = Color(0xFF7C5CFF); // mor — otonom

  // Lift / aksesuar
  static const Color lift = Color(0xFFFF9F1C);
  static const Color buzzer = danger;
  static const Color light = Color(0xFFFFD93D);
  static const Color fan = Color(0xFF38BDF8);
}
