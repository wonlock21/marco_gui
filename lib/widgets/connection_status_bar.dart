import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/connection_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Bağlantı durumunu gösteren kompakt pill chip.
///
/// Sol üst köşede bağımsız olarak konumlanır. Telemetri göstergelerinden
/// ayrılmıştır — operatör her iki bilgiyi de aynı anda görebilir ama
/// görsel olarak gruplar bağımsızdır.
class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvConnectionState>(
      valueListenable: ConnectionController.instance.state,
      builder: (context, conn, _) {
        final Color accent;
        final IconData icon;
        final String label;

        switch (conn.status) {
          case AgvConnectionStatus.connected:
            accent = AgvColors.connected;
            icon = Icons.bluetooth_connected;
            label =
                'BAĞLI${conn.deviceAddress != null ? ' · ${conn.deviceAddress}' : ''}';
          case AgvConnectionStatus.connecting:
            accent = AgvColors.connecting;
            icon = Icons.bluetooth_searching;
            label = 'BAĞLANIYOR';
          case AgvConnectionStatus.error:
            accent = AgvColors.danger;
            icon = Icons.error_outline;
            label = (conn.message ?? 'BAĞLANTI HATASI').toUpperCase();
          case AgvConnectionStatus.disconnected:
            accent = AgvColors.disconnected;
            icon = Icons.bluetooth_disabled;
            label = (conn.message ?? 'BAĞLANTI YOK').toUpperCase();
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AgvColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.7), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.r,
                height: 6.r,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(icon, color: accent, size: 13.r),
              SizedBox(width: 6.w),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 180.w),
                child: Text(
                  label,
                  style: AgvTypography.technical(
                    size: 10.sp,
                    color: AgvColors.textPrimary,
                    letterSpacing: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (conn.status == AgvConnectionStatus.connecting) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 12.r,
                  height: 12.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
