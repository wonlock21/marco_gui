import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/agv_native_bridge.dart';
import 'services/connection_controller.dart';

class BluetoothButton extends StatefulWidget {
  const BluetoothButton({super.key});

  @override
  State<BluetoothButton> createState() => _BluetoothButtonState();
}

class _BluetoothButtonState extends State<BluetoothButton> {
  final _bridge = AgvNativeBridge.instance;
  final _connection = ConnectionController.instance;

  void _onFabPressed() async {
    if (_connection.state.value.isConnected) {
      _showSnack(
        "Zaten bağlısın! (Basılı tutup kesebilirsin)",
        Colors.blueGrey,
      );
      return;
    }

    await _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    var scanStatus = await Permission.bluetoothScan.status;
    var connectStatus = await Permission.bluetoothConnect.status;
    var locationStatus = await Permission.location.status;

    if ((scanStatus.isGranted && connectStatus.isGranted) ||
        locationStatus.isGranted) {
      _showDeviceList();
      return;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    bool connectGranted =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    bool locationGranted = statuses[Permission.location]?.isGranted ?? false;

    if ((scanGranted && connectGranted) || locationGranted) {
      _showDeviceList();
    } else {
      _showSnack("İzin vermezsen Lift Ant'ı bulamayız!", Colors.redAccent);
    }
  }

  void _showDeviceList() async {
    try {
      final List<dynamic> devices = await _bridge
          .getPairedDevices()
          .onError((error, stackTrace) {
            debugPrint('getPairedDevices Error: $error');
            return <dynamic>[];
          });

      if (!mounted) return;

      if (devices.isEmpty) {
        _showSnack(
          "Etrafta hiç kayıtlı cihaz yok! Ayarlardan eşleştir.",
          Colors.orange,
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) {
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
                    color: Colors.black,
                  ),
                ),
                const Divider(),
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
                          Navigator.pop(context);
                          _connectToDevice(device['address']);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showSnack("Liste hatası: ${e.toString()}", Colors.red);
    }
  }

  Future<void> _connectToDevice(String address) async {
    try {
      await _connection.connect(address);
      if (!mounted) return;
      _showSnack("BAĞLANDI! Lift Ant emrinizde. 🚀", Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnack("HATA: Bağlanamadı. (${e.toString()})", Colors.redAccent);
    }
  }

  Future<void> _disconnect() async {
    await _connection.disconnect();
    if (!mounted) return;
    _showSnack("Bağlantı kesildi.", Colors.orange);
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
    return ValueListenableBuilder<AgvConnectionState>(
      valueListenable: _connection.state,
      builder: (context, conn, _) {
        final isConnected = conn.isConnected;
        final isLoading = conn.isConnecting;

        return GestureDetector(
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
      },
    );
  }
}
