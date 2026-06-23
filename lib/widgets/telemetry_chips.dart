import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/agv_telemetry.dart';
import '../services/connection_controller.dart';
import '../services/telemetry_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Batarya, hız ve sıcaklık göstergelerinin bağımsız kart grubu.
///
/// Bağlantı barından ayrı bir bileşendir; `GamePage` içinde kendi
/// `Positioned` katmanıyla istenildiği yere yerleştirilebilir.
/// Bağlantı yokken veya veri eskimişse göstergeler soluk gri görünür.
class TelemetryChips extends StatelessWidget {
  const TelemetryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvConnectionState>(
      valueListenable: ConnectionController.instance.state,
      builder: (context, conn, _) {
        return ValueListenableBuilder<AgvTelemetry>(
          valueListenable: TelemetryController.instance.telemetry,
          builder: (context, t, _) {
            final live = conn.status == AgvConnectionStatus.connected;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AgvColors.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AgvColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BatteryChip(value: t.batteryPct, enabled: live),
                  SizedBox(width: 6.w),
                  _MetricChip(
                    icon: Icons.speed,
                    label: t.speedMps == null
                        ? '—'
                        : '${t.speedMps!.toStringAsFixed(2)} m/s',
                    accent: AgvColors.info,
                    enabled: live,
                  ),
                  SizedBox(width: 6.w),
                  _MetricChip(
                    icon: Icons.thermostat,
                    label: t.temperatureC == null
                        ? '—'
                        : '${t.temperatureC!.toStringAsFixed(1)}°',
                    accent: AgvColors.lift,
                    enabled: live,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Tek bir metric göstergesi: küçük ikon + değer.
class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool enabled;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accent : AgvColors.textDisabled;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AgvColors.surface.withValues(alpha: enabled ? 0.85 : 0.4),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: enabled ? 0.5 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.r),
          SizedBox(width: 5.w),
          Text(
            label,
            style: AgvTypography.mono(
              size: 10.sp,
              color: enabled ? AgvColors.textPrimary : AgvColors.textDisabled,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Batarya için özelleştirilmiş chip — yüzdeye göre renk değiştirir.
class _BatteryChip extends StatelessWidget {
  final double? value;
  final bool enabled;

  const _BatteryChip({required this.value, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final pct = value;
    final accent = pct == null
        ? AgvColors.textMuted
        : pct > 50
        ? AgvColors.accent
        : pct > 20
        ? AgvColors.warning
        : AgvColors.danger;
    final icon = pct == null
        ? Icons.battery_unknown
        : pct > 80
        ? Icons.battery_full
        : pct > 50
        ? Icons.battery_5_bar
        : pct > 20
        ? Icons.battery_3_bar
        : Icons.battery_alert;

    return _MetricChip(
      icon: icon,
      label: pct == null ? '—' : '${pct.toStringAsFixed(0)}%',
      accent: accent,
      enabled: enabled,
    );
  }
}
