import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'log_manager.dart';
import 'joystick_settings.dart';
import 'services/agv_native_bridge.dart';
import 'services/connection_controller.dart';
// --- AYAR YÖNETİCİSİ ---
class SettingsManager {
  static final ValueNotifier<double> joystickScaleNotifier = ValueNotifier(1.0);

  static void setJoystickScale(double newValue) {
    joystickScaleNotifier.value = newValue;
  }
}

// --- ANA AYARLAR MENÜSÜ ---
class AgvSettingsPage extends StatefulWidget {
  const AgvSettingsPage({super.key});

  @override
  State<AgvSettingsPage> createState() => _AgvSettingsPageState();
}

class _AgvSettingsPageState extends State<AgvSettingsPage> {
  final _bridge = AgvNativeBridge.instance;
  final _connection = ConnectionController.instance;
  // Donanım durumları
  bool isLightOn = false;
  bool isFanOn = false;

  void setDeviceState(String device, bool newState) {
    String cmdToSend = "";

    if (device == "light") {
      setState(() {
        isLightOn = newState;
      });
      cmdToSend = newState ? "I_AC" : "I_KAPA";
    } else if (device == "fan") {
      setState(() {
        isFanOn = newState;
      });
      cmdToSend = newState ? "F_AC" : "F_KAPA";
    }

    // Komutu fırlat
    _bridge.sendAccessory(cmdToSend).catchError((e) {
      debugPrint("Ayar Hatası: $e");
    });  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Ayarlar",
          style: TextStyle(
            fontSize: 20.sp,
            letterSpacing: 0.2,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 0.h),
          child: ListView(
            children: [
              // ---------------------------------------------
              // DONANIM KISMI (Yeni Eklenen)
              // ---------------------------------------------
              Text(
                "Donanım",
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
              SizedBox(height: 10.h),

              _buildSwitchTile(
                icon: Icons.lightbulb,
                title: "Farlar",
                subtitle: "Ön aydınlatmaları aç/kapat",
                value: isLightOn,
                activeColor: Colors.yellow,
                onChanged: (val) => setDeviceState("light", val),
              ),
              SizedBox(height: 15.h),

              _buildSwitchTile(
                icon: Icons.lightbulb,
                title: "Soğutma Fanı",
                subtitle: "Sistem fanını aktif et",
                value: isFanOn,
                activeColor: Colors.cyan,
                onChanged: (val) => setDeviceState("fan", val),
              ),

              SizedBox(height: 30.h),

              // ---------------------------------------------
              // GENEL KISMI (Senin Eski Kodların)
              // ---------------------------------------------
              Text(
                "Genel",
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
              SizedBox(height: 10.h),

              _buildSwitchTile(
                icon: Icons.sync,
                title: "Otomatik Yeniden Bağlan",
                subtitle: "Bağlantı koptuğunda son cihaza tekrar dene",
                value: _connection.autoReconnectEnabled,
                activeColor: Colors.tealAccent,
                onChanged: (val) {
                  setState(() {
                    _connection.autoReconnectEnabled = val;
                  });
                },
              ),
              SizedBox(height: 15.h),

              _buildSettingsTile(
                context,
                icon: Icons.gamepad,
                title: "Joystick Yapılandırması",
                subtitle: "Boyut ve hassasiyet ayarları",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoystickSettingsView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 15.h),

              _buildSettingsTile(
                context,
                icon: Icons.terminal,
                title: "Sistem Logları",
                subtitle: "Veri akışı ve hata kayıtları",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogViewerPage(),
                    ),
                  );
                },
              ),
              SizedBox(height: 15.h),

              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: "Uygulama Hakkında",
                subtitle: "Versiyon 1.0",
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SENİN ESKİ YÖNLENDİRME TASARIMIN
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        leading: Icon(icon, color: Colors.greenAccent, size: 28.r),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16.r,
        ),
        onTap: onTap,
      ),
    );
  }

  // YENİ EKLENEN AÇ/KAPA (SWITCH) TASARIMI
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white12),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        secondary: Icon(
          icon,
          color: value ? activeColor : Colors.white54,
          size: 28.r,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
        ),
        value: value,
        activeThumbColor: activeColor,
        onChanged: onChanged,
      ),
    );
  }
}
