import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/connection_controller.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvConnectionState>(
      valueListenable: ConnectionController.instance.state,
      builder: (context, conn, _) {
        final Color bgColor;
        final IconData icon;
        final String label;

        switch (conn.status) {
          case AgvConnectionStatus.connected:
            bgColor = Colors.green.shade800;
            icon = Icons.bluetooth_connected;
            label = 'BAĞLI${conn.deviceAddress != null ? ' · ${conn.deviceAddress}' : ''}';
          case AgvConnectionStatus.connecting:
            bgColor = Colors.amber.shade800;
            icon = Icons.bluetooth_searching;
            label = 'BAĞLANIYOR...';
          case AgvConnectionStatus.error:
            bgColor = Colors.red.shade900;
            icon = Icons.error_outline;
            label = conn.message ?? 'BAĞLANTI HATASI';
          case AgvConnectionStatus.disconnected:
            bgColor = Colors.red.shade900;
            icon = Icons.bluetooth_disabled;
            label = conn.message ?? 'BAĞLANTI YOK';
        }

        return Material(
          color: bgColor.withValues(alpha: 0.92),
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 14.r),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (conn.status == AgvConnectionStatus.connecting)
                    SizedBox(
                      width: 12.r,
                      height: 12.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
