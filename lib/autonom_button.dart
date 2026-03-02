import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'log_manager.dart';

class AutonomusButton extends StatefulWidget {
  const AutonomusButton({super.key});
  @override
  State<AutonomusButton> createState() => _AutonomusButtonState();
}

class _AutonomusButtonState extends State<AutonomusButton> {
  static const channel = MethodChannel('agv/native');
  bool isAuto = false;
  void toggleMode() {
    setState(() {
      isAuto = !isAuto;
    });

    // Native tarafa mod bilgisini yolluyoruz
    channel.invokeMethod('setMode', {'isAuto': isAuto});

    // Log ekranına yazdır
    LogManager.addLog(isAuto ? "MOD: OTONOM" : "MOD: MANUEL");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleMode,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isAuto
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isAuto ? Colors.greenAccent : Colors.redAccent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAuto ? Icons.smart_toy : Icons.front_hand,
              color: isAuto ? Colors.greenAccent : Colors.redAccent,
              size: 24.r,
            ),
            SizedBox(width: 10.w),
            Text(
              isAuto ? "OTONOM" : "MANUEL",
              style: TextStyle(
                color: isAuto ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
