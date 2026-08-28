import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/admin_controller.dart';
import '../services/connection_controller.dart';
import '../services/ros_bridge_client.dart';
import '../services/ros_connection_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Sol üst köşede Bluetooth ve ROS bağlantılarını ayrı gösteren kompakt panel.
class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminController.instance.isAdmin,
      builder: (context, isAdmin, _) {
        return ValueListenableBuilder<AgvConnectionState>(
          valueListenable: ConnectionController.instance.state,
          builder: (context, bluetooth, _) {
            return ValueListenableBuilder<RosConnectionState>(
              valueListenable: RosConnectionController.instance.state,
              builder: (context, ros, _) =>
                  _buildPanel(bluetooth, ros, isAdmin),
            );
          },
        );
      },
    );
  }

  Widget _buildPanel(
    AgvConnectionState bluetooth,
    RosConnectionState ros,
    bool isAdmin,
  ) {
    final btConnected =
        isAdmin || bluetooth.status == AgvConnectionStatus.connected;
    final btConnecting =
        !isAdmin && bluetooth.status == AgvConnectionStatus.connecting;
    final btError =
        !isAdmin && bluetooth.status == AgvConnectionStatus.error;

    final btColor = btConnected
        ? AgvColors.connected
        : btConnecting
        ? AgvColors.connecting
        : btError
        ? AgvColors.danger
        : AgvColors.disconnected;
    final btLabel = btConnected
        ? 'Bağlı'
        : btConnecting
        ? 'Bağlanıyor'
        : btError
        ? 'Hata'
        : 'Bağlı Değil';

    final rosConnected = ros.status == RosConnectionStatus.connected;
    final rosConnecting =
        ros.status == RosConnectionStatus.connecting ||
        ros.status == RosConnectionStatus.reconnecting;
    final rosError = ros.status == RosConnectionStatus.error;
    final rosColor = rosConnected
        ? AgvColors.connected
        : rosConnecting
        ? AgvColors.connecting
        : rosError
        ? AgvColors.danger
        : AgvColors.disconnected;
    final rosLabel = rosConnected
        ? 'Bağlı'
        : rosConnecting
        ? 'Bağlanıyor'
        : rosError
        ? 'Hata'
        : 'Bağlı Değil';

    final panelAccent = (btConnected || rosConnected)
        ? AgvColors.connected
        : (btConnecting || rosConnecting)
        ? AgvColors.connecting
        : (btError || rosError)
        ? AgvColors.danger
        : AgvColors.disconnected;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AgvColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: panelAccent.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: panelAccent.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConnectionLine(
            icon: btConnected
                ? Icons.bluetooth_connected
                : btConnecting
                ? Icons.bluetooth_searching
                : Icons.bluetooth_disabled,
            title: 'Bluetooth',
            status: btLabel,
            color: btColor,
            loading: btConnecting,
          ),
          SizedBox(height: 3.h),
          _ConnectionLine(
            icon: rosConnected
                ? Icons.hub
                : rosConnecting
                ? Icons.sync
                : Icons.hub_outlined,
            title: 'ROS',
            status: rosLabel,
            color: rosColor,
            loading: rosConnecting,
          ),
        ],
      ),
    );
  }
}

class _ConnectionLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final Color color;
  final bool loading;

  const _ConnectionLine({
    required this.icon,
    required this.title,
    required this.status,
    required this.color,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.r, color: color),
        SizedBox(width: 5.w),
        SizedBox(
          width: 52.w,
          child: Text(
            title,
            style: AgvTypography.technical(
              size: 9.sp,
              color: AgvColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          width: 5.r,
          height: 5.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 3),
            ],
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          status,
          style: AgvTypography.technical(
            size: 9.sp,
            color: color,
            letterSpacing: 0.4,
            weight: FontWeight.w700,
          ),
        ),
        if (loading) ...[
          SizedBox(width: 6.w),
          SizedBox(
            width: 9.r,
            height: 9.r,
            child: CircularProgressIndicator(strokeWidth: 1.4, color: color),
          ),
        ],
      ],
    );
  }
}
