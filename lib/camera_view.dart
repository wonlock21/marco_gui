import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'theme/agv_colors.dart';
import 'theme/agv_typography.dart';

class CameraView extends StatelessWidget {
  final String streamUrl;

  const CameraView({super.key, required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AgvColors.background,
        border: Border.all(color: AgvColors.accent, width: 1.5),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AgvColors.accent.withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: Mjpeg(
          isLive: true,
          stream: streamUrl,
          loading: (context) => Container(
            color: AgvColors.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AgvColors.accent),
                  SizedBox(height: 10.h),
                  Text(
                    'SİNYAL ARANIYOR...',
                    style: AgvTypography.technical(
                      size: 11.sp,
                      color: AgvColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (context, error, stack) => Container(
            color: AgvColors.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.signal_wifi_off,
                    color: AgvColors.danger,
                    size: 36.r,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'BAĞLANTI YOK',
                    style: AgvTypography.technical(
                      size: 12.sp,
                      color: AgvColors.danger,
                      letterSpacing: 1.8,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    streamUrl,
                    style: AgvTypography.mono(
                      size: 10.sp,
                      color: AgvColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
