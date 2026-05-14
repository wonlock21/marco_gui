import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/agv_native_bridge.dart';

// ---------------------------------------------------
// 1. AKSESUAR TUŞLARI (Sadece Buzzer)
// ---------------------------------------------------
class AccessoryButtons extends StatefulWidget {
  const AccessoryButtons({super.key});

  @override
  State<AccessoryButtons> createState() => _AccessoryButtonsState();
}

class _AccessoryButtonsState extends State<AccessoryButtons> {
  final _bridge = AgvNativeBridge.instance;
  bool isBuzzerOn = false;

  void toggleBuzzer() {
    bool newState = !isBuzzerOn;
    String cmdToSend = newState ? "B_AC" : "B_KAPA";

    setState(() {
      isBuzzerOn = newState;
    });

    _bridge.sendAccessory(cmdToSend).catchError((e) {
      debugPrint("Buzzer Hatası: $e");
    });  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white10),
      ),
      child: GestureDetector(
        onTap: toggleBuzzer,
        child: Container(
          width: 45.r,
          height: 45.r,
          decoration: BoxDecoration(
            color: isBuzzerOn
                ? Colors.redAccent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: isBuzzerOn ? Colors.redAccent : Colors.white24,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.campaign,
            color: isBuzzerOn ? Colors.redAccent : Colors.white54,
            size: 22.r,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------
// 2. SİSTEM TUŞLARI (Harita & Senaryo - Aynen Kalıyor)
// ---------------------------------------------------
class FeatureButtons extends StatelessWidget {
  const FeatureButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionBtn(Icons.route, "Senaryo", Colors.purpleAccent),
        SizedBox(width: 10.w),
        _buildActionBtn(Icons.map, "Harita", Colors.orangeAccent),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18.r),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
