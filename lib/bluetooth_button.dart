import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/agv_native_bridge.dart';
import 'services/connection_controller.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';

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
        'Zaten bağlısın (basılı tutarak kesebilirsin)',
        AgvColors.info,
      );
      return;
    }

    await _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    final locationStatus = await Permission.location.status;

    if ((scanStatus.isGranted && connectStatus.isGranted) ||
        locationStatus.isGranted) {
      _showDeviceList();
      return;
    }

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectGranted =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationGranted = statuses[Permission.location]?.isGranted ?? false;

    if ((scanGranted && connectGranted) || locationGranted) {
      _showDeviceList();
    } else {
      _showSnack('İzin vermezsen AGV bulunamaz', AgvColors.danger);
    }
  }

  void _showDeviceList() async {
    try {
      final devices = await _bridge.getPairedDevices().onError(
        (error, stackTrace) {
          debugPrint('getPairedDevices Error: $error');
          return <dynamic>[];
        },
      );

      if (!mounted) return;

      if (devices.isEmpty) {
        _showSnack(
          'Etrafta kayıtlı cihaz yok — ayarlardan eşleştir',
          AgvColors.warning,
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AgvColors.surface,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          side: const BorderSide(color: AgvColors.borderSubtle),
        ),
        builder: (context) {
          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: AgvColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Icons.bluetooth_searching,
                        color: AgvColors.accent,
                        size: 16.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'EŞLEŞTİRİLMİŞ CİHAZLAR',
                        style: AgvTypography.sectionLabel,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: devices.length,
                      separatorBuilder: (_, _) => SizedBox(height: 6.h),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return _DeviceTile(
                          name: device['name'] ?? 'Bilinmeyen',
                          address: device['address'] ?? '',
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
            ),
          );
        },
      );
    } catch (e) {
      _showSnack('Liste hatası: ${e.toString()}', AgvColors.danger);
    }
  }

  Future<void> _connectToDevice(String address) async {
    try {
      await _connection.connect(address);
      if (!mounted) return;
      _showSnack('Bağlandı — AGV emrinizde', AgvColors.accent);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Bağlanamadı (${e.toString()})', AgvColors.danger);
    }
  }

  Future<void> _disconnect() async {
    await _connection.disconnect();
    if (!mounted) return;
    _showSnack('Bağlantı kesildi', AgvColors.warning);
  }

  void _showSnack(String message, Color accent) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(width: 4, height: 18, color: accent),
            SizedBox(width: 10.w),
            Expanded(child: Text(message)),
          ],
        ),
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
        final accent = isConnected
            ? AgvColors.accent
            : (isLoading ? AgvColors.warning : AgvColors.info);

        return Semantics(
          label: isConnected
              ? 'Bluetooth bağlı — basılı tutarak kes'
              : 'Bluetooth cihaz seç',
          button: true,
          child: GestureDetector(
            onLongPress: isConnected ? _disconnect : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : _onFabPressed,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AgvColors.surfaceElevated,
                    border: Border.all(color: accent, width: 1.5),
                    boxShadow: isConnected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: isLoading
                      ? Padding(
                          padding: EdgeInsets.all(10.r),
                          child: CircularProgressIndicator(
                            color: accent,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth,
                          color: accent,
                          size: 20.r,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.name,
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Ink(
          decoration: AgvDecorations.solidPanel(radius: 10),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: AgvColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.bluetooth,
                  color: AgvColors.accent,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AgvTypography.tileTitle),
                    SizedBox(height: 2.h),
                    Text(
                      address,
                      style: AgvTypography.mono(
                        size: 10.sp,
                        color: AgvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AgvColors.textMuted,
                size: 18.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
