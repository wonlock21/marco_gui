import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/app_tab.dart';
import 'services/agv_native_bridge.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';

/// Buzzer toggle butonu.
class AccessoryButtons extends StatefulWidget {
  const AccessoryButtons({super.key});

  @override
  State<AccessoryButtons> createState() => _AccessoryButtonsState();
}

class _AccessoryButtonsState extends State<AccessoryButtons> {
  final _bridge = AgvNativeBridge.instance;
  bool isBuzzerOn = false;

  void toggleBuzzer() {
    final newState = !isBuzzerOn;
    final cmdToSend = newState ? 'B_AC' : 'B_KAPA';

    setState(() {
      isBuzzerOn = newState;
    });

    _bridge.sendAccessory(cmdToSend).catchError((e) {
      debugPrint('Buzzer Hatası: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = isBuzzerOn ? AgvColors.buzzer : AgvColors.textMuted;

    return Container(
      padding: EdgeInsets.all(8.r),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: toggleBuzzer,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent, width: 1.5),
            ),
            child: Icon(Icons.campaign, color: accent, size: 22.r),
          ),
        ),
      ),
    );
  }
}

/// Üst panel: Görev / Harita sekme butonları.
class FeatureButtons extends StatelessWidget {
  final AppTab activeTab;
  final void Function(AppTab) onTabChange;

  const FeatureButtons({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TabChip(
          icon: Icons.assignment,
          label: 'GÖREV',
          accent: AgvColors.info,
          isActive: activeTab == AppTab.gorev,
          onTap: () => onTabChange(
            activeTab == AppTab.gorev ? AppTab.manuel : AppTab.gorev,
          ),
        ),
        SizedBox(width: 8.w),
        _TabChip(
          icon: Icons.map,
          label: 'HARİTA',
          accent: AgvColors.lift,
          isActive: activeTab == AppTab.harita,
          onTap: () => onTabChange(
            activeTab == AppTab.harita ? AppTab.manuel : AppTab.harita,
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = isActive ? accent : accent.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: isActive
              ? AgvDecorations.statusChip(accent)
              : BoxDecoration(
                  color: accent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: effectiveAccent, size: 18.r),
              SizedBox(width: 6.w),
              Text(
                label,
                style: AgvTypography.badge.copyWith(
                  color: effectiveAccent,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
