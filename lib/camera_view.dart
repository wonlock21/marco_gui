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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AgvColors.background,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AgvColors.info.withValues(alpha: 0.65),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AgvColors.info.withValues(alpha: 0.14),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Mjpeg(
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
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
          color: AgvColors.background.withValues(alpha: 0.55),
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AgvColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AgvColors.danger.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      color: AgvColors.danger,
                      size: 12.r,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Kamera yok',
                      style: AgvTypography.technical(
                        size: 9.sp,
                        color: AgvColors.danger,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
