import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/autonomy_controller.dart';
import '../services/connection_controller.dart';

enum ControlLockReason { connecting, disconnected, autonomy }

/// Bağlantı ve otonom moda göre kontrol kilidi + görsel overlay.
class ControlLockOverlay extends StatefulWidget {
  final Widget child;
  final bool lockOnAutonomy;

  const ControlLockOverlay({
    super.key,
    required this.child,
    this.lockOnAutonomy = false,
  });

  @override
  State<ControlLockOverlay> createState() => _ControlLockOverlayState();
}

class _ControlLockOverlayState extends State<ControlLockOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  ControlLockReason? _resolveLock(AgvConnectionState conn, bool isAuto) {
    if (conn.status == AgvConnectionStatus.connecting) {
      return ControlLockReason.connecting;
    }
    if (conn.status == AgvConnectionStatus.disconnected ||
        conn.status == AgvConnectionStatus.error) {
      return ControlLockReason.disconnected;
    }
    if (widget.lockOnAutonomy && isAuto) {
      return ControlLockReason.autonomy;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvConnectionState>(
      valueListenable: ConnectionController.instance.state,
      builder: (context, conn, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AutonomyController.instance.isAuto,
          builder: (context, isAuto, _) {
            final lock = _resolveLock(conn, isAuto);
            final isLocked = lock != null;

            return Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  ignoring: isLocked,
                  child: Opacity(
                    opacity: isLocked ? 0.4 : 1.0,
                    child: widget.child,
                  ),
                ),
                if (lock != null) _buildOverlay(lock),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOverlay(ControlLockReason reason) {
    final String label;
    final IconData icon;
    final Color accent;

    switch (reason) {
      case ControlLockReason.connecting:
        label = 'BAĞLANIYOR';
        icon = Icons.bluetooth_searching;
        accent = Colors.amber;
      case ControlLockReason.disconnected:
        label = 'BAĞLANTI YOK';
        icon = Icons.bluetooth_disabled;
        accent = Colors.redAccent;
      case ControlLockReason.autonomy:
        label = 'OTONOM MOD';
        icon = Icons.smart_toy;
        accent = Colors.greenAccent;
    }

    Widget overlay = Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 22.r),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

    if (reason == ControlLockReason.connecting) {
      overlay = FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 0.85).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: overlay,
      );
    }

    return Positioned.fill(child: overlay);
  }
}
