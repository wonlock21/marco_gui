import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'background.dart';
import 'joystick.dart';
import 'camera_view.dart';
import 'bluetooth_button.dart';
import 'agv_settings.dart';
import 'lift_joystick.dart';
import 'autonom_button.dart';
import 'accesories.dart';
import 'widgets/connection_status_bar.dart';
import 'widgets/estop_button.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isCameraOn)
            Positioned.fill(
              child: CameraView(
                streamUrl: 'http://192.168.1.100:81/stream',
              ),
            )
          else
            const BackgroundColor(),

          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConnectionStatusBar(),
          ),

          Positioned(
            right: 30.w,
            bottom: 15.h,
            child: Joystick(
              isCameraOn: isCameraOn,
            ),
          ),

          Positioned(
            bottom: 10.h,
            left: 120.w,
            child: SafeArea(child: const LiftJoystick()),
          ),

          Positioned(
            left: 30.w,
            top: 40.h,
            child: const SafeArea(
              child: BluetoothButton(),
            ),
          ),

          Positioned(
            left: 30.w,
            top: 70.h,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'btn_camera',
                onPressed: () => setState(
                  () => isCameraOn = !isCameraOn,
                ),
                backgroundColor: isCameraOn ? Colors.redAccent : Colors.white,
                child: Icon(
                  isCameraOn ? Icons.videocam_off : Icons.videocam,
                  color: isCameraOn ? Colors.white : Colors.black,
                  size: 20.r,
                ),
              ),
            ),
          ),

          Positioned(
            top: 10.h,
            left: 30.w,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'btn_settings',
                backgroundColor: Colors.grey[900],
                child: Icon(Icons.settings, color: Colors.white, size: 20.r),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgvSettingsPage(),
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            top: 30.h,
            left: 0,
            right: 0,
            child: Center(child: const AutonomusButton()),
          ),

          Positioned(top: 38.h, right: 130.w, child: const FeatureButtons()),

          Positioned(
            bottom: 22.h,
            left: 20.w,
            child: const AccessoryButtons(),
          ),

          Positioned(
            left: 8.w,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Center(child: const EStopButton()),
            ),
          ),
        ],
      ),
    );
  }
}
