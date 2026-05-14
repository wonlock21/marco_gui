import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../log_manager.dart';
import '../services/agv_native_bridge.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          width: 52.w,
          height: 72.h,
          decoration: BoxDecoration(
            color: Colors.red.shade900,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.redAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.45),
                blurRadius: 12,
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
                'E\nSTOP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
