import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'agv_colors.dart';

/// Endüstriyel dark dashboard tipografi token'ları.
///
/// - `Rajdhani`: başlıklar, etiketler (sıkıştırılmış teknik görünüm)
/// - `JetBrainsMono`: terminal/log/numerik
/// - `Inter`: gövde metni
class AgvTypography {
  AgvTypography._();

  static TextStyle technical({
    double? size,
    Color? color,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 1.0,
  }) {
    return TextStyle(
      fontFamily: 'Rajdhani',
      fontSize: size,
      color: color ?? AgvColors.textPrimary,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono({
    double? size,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: size,
      color: color ?? AgvColors.textPrimary,
      fontWeight: weight,
    );
  }

  static TextStyle body({
    double? size,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      color: color ?? AgvColors.textPrimary,
      fontWeight: weight,
    );
  }

  // Hazır stiller
  static TextStyle get pageTitle => technical(
        size: 18.sp,
        color: AgvColors.textPrimary,
        weight: FontWeight.w700,
        letterSpacing: 1.5,
      );

  static TextStyle get sectionLabel => technical(
        size: 11.sp,
        color: AgvColors.textSecondary,
        weight: FontWeight.w600,
        letterSpacing: 1.8,
      );

  static TextStyle get tileTitle => body(
        size: 14.sp,
        color: AgvColors.textPrimary,
        weight: FontWeight.w600,
      );

  static TextStyle get tileSubtitle => body(
        size: 11.sp,
        color: AgvColors.textMuted,
        weight: FontWeight.w400,
      );

  static TextStyle get badge => technical(
        size: 11.sp,
        weight: FontWeight.w700,
        letterSpacing: 1.5,
      );

  static TextStyle get caption => body(
        size: 10.sp,
        color: AgvColors.textMuted,
        weight: FontWeight.w400,
      );
}
