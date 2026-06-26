import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../log_manager.dart';
import '../services/agv_native_bridge.dart';
import '../services/mission_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

class EStopButton extends StatelessWidget {
  const EStopButton({super.key});

  Future<void> _onPressed() async {
    HapticFeedback.heavyImpact();
    LogManager.addLog('E-STOP');
    try {
      await AgvNativeBridge.instance.sendEmergencyStop();
    } catch (e) {
      debugPrint('E-Stop hatası: $e');
    }
    MissionController.instance.onEmergencyStop();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Acil durdurma',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onPressed,
          borderRadius: BorderRadius.circular(14.r),
          child: Ink(
            width: 56.w,
            height: 35.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AgvColors.danger, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AgvColors.danger.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop_circle, color: Colors.white, size: 26.r),
                SizedBox(height: 2.h),
                Text(
                  'E-STOP',
                  textAlign: TextAlign.center,
                  style: AgvTypography.technical(
                    size: 10.sp,
                    color: Colors.white,
                    weight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
