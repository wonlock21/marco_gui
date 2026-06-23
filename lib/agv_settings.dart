import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'joystick_settings.dart';
import 'log_manager.dart';
import 'services/agv_native_bridge.dart';
import 'services/connection_controller.dart';
import 'services/telemetry_mock_provider.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';
import 'widgets/agv_panel.dart';

class SettingsManager {
  static final ValueNotifier<double> joystickScaleNotifier = ValueNotifier(1.0);

  static void setJoystickScale(double newValue) {
    joystickScaleNotifier.value = newValue;
  }
}

class AgvSettingsPage extends StatefulWidget {
  const AgvSettingsPage({super.key});

  @override
  State<AgvSettingsPage> createState() => _AgvSettingsPageState();
}

class _AgvSettingsPageState extends State<AgvSettingsPage> {
  final _bridge = AgvNativeBridge.instance;
  final _connection = ConnectionController.instance;

  bool isLightOn = false;
  bool isFanOn = false;

  void setDeviceState(String device, bool newState) {
    String cmdToSend = '';

    if (device == 'light') {
      setState(() => isLightOn = newState);
      cmdToSend = newState ? 'I_AC' : 'I_KAPA';
    } else if (device == 'fan') {
      setState(() => isFanOn = newState);
      cmdToSend = newState ? 'F_AC' : 'F_KAPA';
    }

    _bridge.sendAccessory(cmdToSend).catchError((e) {
      debugPrint('Ayar Hatası: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AYARLAR')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            children: [
              _sectionLabel('DONANIM'),
              SizedBox(height: 8.h),
              _SwitchTile(
                icon: Icons.lightbulb,
                title: 'Farlar',
                subtitle: 'Ön aydınlatmaları aç/kapat',
                value: isLightOn,
                activeColor: AgvColors.light,
                onChanged: (val) => setDeviceState('light', val),
              ),
              SizedBox(height: 8.h),
              _SwitchTile(
                icon: Icons.air,
                title: 'Soğutma Fanı',
                subtitle: 'Sistem fanını aktif et',
                value: isFanOn,
                activeColor: AgvColors.fan,
                onChanged: (val) => setDeviceState('fan', val),
              ),

              SizedBox(height: 24.h),
              _sectionLabel('GENEL'),
              SizedBox(height: 8.h),
              _SwitchTile(
                icon: Icons.sync,
                title: 'Otomatik Yeniden Bağlan',
                subtitle: 'Bağlantı koptuğunda son cihaza tekrar dene',
                value: _connection.autoReconnectEnabled,
                activeColor: AgvColors.accent,
                onChanged: (val) {
                  setState(() {
                    _connection.autoReconnectEnabled = val;
                  });
                },
              ),
              SizedBox(height: 8.h),
              AgvTile(
                icon: Icons.gamepad,
                title: 'Joystick Yapılandırması',
                subtitle: 'Boyut ve hassasiyet ayarları',
                iconColor: AgvColors.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JoystickSettingsView(),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              AgvTile(
                icon: Icons.terminal,
                title: 'Sistem Logları',
                subtitle: 'Veri akışı ve hata kayıtları',
                iconColor: AgvColors.info,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogViewerPage(),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              _sectionLabel('GELİŞTİRİCİ'),
              SizedBox(height: 8.h),
              ValueListenableBuilder<bool>(
                valueListenable: TelemetryMockProvider.instance.enabled,
                builder: (context, mockOn, _) {
                  return _SwitchTile(
                    icon: Icons.bug_report,
                    title: 'Mock Telemetri',
                    subtitle: 'Firmware verisi yokken simüle akış üret',
                    value: mockOn,
                    activeColor: AgvColors.autonomy,
                    onChanged: (val) =>
                        TelemetryMockProvider.instance.setEnabled(val),
                  );
                },
              ),
              SizedBox(height: 8.h),
              AgvTile(
                icon: Icons.info_outline,
                title: 'Uygulama Hakkında',
                subtitle: 'Versiyon 0.1.0',
                iconColor: AgvColors.textMuted,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(text, style: AgvTypography.sectionLabel),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AgvDecorations.solidPanel(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: (value ? activeColor : AgvColors.textMuted)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: value ? activeColor : AgvColors.textMuted,
              size: 20.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AgvTypography.tileTitle),
                SizedBox(height: 2.h),
                Text(subtitle, style: AgvTypography.tileSubtitle),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
          ),
        ],
      ),
    );
  }
}
