import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/agv_mission_state.dart';
import '../services/admin_controller.dart';
import '../services/autonomy_controller.dart';
import '../services/mission_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Sabit kart boyutu — tüm kartlar aynı boyutta görünür.
const double _kCardW = 140.0;
const double _kCardH = 70.0;

/// Ana ekranın ortasına yerleştirilen 2×2 kompakt durum kart gridi.
///
/// Tüm kartlar aynı genişlik/yükseklikte ve 4'er satır içerir.
/// [_ModeCard] ayrıca [AutonomyController] dinleyerek otonom renk temasına uyar.
class StatusCards extends StatelessWidget {
  const StatusCards({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvMissionState>(
      valueListenable: MissionController.instance.state,
      builder: (context, s, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AdminController.instance.isAdmin,
          builder: (context, isAdmin, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AutonomyController.instance.isAuto,
          builder: (context, isAuto, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MissionCard(s: s),
                    SizedBox(width: 6.w),
                    _QrCard(s: s),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FactoryCard(s: s, isAdmin: isAdmin),
                    SizedBox(width: 6.w),
                    _ModeCard(s: s, isAuto: isAuto),
                  ],
                ),
              ],
            );
          },
        );
          },
        );
      },
    );
  }
}

// ─── Görev Kartı — 4 satır ───────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final AgvMissionState s;
  const _MissionCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(s.missionStatus);
    final route = '${s.routeFrom ?? 'A2'} → ${s.routeTo ?? 'B3'}';
    return _Card(
      accent: accent,
      icon: Icons.route,
      title: 'GÖREV',
      rows: [
        _Row('ID', s.missionId ?? 'MSN-0042', color: AgvColors.info),
        _Row('ROTA', route, color: AgvColors.textPrimary),
        _Row('DURUM', _label(s.missionStatus), color: accent),
        _Row('SONRAKI', s.nextStep ?? 'Alma Noktasına Git', color: AgvColors.textSecondary),
      ],
    );
  }

  static String _label(MissionStatus v) => switch (v) {
        MissionStatus.loaded => 'Yüklü Hareket',
        MissionStatus.unloaded => 'Yüksüz Hareket',
        MissionStatus.idle => 'Beklemede',
        MissionStatus.error => 'Güvenli Duruş',
      };

  static Color _accent(MissionStatus v) => switch (v) {
        MissionStatus.loaded => AgvColors.warning,
        MissionStatus.unloaded => AgvColors.info,
        MissionStatus.idle => AgvColors.info,
        MissionStatus.error => AgvColors.danger,
      };
}

// ─── QR Kartı — 4 satır ──────────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  final AgvMissionState s;
  const _QrCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final qrAccent = _vsAccent(s.qrValidation);
    return _Card(
      accent: qrAccent,
      icon: Icons.qr_code_scanner,
      title: 'QR',
      rows: [
        _Row('SON QR', s.lastQrCode ?? 'QA2.1', color: AgvColors.info),
        _Row('QR', _vsLabel(s.qrValidation), color: qrAccent),
        _Row('KONUM', _vsLabel(s.locationValidation), color: _vsAccent(s.locationValidation)),
        _Row('TARAMA', 'Otomatik', color: AgvColors.textSecondary),
      ],
    );
  }

  static String _vsLabel(ValidateStatus v) => switch (v) {
        ValidateStatus.ok => 'Geçerli',
        ValidateStatus.waiting => 'Bekleniyor',
        ValidateStatus.error => 'Hata',
      };

  static Color _vsAccent(ValidateStatus v) => switch (v) {
        ValidateStatus.ok => AgvColors.accent,
        ValidateStatus.waiting => AgvColors.accent,
        ValidateStatus.error => AgvColors.danger,
      };
}

// ─── Fabrika Otomasyon Kartı — 4 satır ───────────────────────────────────────

class _FactoryCard extends StatelessWidget {
  final AgvMissionState s;
  final bool isAdmin;
  const _FactoryCard({required this.s, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    // Admin modda bağlı ve kapı serbest gibi göster.
    final plcOn = isAdmin ? true : s.plcConnected;
    final door = isAdmin ? DoorPermission.granted : s.doorPermission;
    final message = isAdmin ? 'Bağlantı hazır (Admin)' : (s.plcLastMessage ?? 'Geçiş izni bekleniyor');

    final plcAccent = plcOn ? AgvColors.accent : AgvColors.danger;
    final doorAccent = _doorAccent(door);
    final systemAccent = plcOn ? AgvColors.accent : AgvColors.textSecondary;

    return _Card(
      accent: plcAccent,
      icon: Icons.precision_manufacturing,
      title: 'OTOMASYON',
      rows: [
        _Row('PLC', plcOn ? 'Bağlı' : 'Bağlı Değil', color: plcAccent),
        _Row('KAPI', _doorLabel(door), color: doorAccent),
        _Row('MESAJ', message),
        _Row('SİSTEM', plcOn ? 'Hazır' : 'Bekliyor', color: systemAccent),
      ],
    );
  }

  static String _doorLabel(DoorPermission v) => switch (v) {
        DoorPermission.granted => 'Serbest',
        DoorPermission.waiting => 'Bekleniyor',
        DoorPermission.denied => 'Reddedildi',
      };

  static Color _doorAccent(DoorPermission v) => switch (v) {
        DoorPermission.granted => AgvColors.accent,
        DoorPermission.waiting => AgvColors.warning,
        DoorPermission.denied => AgvColors.danger,
      };
}

// ─── Mod ve Kontrol Kartı — 4 satır, AutonomyController'a bağlı ──────────────

class _ModeCard extends StatelessWidget {
  final AgvMissionState s;
  final bool isAuto;
  const _ModeCard({required this.s, required this.isAuto});

  @override
  Widget build(BuildContext context) {
    // Kart accent rengi otonom moda göre mor, manuel ise turuncu.
    final accent = isAuto ? AgvColors.autonomy : AgvColors.warning;

    final agvModeLabel = isAuto ? 'Otonom' : 'Manuel';
    final agvModeAccent = isAuto ? AgvColors.autonomy : AgvColors.warning;

    // Uzaktan kontrol: otonom modda veya e-stop sonrası kilitli.
    final rcLocked = isAuto || s.remoteControl == RemoteControl.locked;
    final rcLabel = rcLocked ? 'Kilitli' : 'Aktif';
    final rcAccent = rcLocked ? AgvColors.textMuted : AgvColors.accent;

    // Fiziksel mod state'ten; sürüş kilidi otonom duruma göre.
    final physLabel = s.physicalMode == PhysicalMode.automatic
        ? 'Otomatik'
        : 'Manuel';

    return _Card(
      accent: accent,
      icon: Icons.settings_remote,
      title: 'KONTROL',
      rows: [
        _Row('AGV MODU', agvModeLabel, color: agvModeAccent),
        _Row('FİZİKSEL', physLabel, color: agvModeAccent),
        _Row('UZAKTAN', rcLabel, color: rcAccent),
        _Row(
          'SÜRÜŞ',
          rcLocked ? 'Kilitli' : 'Serbest',
          color: rcLocked ? AgvColors.danger : AgvColors.accent,
        ),
      ],
    );
  }
}

// ─── Yeniden kullanılabilir kart iskelet ──────────────────────────────────────

class _Row {
  final String label;
  final String value;
  final Color? color;
  const _Row(this.label, this.value, {this.color});
}

class _Card extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final List<_Row> rows;

  const _Card({
    required this.accent,
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kCardW.w,
      height: _kCardH.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık satırı
          Row(
            children: [
              Icon(icon, color: accent, size: 11.r),
              SizedBox(width: 5.w),
              Text(
                title,
                style: AgvTypography.technical(
                  size: 9.sp,
                  color: accent,
                  weight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Veri satırları — kompakt sabit boşluk.
          ...rows.map(
            (r) => Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 44.w,
                    child: Text(
                      r.label,
                      style: AgvTypography.technical(
                        size: 7.sp,
                        color: AgvColors.textMuted,
                        weight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: AgvTypography.mono(
                        size: 7.5.sp,
                        color: r.color ?? AgvColors.textPrimary,
                        weight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
