import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'accesories.dart';
import 'agv_settings.dart';
import 'autonom_button.dart';
import 'background.dart';
import 'bluetooth_button.dart';
import 'camera_view.dart';
import 'joystick.dart';
import 'lift_joystick.dart';
import 'log_manager.dart';
import 'models/app_tab.dart';
import 'services/ros_connection_controller.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_typography.dart';
import 'widgets/connection_status_bar.dart';
import 'widgets/estop_button.dart';
import 'widgets/last_message_bar.dart';
import 'widgets/map_panel.dart';
import 'widgets/mission_panel.dart';
import 'widgets/status_cards.dart';
import 'widgets/telemetry_chips.dart';

/// Üst kart şeridinin yaklaşık yüksekliği (chip'lerin oturduğu bant).
const double _kTopBandHeight = 36;

/// Immersive modda SafeArea inset'leri 0 olduğu için kenar boşluğu.
const double _kEdgePad = 16;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool isCameraOn = false;
  bool _showStatusCards = false;
  AppTab _activeTab = AppTab.manuel;

  void _onTabChange(AppTab tab) {
    setState(() {
      _activeTab = tab;
      // Görev/Harita sekmelerine geçince durum kartlarını kapat.
      if (tab != AppTab.manuel) _showStatusCards = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    RosConnectionController.instance.stopManual();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topOffset = _kTopBandHeight + _kEdgePad.h + 8.h;
    final isManuel = _activeTab == AppTab.manuel;
    // Son mesaj şeridi yüksekliği kadar lift grubunu yukarı çek.
    final bottomBarClearance = 36.h;

    return Scaffold(
      backgroundColor: AgvColors.background,
      body: Stack(
        children: [
          // KATMAN 1 — Zemin / Kamera
          if (isCameraOn && isManuel)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: _kTopBandHeight + _kEdgePad),
                child: CameraView(streamUrl: 'http://192.168.1.100:81/stream'),
              ),
            )
          else
            const BackgroundColor(),

          // KATMAN 2a — Bağlantı durumu chip'i (sol üst, bağımsız)
          Positioned(
            top: _kEdgePad.h,
            left: 18.w,
            child: const SafeArea(bottom: false, child: ConnectionStatusBar()),
          ),

          // KATMAN 2b — Telemetri chip'leri (sağ üst, bağımsız)
          Positioned(
            top: _kEdgePad.h,
            right: 24.w,
            child: const SafeArea(bottom: false, child: TelemetryChips()),
          ),

          // KATMAN 3 — Üst orta bant: Manuel/Otonom + Görev + Harita
          Positioned(
            top: _kEdgePad.h,
            left: 0,
            right: 80,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AutonomusButton(
                      activeTab: _activeTab,
                      onTabChange: _onTabChange,
                    ),
                    SizedBox(width: 12.w),
                    FeatureButtons(
                      activeTab: _activeTab,
                      onTabChange: _onTabChange,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // KATMAN 4 — Sol kenar: Toolbar (her zaman görünür)
          Positioned(
            top: topOffset,
            bottom: _kEdgePad.h + 8.h,
            left: 8.w,
            child: SafeArea(
              top: false,
              bottom: false,
              child: _LeftRail(
                isCameraOn: isCameraOn,
                onToggleCamera: () => setState(() => isCameraOn = !isCameraOn),
              ),
            ),
          ),

          // KATMAN 5 — E-Stop (telemetri ile joystick arasında ortalı)
          if (isManuel)
            Positioned(
              right: 48.w,
              top: topOffset + 8.h,
              bottom:
                  _kEdgePad.h + 4.h + MediaQuery.of(context).size.height * 0.36,
              child: const Align(
                alignment: Alignment.centerRight,
                child: EStopButton(),
              ),
            ),

          // KATMAN 5b — Durum kartları (yalnızca MANUEL sekmesinde)
          if (isManuel && _showStatusCards)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 215.w,
                  right: 160.w,
                  top: 0.h,
                  bottom: 8.h,
                ),
                child: const Align(
                  alignment: Alignment(0, 0.75),
                  child: StatusCards(),
                ),
              ),
            ),

          // KATMAN 5c — Son mesaj + TX (sol alt, lift'lerin altında)
          Positioned(
            bottom: _kEdgePad.h,
            left: 18.w,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const LastMessageBar(),
                  SizedBox(width: 8.w),
                  const _TxBar(),
                ],
              ),
            ),
          ),

          // KATMAN 6 — Lift joystick'ler + toggle (toolbar'ın sağında, altta)
          if (isManuel)
            Positioned(
              left: 98.w,
              bottom: 48.h,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusToggleButton(
                      active: _showStatusCards,
                      onTap: () =>
                          setState(() => _showStatusCards = !_showStatusCards),
                    ),
                    SizedBox(height: 4.h),
                    const LiftJoystick(),
                    SizedBox(height: 6.h),
                    const LiftSideJoystick(),
                  ],
                ),
              ),
            ),

          // KATMAN 7 — Ana sürüş joystick'i (yalnızca MANUEL)
          if (isManuel)
            Positioned(
              right: 48.w,
              bottom: _kEdgePad.h + 4.h,
              child: SafeArea(
                top: false,
                child: Joystick(isCameraOn: isCameraOn),
              ),
            ),

          // KATMAN 8 — Görev paneli (GÖREV sekmesi)
          if (_activeTab == AppTab.gorev)
            Positioned(
              top: topOffset + 10.h,
              bottom: _kEdgePad.h + bottomBarClearance,
              left: 70.w,
              right: 10.w,
              child: const SafeArea(child: MissionPanel()),
            ),

          // KATMAN 9 — Harita paneli (HARİTA sekmesi)
          if (_activeTab == AppTab.harita)
            Positioned(
              top: topOffset + 10.h,
              bottom: _kEdgePad.h + bottomBarClearance,
              left: 70.w,
              right: 10.w,
              child: const SafeArea(child: MapPanel()),
            ),
        ],
      ),
    );
  }
}

// ── Sol dikey kontrol şeridi ──────────────────────────────────────────────────

class _LeftRail extends StatelessWidget {
  final bool isCameraOn;
  final VoidCallback onToggleCamera;

  const _LeftRail({required this.isCameraOn, required this.onToggleCamera});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ToolbarButton(
          icon: Icons.settings,
          color: AgvColors.textSecondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgvSettingsPage()),
          ),
        ),
        SizedBox(height: 6.h),
        const BluetoothButton(),
        SizedBox(height: 6.h),
        _ToolbarButton(
          icon: isCameraOn ? Icons.videocam_off : Icons.videocam,
          color: isCameraOn ? AgvColors.danger : AgvColors.info,
          onTap: onToggleCamera,
        ),
        SizedBox(height: 2.h),
        const AccessoryButtons(),
      ],
    );
  }
}

// ── Durum kartı toggle butonu ─────────────────────────────────────────────────

class _StatusToggleButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _StatusToggleButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AgvColors.info : AgvColors.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 52.r,
          height: 34.r,
          decoration: BoxDecoration(
            color: AgvColors.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1.2),
          ),
          child: Icon(
            active ? Icons.dashboard : Icons.dashboard_outlined,
            color: color,
            size: 18.r,
          ),
        ),
      ),
    );
  }
}

// ── Toolbar butonu ────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AgvColors.surfaceElevated,
            border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
          ),
          child: Icon(icon, color: color, size: 20.r),
        ),
      ),
    );
  }
}

// ── TX Göstergesi ─────────────────────────────────────────────────────────────
/// Kotlin'e gönderilen son joystick ve lift komut numaralarını canlı gösterir.
class _TxBar extends StatelessWidget {
  const _TxBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Joystick TX
          ValueListenableBuilder<String>(
            valueListenable: LogManager.lastJoyCmdNotifier,
            builder: (context, cmd, child) => Text(
              'JOY:$cmd',
              style: AgvTypography.mono(
                size: 7.5.sp,
                color: AgvColors.accent.withValues(alpha: 0.85),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 10.h,
            margin: EdgeInsets.symmetric(horizontal: 5.w),
            color: Colors.white12,
          ),
          // Lift TX
          ValueListenableBuilder<String>(
            valueListenable: LogManager.lastLiftCmdNotifier,
            builder: (context, cmd, child) => Text(
              'LFT:$cmd',
              style: AgvTypography.mono(
                size: 7.5.sp,
                color: Colors.orangeAccent.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
