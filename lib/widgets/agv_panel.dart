import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/agv_colors.dart';
import '../theme/agv_decorations.dart';
import '../theme/agv_typography.dart';

/// Standart endüstriyel panel — başlık + içerik.
class AgvPanel extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Color? accent;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AgvPanel({
    super.key,
    this.title,
    this.icon,
    this.accent,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(12.r),
      decoration: AgvDecorations.solidPanel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: accent ?? AgvColors.accent, size: 14.r),
                  SizedBox(width: 6.w),
                ],
                Text(
                  title!.toUpperCase(),
                  style: AgvTypography.sectionLabel,
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          child,
        ],
      ),
    );
  }
}

/// Tıklanabilir liste tile'ı — ayarlar ekranı için.
class AgvTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const AgvTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          decoration: AgvDecorations.solidPanel(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AgvColors.accent).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: iconColor ?? AgvColors.accent,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AgvTypography.tileTitle),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(subtitle!, style: AgvTypography.tileSubtitle),
                      ],
                    ],
                  ),
                ),
                ?trailing,
                if (trailing == null && onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AgvColors.textMuted,
                    size: 18.r,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
