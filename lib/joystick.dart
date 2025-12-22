import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class Joystick extends StatefulWidget {
  const Joystick({super.key});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  // Native kanal (MainActivity.kt ile konuşur)
  static const channel = MethodChannel('agv/native');

  Offset offset = Offset
      .zero; //Offset kendisi x y axisleri oluşturuyor. böylece pisagor teoremiyle uğraşmaya gerek kalmıyor
  final double radius = 60; // Joystick boyutunu ayarladık
  final double deadZone = 6; // Hassasiyet ölü bölgesi

  // Spam engelleme (Saniyede ~25 paket limiti)
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  final int sendIntervalMs = 40;

  // Sadece son yönü tutuyoruz (Değişiklik kontrolü için)
  int _lastDir = 999;

  //nativeye gönderilecekleri ayarlıyoruz, kodumda native backend kullandım.
  //native kodlarını görmek için MainActivity.kt dosyasına bakın.
  void sendToNative(Offset o) {
    // 1. DEADZONE (DUR)
    if (o.distance < deadZone) {
      if (_lastDir != -1) {
        _lastDir = -1;
        debugPrint('DUR komutu gönderildi.');
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

    // 3. YÖN HESABI (0-360 Derece -> 0-7 Yön)
    //nativeye 0 ile 7 arasında sayı göndericem ona göre makinaya bunlar gönderilecek ve makina hareket edecek
    double angle = atan2(-o.dy, o.dx) * 180 / pi;
    if (angle < 0) angle += 360;

    int direction = ((angle + 22.5) / 45).floor() % 8;

    // 4. DEĞİŞİKLİK KONTROLÜ
    // yön değişmediyse tekrar aynı komutu göndermeyecek
    if (direction == _lastDir) {
      return;
    }

    _lastDir = direction;

    // Native tarafa sadece "dir" gönderiyoruz
    channel.invokeMethod('joystick', {'dir': direction});
  }

  @override
  Widget build(BuildContext context) {
    // Görsel efekt için strength hesaplıyorum joystick ilerledikçe renk değiştirecek. backendde kullanmıyoruz ama olsun.
    final double strength = (offset.distance / radius).clamp(0.0, 1.0);

    // Renk (Mavi → Kırmızı geçişli)
    final Color knobColor = Color.fromARGB(
      255,
      (150 * strength).toInt(),
      0,
      (150 * (1 - strength)).toInt(),
    );

    //BURASI JOYSTICKIN EN ONEMLI NOKTASI
    return GestureDetector(
      onPanUpdate: (details) {
        //onPanUpdate ile joysticke dokunulduğunda ne yapacağını belirtiroyruz.
        Offset next =
            offset +
            details
                .delta; //burada details.delta ile delta(değişim) miktarını var olan konuma ekleyip yeni konumunu buluyoruz joystickin.

        if (next.distance > radius) {
          //Bu if bloğuyla beraber joystickin ekranın dışına çıkmasını engelliyoruz
          next = Offset.fromDirection(next.direction, radius);
        } //Eğer hesapladığın yeni yer (next), çemberin sınırından (radius) daha uzaktaysa açıyı bozmadan mesafeyi kısaltıyoruz.

        setState(
          () => offset = next,
        ); //setstate yaptık ekranı yeniden boyatıp joystickin güncel konumunu gösteriyoruz.
        sendToNative(offset); //kordinatı da nativeye gönderiyoruz.(backende)
      },
      onPanEnd: (_) {
        //burası parmağı joystickten çektiğimizde çalışıyor.
        setState(
          () => offset = Offset.zero,
        ); //parmak çekildiği anda offset zero olarak ayarlanıyor.
        sendToNative(Offset.zero); //nativeye haber gidiyor.
      },
      child: Container(
        width: radius * 2, //joysticki barındıracak çemberin boyutunu belirledim
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Eğer withValues hata verirse yerine .withOpacity(0.15) yazabilirsin
          color: Colors.black.withValues(alpha: 0.15),
        ),
        child: Stack(
          alignment: Alignment.center, //joysticki merkeze yerleştirdim
          children: [
            // İç feedback çemberi
            Container(
              width:
                  radius *
                  1.4, //burada kontrol çemberi tarzı bir şey ekledim çemberin içine ikincil bir çember.
              height: radius * 1.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            // Hareketli Joystick Topu
            Transform.translate(
              //Transform.translate sayesinde hareketli yapıyoruz
              offset:
                  offset, //onPanUpdatede hesapladığımız verileri buraya veriyoruz
              child: Container(
                width: 31, //genişlik bilgileri
                height: 31,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      knobColor, //rengini ayarladık, rengi çektikçe kırmızıya kayıyor
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
