import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //MethodChannel için gerekli
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BluetoothButton extends StatefulWidget {
  // Ana sayfaya (GamePage) haber vermek için bir telgraf hattı (Callback)
  final Function(bool) onConnectionChanged;

  const BluetoothButton({super.key, required this.onConnectionChanged});

  @override
  State<BluetoothButton> createState() => _BluetoothButtonState();
}

class _BluetoothButtonState extends State<BluetoothButton> {
  // Native tarafla konuşacak kanal
  static const channel = MethodChannel('agv/native');

  // Bağlantı durumu ve yükleniyor animasyonu için değişkenler. Bluetooth bağlanınca falan renk değişmesi için
  bool isConnected = false;
  bool isLoading = false;

  void _connectBluetooth() async {
    // Zaten bağlıysa tekrar deneme
    if (isConnected) {
      _showSnack("Zaten bağlısın kaptan! 🫡", Colors.blueGrey);
      return;
    }

    setState(
      () => isLoading = true,
    ); // hala bağlanmaya çalışıyorsa isLoading kısmında devam ediyor.

    try {
      // Native tarafa bağlan emri veriyoruz ve sonucu bekliyoruz
      final bool result = await channel.invokeMethod('connect');
      //burda flutter nativeye bluetootha bağlanma emrini verdiği yer
      //await sayesinde cevap gelene kadar bekliyoruz

      if (mounted) {
        //mounted ile şuanda telefon ekranında açık olup olmadığı kontrol ediliyo uygulama çökmesin diye. örneğin yanlışıkla bluetooth bağlarken uygulamadan çıktın geri geldiğinde uygulama setstate yüzünden çökmemiş olacak
        setState(() {
          isConnected = result; // Sonucu kaydet (true ise yeşil olacak)
          isLoading = false; // Loadingi durdur
        });

        // KRİTİK NOKTA: Sonucu GamePage'e bildiriyoruz
        widget.onConnectionChanged(result);

        if (result) {
          //eğer sonuç başarılıysa bağlandı diye mesaj vericez
          _showSnack("BAĞLANDI! Lift Ant emrinizde. 🚀", Colors.green);
        }
      }
    } catch (e) {
      //eğer bağlantı başarısızsa buraya giriyoruz
      if (mounted) {
        //yine uygulama çökmesin diye var. kullanıcı uygulama ekranında değilse bile uygulama çökmez.
        setState(() {
          isConnected =
              false; //setstate ile bağlı olmadığını belirtiyoruz ekranda ve loading kısmını sıfırlıyoruz
          isLoading = false;
        });
        // Hata durumunda da GamePage'e false bilgisini geçelim
        widget.onConnectionChanged(false);

        _showSnack(
          "HATA: Bağlanamadı. (${e.toString()})",
          Colors.redAccent,
        ); //hata çıktısı veriyoruz
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ), //burada popup mesajlar için bir fonksiyon oluşturum kod kalabalığı azalsın diye
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Butonun tasarımı tamamen burada
    return FloatingActionButton.small(
      heroTag: "btn_bluetooth",
      onPressed: isLoading ? null : _connectBluetooth,
      backgroundColor: isConnected
          ? Colors.green
          : Colors.indigo, //bt bağlıysa yeşil değilse indigo
      child: isLoading
          ? Padding(
              padding: EdgeInsets.all(8.r),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.r,
              ),
            )
          : Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: Colors.white,
              size: 20.r,
            ),
    );
  }
}
