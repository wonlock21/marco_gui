import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'log_manager.dart';
import 'agv_settings.dart'; // <--- 1. AYARLARI İÇERİ ALDIK

class Joystick extends StatefulWidget {
  // Dışarıdan gelen "Kamera açık mı?" bilgisini alıyoruz
  final bool isCameraOn;

  const Joystick({super.key, this.isCameraOn = false});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  // Native kanal (MainActivity.kt ile konuşur)
  static const channel = MethodChannel('agv/native');

  // Offset kendisi x y axisleri oluşturuyor. böylece pisagor teoremiyle uğraşmaya gerek kalmıyor
  Offset offset = Offset.zero;

  // Joystick boyutunu ayarladık (.r ile ekrana göre orantılı)
  // DEĞİŞİKLİK: Bu değerleri artık build içinde ekran boyutuna göre hesaplayacağız
  late double radius;
  // Hassasiyet ölü bölgesi
  late double deadZone;
  // Hareketli topun boyutu (Eskiden 30.r idi)
  late double knobSize;

  // Spam engelleme (Saniyede ~25 paket limiti)
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  final int sendIntervalMs = 40;

  // Sadece son yönü tutuyoruz (Değişiklik kontrolü için)
  int _lastDir = 999;

  // Çaprazlar eklendi. Toplam 8 ana yön ve Dur komutu var.
  final Map<int, String> agvLabels = {
    -1: "DUR:0",
    0: "SAĞ:2", // Kotlin: RIGHT
    1: "SAĞ_İLERİ:12", // Kotlin: UP_RIGHT
    2: "İLERİ:1", // Kotlin: UP
    3: "SOL_İLERİ:41", // Kotlin: UP_LEFT
    4: "SOL:4", // Kotlin: LEFT
    5: "SOL_GERİ:34", // Kotlin: DOWN_LEFT
    6: "GERİ:3", // Kotlin: DOWN
    7: "SAĞ_GERİ:23", // Kotlin: DOWN_RIGHT
  };

  // nativeye gönderilecekleri ayarlıyoruz, kodumda native backend kullandım.
  // native kodlarını görmek için MainActivity.kt dosyasına bakın.
  void sendToNative(Offset o) {
    // 1. DEADZONE (DUR)
    if (o.distance < deadZone) {
      if (_lastDir != -1) {
        _lastDir = -1;
        debugPrint('DUR komutu gönderildi.');

        // Log dosyasına gönderiyoruz (Sözlükten çekerek)
        LogManager.addLog(agvLabels[-1]!);

        // Sadece dur (-1) diyoruz, güç yok
        channel.invokeMethod('joystick', {'dir': -1});
      }
      return;
    }

    // 2. SPAM ENGELLEME (Throttle)
    final now = DateTime.now();
    if (now.difference(_lastSend).inMilliseconds < sendIntervalMs) {
      return;
    }
    _lastSend = now;

    // 3. YÖN HESABI (0-360 Derece -> 8 Ana Yön)
    // 360 dereceyi 45 derecelik 8 dilime bölüyoruz.
    double angle = atan2(-o.dy, o.dx) * 180 / pi;
    if (angle < 0) angle += 360;

    // 0'dan 7'ye kadar yön indeksleri çıkıyor
    int direction = ((angle + 22.5) / 45).floor() % 8;

    // 4. DEĞİŞİKLİK KONTROLÜ
    // yön değişmediyse tekrar aynı komutu göndermeyecek
    if (direction == _lastDir) {
      return;
    }

    _lastDir = direction;
    // Native tarafa sadece "dir" gönderiyoruz

    // Log dosyasına gönderiyoruz komutları
    String logMsg = agvLabels[direction] ?? "BİLİNMEYEN:$direction";
    LogManager.addLog(logMsg);

    channel.invokeMethod('joystick', {'dir': direction}).catchError((e) {
      debugPrint('Joystick Native Hata Test Modundan Cikart: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    // <--- 2. BURAYA DİNLEYİCİ EKLEDİK (Tüm build'i sarmaladık)
    return ValueListenableBuilder<double>(
      valueListenable: SettingsManager.joystickScaleNotifier,
      builder: (context, scale, child) {
        // Ekranın yüksekliğini alıp oranlıyoruz.
        double screenHeight = MediaQuery.of(context).size.height;

        // <--- 3. KRİTİK HAMLE: Senin %18 oranını 'scale' (ayar) ile çarptık
        radius = (screenHeight * 0.18) * scale;

        deadZone = radius * 0.05; // Radius'un %5'i kadar ölü bölge
        knobSize = radius * 0.5; // Topun boyutu radius'un yarısı
        // -------------------------

        // Görsel efekt için strength hesaplıyorum joystick ilerledikçe renk değiştirecek. backendde kullanmıyoruz ama olsun.
        final double strength = (offset.distance / radius).clamp(0.0, 1.0);

        // Renk (Mavi → Kırmızı geçişli)
        final Color knobColor = Color.fromARGB(
          255,
          (150 * strength).toInt(),
          0,
          (150 * (1 - strength)).toInt(),
        );

        // BURASI JOYSTICKIN EN ONEMLI NOKTASI
        return GestureDetector(
          onPanUpdate: (details) {
            // onPanUpdate ile joysticke dokunulduğunda ne yapacağını belirtiroyruz.
            // burada details.delta ile delta(değişim) miktarını var olan konuma ekleyip yeni konumunu buluyoruz joystickin.
            Offset next = offset + details.delta;

            // Bu if bloğuyla beraber joystickin ekranın dışına çıkmasını engelliyoruz
            if (next.distance > radius) {
              // Eğer hesapladığın yeni yer (next), çemberin sınırından (radius) daha uzaktaysa açıyı bozmadan mesafeyi kısaltıyoruz.
              next = Offset.fromDirection(next.direction, radius);
            }

            // setstate yaptık ekranı yeniden boyatıp joystickin güncel konumunu gösteriyoruz.
            setState(() => offset = next);
            // kordinatı da nativeye gönderiyoruz.(backende)
            sendToNative(offset);
          },
          onPanEnd: (_) {
            // burası parmağı joystickten çektiğimizde çalışıyor.
            // parmak çekildiği anda offset zero olarak ayarlanıyor.
            setState(() => offset = Offset.zero);
            // nativeye haber gidiyor.
            sendToNative(Offset.zero);
          },
          child: Container(
            // joysticki barındıracak çemberin boyutunu belirledim
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Kamera açıksa beyazımsı, değilse eski şeffaf siyah
              color: widget.isCameraOn
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
              boxShadow: widget.isCameraOn
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: 0.2,
                        ), // Güncellendi
                        blurRadius: 20, // .r sildik
                        spreadRadius: 2, // .r sildik
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center, // joysticki merkeze yerleştirdim
              children: [
                // İç feedback çemberi
                Container(
                  // burada kontrol çemberi tarzı bir şey ekledim çemberin içine ikincil bir çember.
                  width: radius * 1.4,
                  height: radius * 1.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.05), // Güncellendi
                  ),
                ),
                // Hareketli Joystick Topu
                Transform.translate(
                  // Transform.translate sayesinde hareketli yapıyoruz
                  // onPanUpdatede hesapladığımız verileri buraya veriyoruz
                  offset: offset,
                  child: Container(
                    // genişlik bilgileri (artık dinamik knobSize)
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // rengini ayarladık, rengi çektikçe kırmızıya kayıyor
                      color: knobColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.3,
                          ), // Güncellendi
                          blurRadius: 5, // .r sildik
                          offset: Offset(2, 2), // .w ve .h sildik
                        ),
                      ],
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
