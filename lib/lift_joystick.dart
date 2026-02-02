import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'agv_settings.dart'; // SettingsManager için

class LiftJoystick extends StatefulWidget {
  const LiftJoystick({super.key});

  @override
  State<LiftJoystick> createState() => _LiftJoystickState();
}

class _LiftJoystickState extends State<LiftJoystick> {
  static const channel = MethodChannel('agv/native');

  Offset offset = Offset.zero;

  // Joystick Boyutları (Build içinde hesaplanacak)
  late double radius;
  late double knobSize;
  late double deadZone;

  // Son gönderilen komut (Spam engellemek için)
  int _lastCommand = 0; // 0: Dur, 1: Yukarı, -1: Aşağı
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  final int sendIntervalMs = 50; // 50ms araya gönderme

  void sendLiftCommand(Offset o) {
    try {
      // Değer kontrolü
      if (o.dy.isNaN || o.dx.isNaN || radius.isNaN || deadZone.isNaN) {
        debugPrint("Lift: NaN değer algılandı, gönderim atlanıyor");
        return;
      }

      // Spam kontrolü
      final now = DateTime.now();
      if (now.difference(_lastSend).inMilliseconds < sendIntervalMs) {
        return;
      }

      // 1. ÖLÜ BÖLGE KONTROLÜ (DURMA)
      if (o.distance < deadZone) {
        if (_lastCommand != 0) {
          _lastCommand = 0;
          _lastSend = now;
          channel.invokeMethod('lift', {'action': 0}).catchError((e) {
            debugPrint("Lift DUR komutu hatası: $e");
          });
          debugPrint("Lift: DUR");
        }
        return;
      }

      // 2. YÖN BELİRLEME (Sadece Yukarı veya Aşağı)
      // dy negatifse yukarı (1), pozitifse aşağı (-1)
      int currentCommand = (o.dy < 0) ? 1 : -1;

      // 3. DEĞİŞİKLİK VARSA GÖNDER
      if (currentCommand != _lastCommand) {
        _lastCommand = currentCommand;
        _lastSend = now;
        channel.invokeMethod('lift', {'action': currentCommand}).catchError((
          e,
        ) {
          debugPrint("Lift komutu hatası: $e");
        });
        debugPrint("Lift: ${currentCommand == 1 ? 'YUKARI' : 'AŞAĞI'}");
      }
    } catch (e) {
      debugPrint("Lift Joystick Critical Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ayarlardan gelen boyutu dinliyoruz
    return ValueListenableBuilder<double>(
      valueListenable: SettingsManager.joystickScaleNotifier,
      builder: (context, scale, child) {
        // Ana joystick ile aynı orantıyı kullanıyoruz
        double screenHeight = MediaQuery.of(context).size.height;
        radius = (screenHeight * 0.18) * scale;
        deadZone = radius * 0.1; // %10 ölü bölge
        knobSize = radius * 0.5;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // --- KİLİT NOKTA BURASI ---
              // dx (yatay) hareketini SIFIRLIYORUZ. Sadece dy (dikey) alıyoruz.
              double newY = offset.dy + details.delta.dy;

              // Sınırların dışına çıkmasını engelle (Clamp)
              // Çemberin yarıçapı kadar yukarı veya aşağı gidebilir
              newY = newY.clamp(-radius, radius);

              // Yatay (x) her zaman 0, Dikey (y) hareketli
              offset = Offset(0, newY);
            });
            sendLiftCommand(offset);
          },
          onPanEnd: (_) {
            // Bırakınca merkeze dön
            setState(() => offset = Offset.zero);
            sendLiftCommand(Offset.zero);
          },
          child: Container(
            // İnce uzun bir yol görünümü verelim (Slider gibi)
            width: knobSize * 1.5,
            height: radius * 2.2,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(color: Colors.white10, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dikey Kılavuz Çizgisi
                Container(
                  width: 2.w,
                  height: radius * 1.8,
                  color: Colors.white24,
                ),
                // Hareketli Top
                Transform.translate(
                  offset: offset,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Lift için farklı renk (Örn: Turuncu)
                      color: Colors.orangeAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      // Simge yukarı/aşağı/dur durumuna göre değişsin
                      offset.dy < -deadZone
                          ? Icons.arrow_upward
                          : (offset.dy > deadZone
                                ? Icons.arrow_downward
                                : Icons.unfold_more),
                      color: Colors.black,
                      size: 20.r,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
