import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'log_manager.dart'; // <--- LogManager'ı buradan çağırıyoruz
import 'joystick_settings.dart';

// --- AYAR YÖNETİCİSİ ---
class SettingsManager {
  static final ValueNotifier<double> joystickScaleNotifier = ValueNotifier(1.0);

  static void setJoystickScale(double newValue) {
    joystickScaleNotifier.value = newValue;
  }
}

// --- ANA AYARLAR MENÜSÜ ---
class AgvSettingsPage extends StatelessWidget {
  const AgvSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Ayarlar",
          style: TextStyle(fontSize: 20.sp, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
          child: ListView(
            children: [
              Text(
                "Genel",
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
              SizedBox(height: 10.h),

              // 1. JOYSTICK BUTONU (Aşağıdaki sayfaya gider)
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

              // 2. SİSTEM LOGLARI BUTONU (LogManager içindeki sayfaya gider)
              _buildSettingsTile(
                context,
                icon: Icons.terminal,
                title: "Sistem Logları",
                subtitle: "Veri akışı ve hata kayıtları",
                onTap: () {
                  // BURASI ÖNEMLİ: log_manager.dart içindeki sayfayı açıyor
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogViewerPage(),
                    ),
                  );
                },
              ),

              SizedBox(height: 15.h),

              // 3. HAKKINDA BUTONU
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
}
