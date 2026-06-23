import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'agv_settings.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';

class JoystickSettingsView extends StatelessWidget {
  const JoystickSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JOYSTICK AYARLARI')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BOYUTLANDIRMA', style: AgvTypography.sectionLabel),
              SizedBox(height: 8.h),
              ValueListenableBuilder<double>(
                valueListenable: SettingsManager.joystickScaleNotifier,
                builder: (context, scale, child) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: AgvDecorations.solidPanel(),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Ölçek',
                                style: AgvTypography.tileTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: AgvDecorations.statusChip(
                                AgvColors.accent,
                              ),
                              child: Text(
                                '%${(scale * 100).toInt()}',
                                style: AgvTypography.mono(
                                  size: 12.sp,
                                  color: AgvColors.accent,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AgvColors.accent,
                            inactiveTrackColor: AgvColors.surfaceOverlay,
                            thumbColor: AgvColors.accent,
                            overlayColor:
                                AgvColors.accent.withValues(alpha: 0.18),
                            trackHeight: 3.h,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 8.r,
                            ),
                          ),
                          child: Slider(
                            value: scale,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            onChanged: SettingsManager.setJoystickScale,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Küçük', style: AgvTypography.caption),
                            Text('Büyük', style: AgvTypography.caption),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AgvColors.textMuted,
                    size: 14.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Joystick boyutu anında güncellenir.',
                      style: AgvTypography.caption.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
