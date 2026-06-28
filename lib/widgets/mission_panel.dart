import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/agv_mission_state.dart';
import '../services/mission_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Görev sekmesinde gösterilen görev takip paneli.
class MissionPanel extends StatefulWidget {
  const MissionPanel({super.key});

  @override
  State<MissionPanel> createState() => _MissionPanelState();
}

class _MissionPanelState extends State<MissionPanel> {
  int _seconds = 257; // 04:17 mock başlangıç
  late Timer _timer;

  static const _phases = [
    'Görev Alındı',
    'Yüksüz Hareket',
    'Yük Alma',
    'Yüklü Hareket',
    'Kapı İzni',
    'Yük Bırakma',
    'Tamamlandı',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _duration {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int _activePhase(MissionStatus status) => switch (status) {
        MissionStatus.idle => 0,
        MissionStatus.unloaded => 1,
        MissionStatus.loaded => 3,
        MissionStatus.error => -1, // güvenli duruş
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvMissionState>(
      valueListenable: MissionController.instance.state,
      builder: (context, s, _) => _buildContent(s),
    );
  }

  Widget _buildContent(AgvMissionState s) {
    final route = '${s.routeFrom ?? 'A2'} → ${s.routeTo ?? 'B3'}';
    final statusLabel = _missionLabel(s.missionStatus);
    final statusAccent = _missionAccent(s.missionStatus);
    final activeIdx = _activePhase(s.missionStatus);

    return Container(
      decoration: BoxDecoration(
        color: AgvColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AgvColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık ──────────────────────────────────────────────
          _Header(
            id: s.missionId ?? 'MSN-0042',
            route: route,
            status: statusLabel,
            statusAccent: statusAccent,
            duration: _duration,
          ),
          Divider(height: 1, color: AgvColors.divider),

          // ── İçerik: info + aşama ────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sol: bilgi gridesi — kırpılarak taşmayı önle
                  Expanded(
                    flex: 3,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: _InfoGrid(state: s, duration: _duration),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Sağ: aşama listesi — kırpılarak taşmayı önle
                  Expanded(
                    flex: 2,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: _PhaseList(
                          phases: _phases,
                          activeIndex: activeIdx,
                        ),
                      ),
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

  static String _missionLabel(MissionStatus v) => switch (v) {
        MissionStatus.loaded => 'Yüklü Hareket',
        MissionStatus.unloaded => 'Yüksüz Hareket',
        MissionStatus.idle => 'Beklemede',
        MissionStatus.error => 'Güvenli Duruş',
      };

  static Color _missionAccent(MissionStatus v) => switch (v) {
        MissionStatus.loaded => AgvColors.warning,
        MissionStatus.unloaded => AgvColors.info,
        MissionStatus.idle => AgvColors.info,
        MissionStatus.error => AgvColors.danger,
      };
}

// ── Başlık satırı ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String id;
  final String route;
  final String status;
  final Color statusAccent;
  final String duration;

  const _Header({
    required this.id,
    required this.route,
    required this.status,
    required this.statusAccent,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      child: Row(
        children: [
          Icon(Icons.assignment, color: AgvColors.info, size: 14.r),
          SizedBox(width: 6.w),
          Text(
            'GÖREV TAKİBİ',
            style: AgvTypography.technical(
              size: 10.sp,
              color: AgvColors.info,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(width: 10.w),
          _Pill(text: id, color: AgvColors.info),
          SizedBox(width: 6.w),
          _Pill(text: route, color: AgvColors.textSecondary),
          const Spacer(),
          // Durum
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: statusAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: statusAccent.withValues(alpha: 0.5)),
            ),
            child: Text(
              status,
              style: AgvTypography.technical(
                size: 9.sp,
                color: statusAccent,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Süre
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 11.r, color: AgvColors.textMuted),
              SizedBox(width: 3.w),
              Text(
                duration,
                style: AgvTypography.mono(
                  size: 10.sp,
                  color: AgvColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AgvTypography.technical(
          size: 8.sp,
          color: color,
          letterSpacing: 0.4,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

// ── Bilgi gridesi ─────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final AgvMissionState state;
  final String duration;

  const _InfoGrid({required this.state, required this.duration});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem('SONRAKI', state.nextStep ?? 'Yük Alma', AgvColors.info),
      _InfoItem('ALMA', state.routeFrom ?? 'A2', AgvColors.warning),
      _InfoItem('BIRAKMA', state.routeTo ?? 'B3', AgvColors.lift),
      _InfoItem('SON MESAJ', state.lastSystemMessage ?? 'Görev alındı', AgvColors.textSecondary),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETAYLAR',
          style: AgvTypography.technical(
            size: 8.sp,
            color: AgvColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 6.h),
        ...items.map((e) => _InfoRow(item: e)),
      ],
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final Color color;
  const _InfoItem(this.label, this.value, this.color);
}

class _InfoRow extends StatelessWidget {
  final _InfoItem item;
  const _InfoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        children: [
          SizedBox(
            width: 64.w,
            child: Text(
              item.label,
              style: AgvTypography.technical(
                size: 8.sp,
                color: AgvColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              style: AgvTypography.technical(
                size: 9.sp,
                color: item.color,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aşama listesi ─────────────────────────────────────────────────────────────

class _PhaseList extends StatelessWidget {
  final List<String> phases;
  final int activeIndex;

  const _PhaseList({required this.phases, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AŞAMALAR',
          style: AgvTypography.technical(
            size: 8.sp,
            color: AgvColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        ...phases.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final isActive = i == activeIndex;
          final isDone = activeIndex >= 0 && i < activeIndex;
          final isError = activeIndex == -1;

          final Color color;
          final IconData icon;
          if (isError) {
            color = AgvColors.danger;
            icon = Icons.warning_amber;
          } else if (isActive) {
            color = AgvColors.accent;
            icon = Icons.play_arrow;
          } else if (isDone) {
            color = AgvColors.textMuted;
            icon = Icons.check_circle_outline;
          } else {
            color = AgvColors.textDisabled;
            icon = Icons.radio_button_unchecked;
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Row(
              children: [
                Icon(icon, size: 10.r, color: color),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    label,
                    style: AgvTypography.technical(
                      size: isActive ? 9.sp : 8.sp,
                      color: color,
                      letterSpacing: 0.2,
                      weight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
