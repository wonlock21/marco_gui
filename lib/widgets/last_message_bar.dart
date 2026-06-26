import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/mission_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Kompakt "Son Mesaj" şeridi.
///
/// [MissionController.state.lastSystemMessage] değiştiğinde güncellenir.
/// Ekranın alt merkezine küçük bir bildirim çubuğu olarak yerleştirilir.
class LastMessageBar extends StatelessWidget {
  const LastMessageBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: MissionController.instance.state,
      builder: (context, state, _) {
        final msg = state.lastSystemMessage;
        if (msg == null || msg.isEmpty) return const SizedBox.shrink();

        final isStop = msg.toLowerCase().contains('durdurma') ||
            msg.toLowerCase().contains('e-stop');
        final accent = isStop ? AgvColors.danger : AgvColors.textSecondary;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AgvColors.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isStop ? Icons.warning_amber_rounded : Icons.info_outline,
                size: 11.r,
                color: accent,
              ),
              SizedBox(width: 5.w),
              Text(
                'SON MESAJ',
                style: AgvTypography.technical(
                  size: 8.sp,
                  color: AgvColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                width: 1,
                height: 10.h,
                color: AgvColors.textSecondary.withValues(alpha: 0.3),
              ),
              SizedBox(width: 6.w),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 180.w),
                child: Text(
                  msg,
                  style: AgvTypography.technical(
                    size: 9.sp,
                    color: isStop ? accent : AgvColors.textPrimary,
                    weight: isStop ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
