import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/admin_controller.dart';
import '../services/autonomy_controller.dart';
import '../services/connection_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

enum ControlLockReason { connecting, disconnected, autonomy }

/// Bağlantı ve otonom moda göre kontrol kilidi + görsel overlay.
///
/// [compact] true ise overlay sadece bir ikon rozeti gösterir
/// (dar widget'lar için, örn. dikey lift joystick).
class ControlLockOverlay extends StatefulWidget {
  final Widget child;
  final bool lockOnAutonomy;
  final bool compact;

  const ControlLockOverlay({
    super.key,
    required this.child,
    this.lockOnAutonomy = false,
    this.compact = false,
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

  ControlLockReason? _resolveLock(
    AgvConnectionState conn,
    bool isAuto,
    bool isAdmin,
  ) {
    // Admin modda BT bağlantı kilitleri atlanır.
    if (!isAdmin) {
      if (conn.status == AgvConnectionStatus.connecting) {
        return ControlLockReason.connecting;
      }
      if (conn.status == AgvConnectionStatus.disconnected ||
          conn.status == AgvConnectionStatus.error) {
        return ControlLockReason.disconnected;
      }
    }
    // Otonom kilidi admin moddan etkilenmez.
    if (widget.lockOnAutonomy && isAuto) {
      return ControlLockReason.autonomy;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminController.instance.isAdmin,
      builder: (context, isAdmin, _) {
        return ValueListenableBuilder<AgvConnectionState>(
          valueListenable: ConnectionController.instance.state,
          builder: (context, conn, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: AutonomyController.instance.isAuto,
              builder: (context, isAuto, _) {
                final lock = _resolveLock(conn, isAuto, isAdmin);
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
        accent = AgvColors.connecting;
      case ControlLockReason.disconnected:
        label = 'BAĞLANTI YOK';
        icon = Icons.bluetooth_disabled;
        accent = AgvColors.danger;
      case ControlLockReason.autonomy:
        label = 'OTO. KİLİTLİ';
        icon = Icons.lock_outline;
        accent = AgvColors.autonomy;
    }

    final Widget content;
    if (widget.compact) {
      content = Center(
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AgvColors.background.withValues(alpha: 0.78),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: accent, size: 20.r),
        ),
      );
    } else {
      content = Container(
        decoration: BoxDecoration(
          color: AgvColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.5),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 22.r),
            SizedBox(height: 4.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AgvTypography.technical(
                size: 10.sp,
                color: accent,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    Widget overlay = content;

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
