import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/agv_mission_state.dart';
import '../services/connection_controller.dart';
import '../services/mission_controller.dart';
import '../services/ros_connection_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Bluetooth butona basınca açılan bağlantı yönetim popup'ı.
///
/// BT bölümü gerçek [ConnectionController]'a bağlıdır.
/// WiFi bölümü gerçek rosbridge, PLC durumu /robot_status kaynağıdır.
class ConnectionPanel extends StatefulWidget {
  /// Kullanıcı "Cihaz Seç" butonuna basınca çağrılır.
  final VoidCallback onConnectBluetooth;

  /// Kullanıcı BT "Kes" butonuna basınca çağrılır.
  final VoidCallback onDisconnectBluetooth;

  const ConnectionPanel({
    super.key,
    required this.onConnectBluetooth,
    required this.onDisconnectBluetooth,
  });

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  final _ros = RosConnectionController.instance;
  final _ipController = TextEditingController(text: 'ws://localhost:9090');

  @override
  void initState() {
    super.initState();
    _ros.state.addListener(_onRosState);
  }

  void _onRosState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ros.state.removeListener(_onRosState);
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connectRos() async {
    try {
      await _ros.connect(_ipController.text);
    } catch (error) {
      MissionController.instance.postMessage('ROS bağlantı hatası: $error');
    }
  }

  Future<void> _disconnectRos() => _ros.disconnect();

  @override
  Widget build(BuildContext context) {
    final rosState = _ros.state.value;
    final wifiConnected = rosState.isConnected;
    final wifiLoading = rosState.isConnecting;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: screenW * 0.86,
        height: screenH * 0.82,
        child: Container(
          decoration: BoxDecoration(
            color: AgvColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AgvColors.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Başlık ───────────────────────────────────────────────
              _PanelHeader(onClose: () => Navigator.pop(context)),
              Divider(height: 1, color: AgvColors.divider),
              // ── İçerik (kalan tüm alan) ──────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.r, 10.r, 12.r, 10.r),
                  child: Column(
                    children: [
                      // Bilgi satırları
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _BtSection(
                                onConnect: widget.onConnectBluetooth,
                                onDisconnect: widget.onDisconnectBluetooth,
                              ),
                            ),
                            _VDivider(),
                            Expanded(
                              child: _WifiSection(
                                connected: wifiConnected,
                                loading: wifiLoading,
                                statusMessage: rosState.message,
                                ipController: _ipController,
                                onConnect: _connectRos,
                                onDisconnect: _disconnectRos,
                              ),
                            ),
                            _VDivider(),
                            Expanded(child: _PlcSection()),
                          ],
                        ),
                      ),
                      // Butonlar — daima altta, daima görünür
                      Divider(height: 12.h, color: AgvColors.divider),
                      _ButtonsRow(
                        wifiConnected: wifiConnected,
                        wifiLoading: wifiLoading,
                        onBtConnect: widget.onConnectBluetooth,
                        onBtDisconnect: widget.onDisconnectBluetooth,
                        onWifiConnect: _connectRos,
                        onWifiDisconnect: _disconnectRos,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Başlık ────────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _PanelHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(Icons.cable, color: AgvColors.accent, size: 14.r),
          SizedBox(width: 6.w),
          Text(
            'BAĞLANTI PANELİ',
            style: AgvTypography.technical(
              size: 11.sp,
              color: AgvColors.textPrimary,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Icon(
                  Icons.close,
                  color: AgvColors.textMuted,
                  size: 16.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dikey ayırıcı ─────────────────────────────────────────────────────────────

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(width: 1, color: AgvColors.divider),
    );
  }
}

// ── Bluetooth Bölümü ──────────────────────────────────────────────────────────

class _BtSection extends StatelessWidget {
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _BtSection({required this.onConnect, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvConnectionState>(
      valueListenable: ConnectionController.instance.state,
      builder: (context, conn, _) {
        final isConnected = conn.isConnected;
        final isConnecting = conn.isConnecting;
        final accent = isConnected
            ? AgvColors.connected
            : isConnecting
            ? AgvColors.connecting
            : AgvColors.disconnected;
        final statusLabel = isConnected
            ? 'Bağlı'
            : isConnecting
            ? 'Bağlanıyor...'
            : 'Bağlı Değil';

        return _Section(
          icon: Icons.bluetooth,
          title: 'Bluetooth',
          accent: accent,
          children: [
            _StatusRow(label: 'Durum', value: statusLabel, color: accent),
            _StatusRow(
              label: 'Kanal',
              value: conn.deviceAddress ?? 'HC-06',
              color: AgvColors.textSecondary,
            ),
          ],
        );
      },
    );
  }
}

// ── WiFi / IP Bölümü ──────────────────────────────────────────────────────────

class _WifiSection extends StatelessWidget {
  final bool connected;
  final bool loading;
  final String statusMessage;
  final TextEditingController ipController;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _WifiSection({
    required this.connected,
    required this.loading,
    required this.statusMessage,
    required this.ipController,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = connected
        ? AgvColors.connected
        : loading
        ? AgvColors.connecting
        : AgvColors.disconnected;

    return _Section(
      icon: Icons.wifi,
      title: 'WiFi / IP',
      accent: accent,
      children: [
        _StatusRow(
          label: 'Durum',
          value: connected
              ? 'Bağlı'
              : loading
              ? 'Bağlanıyor...'
              : statusMessage,
          color: accent,
        ),
        SizedBox(height: 6.h),
        Container(
          height: 24.h,
          decoration: BoxDecoration(
            color: AgvColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AgvColors.borderSubtle),
          ),
          child: TextField(
            controller: ipController,
            style: AgvTypography.mono(
              size: 10.sp,
              color: AgvColors.textPrimary,
            ),
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              border: InputBorder.none,
              hintText: 'ws://192.168.1.50:9090',
              hintStyle: AgvTypography.mono(
                size: 10.sp,
                color: AgvColors.textMuted,
              ),
              prefixIcon: Icon(
                Icons.dns_outlined,
                size: 11.r,
                color: AgvColors.textMuted,
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 22.w),
            ),
          ),
        ),
      ],
    );
  }
}

// ── PLC / Fabrika Bölümü ──────────────────────────────────────────────────────

class _PlcSection extends StatelessWidget {
  const _PlcSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvMissionState>(
      valueListenable: MissionController.instance.state,
      builder: (context, s, _) {
        final plcOn = s.plcConnected;
        final accent = plcOn ? AgvColors.accent : AgvColors.disconnected;
        final doorAccent = s.doorPermission == DoorPermission.granted
            ? AgvColors.connected
            : s.doorPermission == DoorPermission.denied
            ? AgvColors.danger
            : AgvColors.warning;
        final doorLabel = switch (s.doorPermission) {
          DoorPermission.granted => 'Serbest',
          DoorPermission.waiting => 'Bekleniyor',
          DoorPermission.denied => 'Reddedildi',
        };

        return _Section(
          icon: Icons.precision_manufacturing_outlined,
          title: 'PLC / Otomasyon',
          accent: accent,
          children: [
            _StatusRow(
              label: 'Durum',
              value: plcOn ? 'Bağlı' : 'Bağlı Değil',
              color: accent,
            ),
            _StatusRow(label: 'Kapı İzni', value: doorLabel, color: doorAccent),
            _StatusRow(
              label: 'Son Mesaj',
              value: s.plcLastMessage ?? '—',
              color: AgvColors.textSecondary,
              maxLines: 2,
            ),
          ],
        );
      },
    );
  }
}

// ── Butonlar satırı ───────────────────────────────────────────────────────────

class _ButtonsRow extends StatelessWidget {
  final bool wifiConnected;
  final bool wifiLoading;
  final VoidCallback onBtConnect;
  final VoidCallback onBtDisconnect;
  final VoidCallback onWifiConnect;
  final VoidCallback onWifiDisconnect;

  const _ButtonsRow({
    required this.wifiConnected,
    required this.wifiLoading,
    required this.onBtConnect,
    required this.onBtDisconnect,
    required this.onWifiConnect,
    required this.onWifiDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // BT butonu
        Expanded(
          child: ValueListenableBuilder<AgvConnectionState>(
            valueListenable: ConnectionController.instance.state,
            builder: (context, conn, child) {
              if (conn.isConnecting) {
                return _CompactButton(
                  label: 'Bağlanıyor',
                  icon: Icons.hourglass_top,
                  color: AgvColors.connecting,
                  onTap: null,
                );
              }
              if (conn.isConnected) {
                return _CompactButton(
                  label: 'Kes',
                  icon: Icons.bluetooth_disabled,
                  color: AgvColors.danger,
                  onTap: onBtDisconnect,
                );
              }
              return _CompactButton(
                label: 'Cihaz Seç',
                icon: Icons.bluetooth_searching,
                color: AgvColors.accent,
                onTap: onBtConnect,
              );
            },
          ),
        ),
        SizedBox(width: 21.w),
        // WiFi butonu
        Expanded(
          child: wifiConnected
              ? _CompactButton(
                  label: 'Kes',
                  icon: Icons.wifi_off,
                  color: AgvColors.danger,
                  onTap: onWifiDisconnect,
                )
              : _CompactButton(
                  label: wifiLoading ? 'Bağlanıyor' : 'Bağlan',
                  icon: wifiLoading ? Icons.hourglass_top : Icons.wifi,
                  color: AgvColors.info,
                  onTap: wifiLoading ? null : onWifiConnect,
                  loading: wifiLoading,
                ),
        ),
        SizedBox(width: 21.w),
        // PLC butonu
        Expanded(
          child: ValueListenableBuilder<AgvMissionState>(
            valueListenable: MissionController.instance.state,
            builder: (context, s, child) {
              final plcOn = s.plcConnected;
              return _CompactButton(
                label: plcOn ? 'PLC Bağlı' : 'ROS Bekleniyor',
                icon: plcOn ? Icons.link : Icons.link_off,
                color: plcOn ? AgvColors.accent : AgvColors.disconnected,
                onTap: null,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Yeniden kullanılabilir bölüm iskelet ──────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 11.r, color: accent),
              SizedBox(width: 4.w),
              Text(
                title,
                style: AgvTypography.technical(
                  size: 9.sp,
                  color: accent,
                  letterSpacing: 0.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...children,
        ],
      ),
    );
  }
}

// ── Durum satırı ──────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final int maxLines;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52.w,
            child: Text(
              label,
              style: AgvTypography.technical(
                size: 8.sp,
                color: AgvColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AgvTypography.technical(
                size: 8.sp,
                color: color,
                letterSpacing: 0.3,
                weight: FontWeight.w600,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kompakt aksiyon butonu ────────────────────────────────────────────────────

class _CompactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _CompactButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final effectiveColor = disabled ? color.withValues(alpha: 0.35) : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(6.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 10.r,
                  height: 10.r,
                  child: CircularProgressIndicator(
                    color: effectiveColor,
                    strokeWidth: 1.5,
                  ),
                )
              else
                Icon(icon, size: 11.r, color: effectiveColor),
              SizedBox(width: 5.w),
              Text(
                label,
                style: AgvTypography.technical(
                  size: 8.sp,
                  color: effectiveColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
