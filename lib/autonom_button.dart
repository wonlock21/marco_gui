import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'log_manager.dart';
import 'models/app_tab.dart';
import 'services/agv_native_bridge.dart';
import 'services/autonomy_controller.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';

class AutonomusButton extends StatelessWidget {
  final AppTab activeTab;
  final void Function(AppTab) onTabChange;

  const AutonomusButton({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  Future<void> _onTap(BuildContext context, bool isAuto) async {
    // Başka bir sekmeden geliyorsa önce MANUEL sekmeye geç.
    if (activeTab != AppTab.manuel) {
      onTabChange(AppTab.manuel);
      return;
    }

    // MANUEL sekmesindeyken: mod değiştirme diyaloğu.
    final autonomy = AutonomyController.instance;
    final bridge = AgvNativeBridge.instance;

    if (!isAuto) {
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
              child: const Text('İPTAL', style: TextStyle(color: AgvColors.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OTONOM\'A GEÇ', style: TextStyle(color: AgvColors.autonomy)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final newAuto = !isAuto;
    autonomy.setAuto(newAuto);
    await bridge.setMode(newAuto);
    LogManager.addLog(newAuto ? 'MOD: OTONOM' : 'MOD: MANUEL');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AutonomyController.instance.isAuto,
      builder: (context, isAuto, _) {
        final isActive = activeTab == AppTab.manuel;
        final baseAccent = isAuto ? AgvColors.autonomy : AgvColors.warning;
        final accent = isActive ? baseAccent : baseAccent.withValues(alpha: 0.4);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onTap(context, isAuto),
            borderRadius: BorderRadius.circular(10.r),
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: isActive
                  ? AgvDecorations.statusChip(baseAccent)
                  : BoxDecoration(
                      color: baseAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: baseAccent.withValues(alpha: 0.2)),
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAuto ? Icons.smart_toy : Icons.front_hand,
                    color: accent,
                    size: 18.r,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    isAuto ? 'OTONOM' : 'MANUEL',
                    style: AgvTypography.badge.copyWith(
                      color: accent,
                      fontSize: 10.sp,
                    ),
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
