import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'agv_colors.dart';

/// Yeniden kullanılabilir BoxDecoration ve panel token'ları.
class AgvDecorations {
  AgvDecorations._();

  /// Cam görünümlü ana panel (saydam arka plan, ince border).
  static BoxDecoration glassPanel({
    Color? borderColor,
    double radius = 12,
    double alpha = 0.55,
  }) {
    return BoxDecoration(
      color: AgvColors.surface.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(
        color: borderColor ?? AgvColors.borderSubtle,
        width: 1,
      ),
    );
  }

  /// Daha belirgin panel (ayarlar tile'ları için).
  static BoxDecoration solidPanel({Color? borderColor, double radius = 14}) {
    return BoxDecoration(
      color: AgvColors.surfaceElevated,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(
        color: borderColor ?? AgvColors.borderSubtle,
        width: 1,
      ),
    );
  }

  /// Aksent renkli pill / badge.
  static BoxDecoration pill({
    required Color accent,
    double radius = 999,
    double alpha = 0.16,
  }) {
    return BoxDecoration(
      color: accent.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
    );
  }

  /// Aksent renkli durum kutusu (status chip).
  static BoxDecoration statusChip(Color accent) {
    return BoxDecoration(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: accent.withValues(alpha: 0.45)),
    );
  }

  /// Hafif glow (yalnızca kritik elementler için kullan).
  static List<BoxShadow> glow(
    Color color, {
    double blur = 14,
    double spread = 0.5,
    double alpha = 0.35,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }
}
