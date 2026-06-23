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
import 'theme/agv_colors.dart';
import 'widgets/connection_status_bar.dart';
import 'widgets/estop_button.dart';
import 'widgets/telemetry_chips.dart';

/// Üst kart şeridinin yaklaşık yüksekliği (chip'lerin oturduğu bant).
/// Kamera dolgusu ve diğer üst elemanlar bu değere göre hizalanır.
const double _kTopBandHeight = 36;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool isCameraOn = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Üst chip'lerle aynı bantta duracak elemanlar için Y koordinatı.
    final topOffset = _kTopBandHeight + 8.h;

    return Scaffold(
      backgroundColor: AgvColors.background,
      body: Stack(
        children: [
          // KATMAN 1 — Zemin / Kamera
          if (isCameraOn)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: _kTopBandHeight),
                child: CameraView(streamUrl: 'http://192.168.1.100:81/stream'),
              ),
            )
          else
            const BackgroundColor(),

          // KATMAN 2a — Bağlantı durumu chip'i (sol üst, bağımsız)
          Positioned(
            top: 0.h,
            left: 18.w,
            child: const SafeArea(bottom: false, child: ConnectionStatusBar()),
          ),

          // KATMAN 2b — Telemetri chip'leri (sağ üst, bağımsız)
          Positioned(
            top: 0.h,
            right: 54.w,
            child: const SafeArea(bottom: false, child: TelemetryChips()),
          ),

          // KATMAN 3 — Üst orta bant: Manuel/Otonom + Senaryo + Harita
          Positioned(
            top: 0.h,
            left: 0,
            right: 80,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AutonomusButton(),
                    SizedBox(width: 12.w),
                    const FeatureButtons(),
                  ],
                ),
              ),
            ),
          ),

          // KATMAN 4 — Sol kenar: Toolbar (üstte) + Buzzer (en altta)
          Positioned(
            top: topOffset,
            bottom: 12.h,
            left: 8.w,
            child: SafeArea(
              child: _LeftRail(
                isCameraOn: isCameraOn,
                onToggleCamera: () => setState(() => isCameraOn = !isCameraOn),
              ),
            ),
          ),

          // KATMAN 5 — Sağ kenar: E-Stop dikey
          Positioned(
            top: 42.h,
            right: 85.w,
            child: const SafeArea(child: EStopButton()),
          ),

          // KATMAN 6 — Lift joystick (sol-orta, toolbar'ın sağında)
          Positioned(
            left: 98.w,
            bottom: 12.h,
            child: const SafeArea(child: LiftJoystick()),
          ),

          // KATMAN 7 — Ana sürüş joystick'i (sağ-orta, E-Stop'un solunda)
          Positioned(
            right: 48.w,
            bottom: 12.h,
            child: SafeArea(child: Joystick(isCameraOn: isCameraOn)),
          ),
        ],
      ),
    );
  }
}

/// Sol kenardaki dikey kontrol şeridi.
/// Üstte: Ayarlar, Bluetooth, Kamera
/// Altta: Buzzer
class _LeftRail extends StatelessWidget {
  final bool isCameraOn;
  final VoidCallback onToggleCamera;

  const _LeftRail({required this.isCameraOn, required this.onToggleCamera});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Üst grup
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _ToolbarButton(
              icon: Icons.settings,
              color: AgvColors.textSecondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgvSettingsPage(),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            const BluetoothButton(),
            SizedBox(height: 8.h),
            _ToolbarButton(
              icon: isCameraOn ? Icons.videocam_off : Icons.videocam,
              color: isCameraOn ? AgvColors.danger : AgvColors.info,
              onTap: onToggleCamera,
            ),
            SizedBox(height: 2.h),
            const AccessoryButtons(),
          ],
        ),
        // Alt: aksesuar (buzzer)
      ],
    );
  }
}

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
