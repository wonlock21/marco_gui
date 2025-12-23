import 'package:flutter/material.dart';
import 'background.dart';
import 'joystick.dart';
import 'package:flutter/services.dart'; //MethodChannel için gerekli

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // Native tarafla konuşacak kanal
  static const channel = MethodChannel('agv/native');

  // Bağlantı durumu ve yükleniyor animasyonu için değişkenler. Bluetooth bağlanınca falan renk değişmesi için
  bool isConnected = false;
  bool isLoading = false;

  void _connectBluetooth() async {
    // Zaten bağlıysa tekrar deneme
    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Zaten bağlısın kaptan! 🫡"),
        ), //bluetooth bağlantısı çoktan yapıldıysa ve tekrar
      ); //bağlanmaya çalışılıyorsa zaten bağlısın çıktısı veriliyor.
      return; //eğer çalıştıysa bu fonksiyon bitiriliyor.
    }

    setState(() {
      isLoading =
          true; // hala bağlanmaya çalışıyorsa isLoading kısmında devam ediyor.
    });

    try {
      // Native tarafa bağlan emri veriyoruz ve sonucu bekliyoruz
      final bool result = await channel.invokeMethod(
        'connect',
      ); //burda flutter nativeye bluetootha bağlanma emrini verdiği yer
      //await sayesinde cevap gelene kadar bekliyoruz

      if (mounted) {
        //mounted ile şuanda telefon ekranında açık olup olmadığı kontrol ediliyo uygulama çökmesin diye. örneğin yanlışıkla bluetooth bağlarken uygulamadan çıktın geri geldiğinde uygulama setstate yüzünden çökmemiş olacak
        setState(() {
          isConnected = result; // Sonucu kaydet (true ise yeşil olacak)
          isLoading = false; // Dönme dolabı durdur
        });

        if (result) {
          //eğer sonuç başarılıysa bağlandı diye mesaj vericez
          // BAŞARILI MESAJI
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("BAĞLANDI! Lift Ant emrinizde. 🚀"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2), //2 saniye ekranda kalıyo bildirim
            ),
          );
        }
      }
    } catch (e) {
      //eğer bağlantı başarısızsa buraya giriyoruz
      // HATA MESAJI
      if (mounted) {
        //yine uygulama çökmesin diye var. kullanıcı uygulama ekranında değilse bile uygulama çökmez.
        setState(() {
          isConnected =
              false; //setstate ile bağlı olmadığını belirtiyoruz ekranda ve loading kısmını sıfırlıyoruz
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          //hata çıktısı veriyoruz
          SnackBar(
            content: Text("HATA: Bağlanamadı. (${e.toString()})"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Arka Plan
          const BackgroundColor(),

          // 2. Joystick (Tam Ortada)
          const Center(child: Joystick()),

          // 3. Bluetooth Butonu (Sağ Üst)
          Positioned(
            right: 20,
            top: 50,
            child: FloatingActionButton.small(
              onPressed: isLoading
                  ? null
                  : _connectBluetooth, // Yüklenirken basılamaz
              // Bağlıysa YEŞİL, Değilse İNDIGO, Yükleniyorsa GRİ
              backgroundColor: isConnected ? Colors.green : Colors.indigo,
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      color: Colors.white,
                    ),
            ),
          ),

          // 4. Durum Yazısı (Sol Üst)
          Positioned(
            left: 20,
            top: 60,
            child: Text(
              isConnected ? "BAĞLI: Lift Ant" : "BAĞLANTI YOK",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isConnected ? Colors.greenAccent : Colors.white70,
                shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
