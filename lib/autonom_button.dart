import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'log_manager.dart';
import 'services/agv_native_bridge.dart';
import 'services/autonomy_controller.dart';

class AutonomusButton extends StatelessWidget {
  const AutonomusButton({super.key});

  Future<void> _toggleMode(BuildContext context) async {
    final autonomy = AutonomyController.instance;
    final bridge = AgvNativeBridge.instance;

    if (!autonomy.isAuto.value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Otonom Mod',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'AGV otonom moda geçecek. Manuel sürüş joystick\'i kilitlenecek. Devam edilsin mi?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Otonom\'a Geç',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final newAuto = !autonomy.isAuto.value;
    autonomy.setAuto(newAuto);
    await bridge.setMode(newAuto);
    LogManager.addLog(newAuto ? 'MOD: OTONOM' : 'MOD: MANUEL');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AutonomyController.instance.isAuto,
      builder: (context, isAuto, _) {
        return GestureDetector(
          onTap: () => _toggleMode(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isAuto
                  ? Colors.greenAccent.withValues(alpha: 0.2)
                  : Colors.redAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: isAuto ? Colors.greenAccent : Colors.redAccent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAuto ? Icons.smart_toy : Icons.front_hand,
                  color: isAuto ? Colors.greenAccent : Colors.redAccent,
                  size: 24.r,
                ),
                SizedBox(width: 10.w),
                Text(
                  isAuto ? 'OTONOM' : 'MANUEL',
                  style: TextStyle(
                    color: isAuto ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
