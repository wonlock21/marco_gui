import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/admin_controller.dart';
import '../services/connection_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Sol üst köşede Bluetooth bağlantı durumunu gösteren kompakt panel.
///
/// Yalnızca tek bağlantı kaynağı (Bluetooth) gösterilir; robot haberleşmesi
/// de aynı kanal üzerinden yürütüldüğünden ayrı satır eklenmez.
class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminController.instance.isAdmin,
      builder: (context, isAdmin, _) {
        return ValueListenableBuilder<AgvConnectionState>(
          valueListenable: ConnectionController.instance.state,
          builder: (context, conn, _) => _buildPanel(conn, isAdmin),
        );
      },
    );
  }

  Widget _buildPanel(AgvConnectionState conn, bool isAdmin) {
    final bool isConnected =
        isAdmin || conn.status == AgvConnectionStatus.connected;
    final bool isConnecting =
        !isAdmin && conn.status == AgvConnectionStatus.connecting;

    final Color accent;
    final String statusLabel;

    if (isConnected) {
      accent = AgvColors.connected;
      statusLabel = 'Bağlı';
    } else if (isConnecting) {
      accent = AgvColors.connecting;
      statusLabel = 'Bağlanıyor';
    } else if (conn.status == AgvConnectionStatus.error) {
      accent = AgvColors.danger;
      statusLabel = 'Hata';
    } else {
      accent = AgvColors.disconnected;
      statusLabel = 'Bağlı Değil';
    }

    // Kanal: cihaz adresi varsa göster, yoksa varsayılan.
    final String channelLabel =
        conn.deviceAddress ?? (isConnected ? 'HC-06' : '—');

    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 3.h),
      decoration: BoxDecoration(
        color: AgvColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: accent.withValues(alpha: isConnected ? 0.6 : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConnected ? AgvColors.connected : Colors.black)
                .withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Satır 1: BT durumu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : isConnecting
                        ? Icons.bluetooth_searching
                        : Icons.bluetooth_disabled,
                size: 12.r,
                color: accent,
              ),
              SizedBox(width: 5.w),
              Text(
                'Bluetooth',
                style: AgvTypography.technical(
                  size: 9.sp,
                  color: AgvColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                width: 5.r,
                height: 5.r,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                statusLabel,
                style: AgvTypography.technical(
                  size: 9.sp,
                  color: accent,
                  letterSpacing: 0.4,
                  weight: FontWeight.w700,
                ),
              ),
              if (isConnecting) ...[
                SizedBox(width: 6.w),
                SizedBox(
                  width: 10.r,
                  height: 10.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
          // Satır 2: Kanal adı (yalnızca bağlı veya bağlanıyor durumunda)
          if (isConnected || isConnecting) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 17.w), // ikon hizalaması
                Text(
                  'Kanal',
                  style: AgvTypography.technical(
                    size: 8.sp,
                    color: AgvColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  channelLabel,
                  style: AgvTypography.technical(
                    size: 8.sp,
                    color: AgvColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
