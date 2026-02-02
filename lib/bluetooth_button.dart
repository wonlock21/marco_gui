import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // MethodChannel için gerekli
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart'; // İzin şefi

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

  // Bağlantı durumu ve yükleniyor animasyonu
  bool isConnected = false;
  bool isLoading = false;

  // --- BUTONA BASINCA İLK BURASI ÇALIŞIR ---
  void _onFabPressed() async {
    // Zaten bağlıysa tekrar deneme
    if (isConnected) {
      _showSnack(
        "Zaten bağlısın kaptan! 🫡 (Basılı tutup kesebilirsin)",
        Colors.blueGrey,
      );
      // İstersen buraya _disconnect() ekleyip bağlantıyı kesebilirsin.
      return;
    }

    // Bağlı değilsek akıllı izin kontrolüne git
    await _checkAndRequestPermissions();
  }

  // --- GÜNCELLENMİŞ İZİN KONTROL MERKEZİ ---
  Future<void> _checkAndRequestPermissions() async {
    // 1. ADIM: ÖNCE SADECE BAK (İSTEME)
    // Zaten izin verilmiş mi diye kontrol ediyoruz.
    var scanStatus = await Permission.bluetoothScan.status;
    var connectStatus = await Permission.bluetoothConnect.status;
    var locationStatus = await Permission.location.status;

    // Eğer ana izinler zaten cepteyse, kullanıcıyı darlama direkt listeyi aç.
    if ((scanStatus.isGranted && connectStatus.isGranted) ||
        locationStatus.isGranted) {
      _showDeviceList();
      return; // Fonksiyondan çık, aşağıya inip tekrar istemesin.
    }

    // 2. ADIM: İZİN YOKSA İSTE (Sadece ilk seferde buraya düşer)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // İzin istedikten sonraki durumlar
    bool scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    bool connectGranted =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    bool locationGranted = statuses[Permission.location]?.isGranted ?? false;

    if ((scanGranted && connectGranted) || locationGranted) {
      // İzinleri yeni aldık, listeyi getir.
      _showDeviceList();
    } else {
      // Israrla reddettiyse
      _showSnack(
        "İzin vermezsen Lift Ant'ı bulamayız kaptan! 🥺",
        Colors.redAccent,
      );
    }
  }

  // --- CİHAZ LİSTESİNİ GETİREN FONKSİYON (GÜNCELLENDİ: ARTIK KAYDIRILABİLİR) ---
  void _showDeviceList() async {
    try {
      // Native'den listeyi istiyoruz
      final List<dynamic> devices = await channel.invokeMethod(
        'getPairedDevices',
      );

      if (!mounted) return;

      if (devices.isEmpty) {
        _showSnack(
          "Etrafta hiç kayıtlı cihaz yok! Ayarlardan eşleştir.",
          Colors.orange,
        );
        return;
      }

      // Alttan çıkan menü (Bottom Sheet)
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true, // BU EKLENDİ: Ekran boyunu esnek kullanır
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) {
          // Listenin boyunu ekranın %70'i kadar yapıyoruz ki rahat sığsın
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Bir Cihaz Seçin",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        Colors.black, // Yazı rengini siyah yaptım görünsün diye
                  ),
                ),
                Divider(),

                // --- BURASI DEĞİŞTİ: LİSTE ARTIK KAYDIRILABİLİR (SCROLLABLE) ---
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.bluetooth,
                          color: Colors.indigo,
                        ),
                        title: Text(
                          device['name'] ?? "Bilinmeyen",
                          style: const TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          device['address'] ?? "",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Menüyü kapat
                          _connectToDevice(
                            device['address'],
                          ); // Seçilene bağlan
                        },
                      );
                    },
                  ),
                ),
                // -------------------------------------------------------------
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showSnack("Liste hatası: ${e.toString()}", Colors.red);
    }
  }

  // --- BAĞLANMA FONKSİYONU ---
  void _connectToDevice(String address) async {
    setState(() => isLoading = true);

    try {
      // Native tarafa adresi yollayıp bağlan diyoruz
      // Kotlin tarafında bu işlem Thread içinde yapıldığı için UI donmaz
      await channel.invokeMethod('connect', {'address': address});

      if (mounted) {
        setState(() {
          isConnected = true;
          isLoading = false;
        });

        // KRİTİK NOKTA: Sonucu GamePage'e bildiriyoruz
        widget.onConnectionChanged(true);

        _showSnack("BAĞLANDI! Lift Ant emrinizde. 🚀", Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnected = false;
          isLoading = false;
        });
        widget.onConnectionChanged(false);

        _showSnack("HATA: Bağlanamadı. (${e.toString()})", Colors.redAccent);
      }
    }
  }

  // --- KOPARMA FONKSİYONU (Backend destekliyor, lazım olursa kullanırsın) ---
  void _disconnect() async {
    try {
      await channel.invokeMethod('disconnect');
    } catch (e) {
      // Hata olsa bile UI'da koptu göster
    }
    if (mounted) {
      setState(() => isConnected = false);
      widget.onConnectionChanged(false);
      _showSnack("Bağlantı kesildi.", Colors.orange);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opsiyonel: Uzun basınca bağlantıyı kessin mi?
      onLongPress: isConnected ? _disconnect : null,
      child: FloatingActionButton.small(
        heroTag: "btn_bluetooth",
        onPressed: isLoading ? null : _onFabPressed,
        backgroundColor: isConnected ? Colors.green : Colors.indigo,
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
      ),
    );
  }
}
