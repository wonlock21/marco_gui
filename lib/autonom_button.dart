import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'log_manager.dart';
import 'services/agv_native_bridge.dart';
import 'services/autonomy_controller.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';

class AutonomusButton extends StatelessWidget {
  const AutonomusButton({super.key});

  Future<void> _toggleMode(BuildContext context) async {
    final autonomy = AutonomyController.instance;
    final bridge = AgvNativeBridge.instance;

    if (!autonomy.isAuto.value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('OTONOM MOD'),
          content: const Text(
            'AGV otonom moda geçecek. Manuel sürüş joystick\'i kilitlenecek. Devam edilsin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'İPTAL',
                style: TextStyle(color: AgvColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'OTONOM\'A GEÇ',
                style: TextStyle(color: AgvColors.autonomy),
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
        final accent = isAuto ? AgvColors.autonomy : AgvColors.warning;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleMode(context),
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
              decoration: AgvDecorations.pill(accent: accent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAuto ? Icons.smart_toy : Icons.front_hand,
                    color: accent,
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isAuto ? 'OTONOM' : 'MANUEL',
                    style: AgvTypography.badge.copyWith(color: accent),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
