import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/agv_mission_state.dart';
import '../services/mission_controller.dart';
import '../theme/agv_colors.dart';
import '../theme/agv_typography.dart';

/// Harita sekmesinde gösterilen mini rota takip paneli.
class MapPanel extends StatelessWidget {
  const MapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgvMissionState>(
      valueListenable: MissionController.instance.state,
      builder: (context, s, _) => _buildPanel(s),
    );
  }

  Widget _buildPanel(AgvMissionState s) {
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            child: Row(
              children: [
                Icon(Icons.map_outlined, color: AgvColors.lift, size: 14.r),
                SizedBox(width: 6.w),
                Text(
                  'ROTA TAKİBİ',
                  style: AgvTypography.technical(
                    size: 10.sp,
                    color: AgvColors.lift,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                _StatusDot(
                  label: '${s.routeFrom ?? 'A2'} → ${s.routeTo ?? 'B3'}',
                  color: AgvColors.info,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AgvColors.divider),

          // ── Harita alanı ─────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12.r),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _MapPainter(state: s),
                      ),
                      // Legend
                      Positioned(
                        bottom: 4.h,
                        left: 10.w,
                        right: 10.w,
                        child: const _Legend(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.r,
          height: 5.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 3)],
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: AgvTypography.technical(
            size: 9.sp,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ── Harita ressamı ────────────────────────────────────────────────────────────

/// Koordinat sistemi: 10 sütun × 5 satır
///   col 0‥9   (x = col * cellW + cellW/2)
///   row 0‥4   (y = row * cellH + cellH/2)
class _MapPainter extends CustomPainter {
  final AgvMissionState state;
  _MapPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final cW = size.width / 10;
    final cH = size.height / 5;

    _drawGrid(canvas, size, cW, cH);
    _drawObstacle(canvas, cW, cH);
    _drawRoute(canvas, cW, cH);
    _drawWaypoints(canvas, cW, cH);
    _drawRobot(canvas, cW, cH);
  }

  // ── Grid ────────────────────────────────────────────────────────────────────
  void _drawGrid(Canvas canvas, Size size, double cW, double cH) {
    final p = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += cW) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += cH) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  // ── Rota çizgisi ─────────────────────────────────────────────────────────────
  // Rota: A2(1,2.5) → QR1(3,2.5) → Door(5,1.5) → QR2(6.5,1.5) → B3(8.5,1.5)
  void _drawRoute(Canvas canvas, double cW, double cH) {
    final points = [
      _pt(1.5, 2.5, cW, cH),
      _pt(3.0, 2.5, cW, cH),
      _pt(3.0, 1.5, cW, cH),
      _pt(5.0, 1.5, cW, cH),
      _pt(6.5, 1.5, cW, cH),
      _pt(8.5, 1.5, cW, cH),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Gölge çizgi
    canvas.drawPath(
      path,
      Paint()
        ..color = AgvColors.info.withValues(alpha: 0.15)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Ana çizgi
    canvas.drawPath(
      path,
      Paint()
        ..color = AgvColors.info.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Yön okları
    for (int i = 0; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      final angle = math.atan2(
        points[i + 1].dy - points[i].dy,
        points[i + 1].dx - points[i].dx,
      );
      _drawArrow(canvas, mid, angle, AgvColors.info.withValues(alpha: 0.6));
    }
  }

  void _drawArrow(Canvas canvas, Offset pos, double angle, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final size = 4.0;
    final a1 = angle + math.pi * 0.8;
    final a2 = angle - math.pi * 0.8;
    canvas.drawLine(pos, Offset(pos.dx + math.cos(a1) * size, pos.dy + math.sin(a1) * size), p);
    canvas.drawLine(pos, Offset(pos.dx + math.cos(a2) * size, pos.dy + math.sin(a2) * size), p);
  }

  // ── Engel alanı ──────────────────────────────────────────────────────────────
  void _drawObstacle(Canvas canvas, double cW, double cH) {
    // Engel QR1'in (col 3, row 2.5) hemen sağında üst bölgede
    final rect = Rect.fromCenter(
      center: _pt(4.2, 2.5, cW, cH),
      width: cW * 1.2,
      height: cH * 0.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = AgvColors.danger.withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..color = AgvColors.danger.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Çapraz çizgiler
    final dash = Paint()
      ..color = AgvColors.danger.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    canvas.drawLine(rect.topLeft, rect.bottomRight, dash);
    canvas.drawLine(rect.topRight, rect.bottomLeft, dash);
  }

  // ── Waypoint'ler ─────────────────────────────────────────────────────────────
  void _drawWaypoints(Canvas canvas, double cW, double cH) {
    // Alma noktası A2 — sarı daire
    _circle(canvas, _pt(1.5, 2.5, cW, cH), AgvColors.warning, 'A2', filled: true);
    // Bırakma noktası B3 — turuncu daire
    _circle(canvas, _pt(8.5, 1.5, cW, cH), AgvColors.lift, 'B3', filled: true);
    // QR1 — teal elmas
    _diamond(canvas, _pt(3.0, 2.5, cW, cH), AgvColors.accent, 'QR');
    // QR2 — teal elmas
    _diamond(canvas, _pt(6.5, 1.5, cW, cH), AgvColors.accent, 'QR');
    // Kapı — mavi kare
    _square(canvas, _pt(5.0, 1.5, cW, cH), AgvColors.info, 'KP');
    // Şarj — yeşil üçgen
    _triangle(canvas, _pt(8.8, 3.5, cW, cH), AgvColors.connected, 'ŞRJ');
  }

  void _circle(Canvas canvas, Offset pos, Color color, String label, {bool filled = false}) {
    final r = 8.0;
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = filled ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    _label(canvas, pos + const Offset(0, 13), label, color);
  }

  void _diamond(Canvas canvas, Offset pos, Color color, String label) {
    final s = 7.0;
    final path = Path()
      ..moveTo(pos.dx, pos.dy - s)
      ..lineTo(pos.dx + s, pos.dy)
      ..lineTo(pos.dx, pos.dy + s)
      ..lineTo(pos.dx - s, pos.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.2));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    _label(canvas, pos + const Offset(0, 13), label, color);
  }

  void _square(Canvas canvas, Offset pos, Color color, String label) {
    final s = 7.0;
    final rect = Rect.fromCenter(center: pos, width: s * 2, height: s * 2);
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.2));
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    _label(canvas, pos + const Offset(0, 13), label, color);
  }

  void _triangle(Canvas canvas, Offset pos, Color color, String label) {
    final s = 7.0;
    final path = Path()
      ..moveTo(pos.dx, pos.dy - s)
      ..lineTo(pos.dx + s, pos.dy + s)
      ..lineTo(pos.dx - s, pos.dy + s)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.2));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    _label(canvas, pos + const Offset(0, 13), label, color);
  }

  void _label(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, 0));
  }

  // ── Robot ────────────────────────────────────────────────────────────────────
  void _drawRobot(Canvas canvas, double cW, double cH) {
    // Mock pozisyon: rota üzerinde ilk segmentte
    final pos = _pt(2.2, 2.5, cW, cH);
    final heading = 0.0; // sağa bakıyor

    // Robot gövdesi (ok şeklinde)
    final s = 10.0;
    final path = Path()
      ..moveTo(pos.dx + math.cos(heading) * s, pos.dy + math.sin(heading) * s)
      ..lineTo(
          pos.dx + math.cos(heading + math.pi * 0.75) * s * 0.7,
          pos.dy + math.sin(heading + math.pi * 0.75) * s * 0.7)
      ..lineTo(pos.dx, pos.dy)
      ..lineTo(
          pos.dx + math.cos(heading - math.pi * 0.75) * s * 0.7,
          pos.dy + math.sin(heading - math.pi * 0.75) * s * 0.7)
      ..close();

    // Glow
    canvas.drawCircle(
      pos,
      s * 1.1,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AgvColors.accent
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    _label(canvas, pos + const Offset(0, 15), 'AGV', Colors.white);
  }

  Offset _pt(double col, double row, double cW, double cH) =>
      Offset(col * cW, row * cH);

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.state.missionStatus != state.missionStatus ||
      old.state.physicalMode != state.physicalMode;
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AgvColors.background.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AgvColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LegendItem(symbol: '▶', label: 'Robot', color: Colors.white),
          _LegendItem(symbol: '─', label: 'Rota', color: AgvColors.info),
          _LegendItem(symbol: '●', label: 'Alma', color: AgvColors.warning),
          _LegendItem(symbol: '●', label: 'Bırakma', color: AgvColors.lift),
          _LegendItem(symbol: '◆', label: 'QR', color: AgvColors.accent),
          _LegendItem(symbol: '■', label: 'Kapı', color: AgvColors.info),
          _LegendItem(symbol: '▲', label: 'Şarj', color: AgvColors.connected),
          _LegendItem(symbol: '✕', label: 'Engel', color: AgvColors.danger),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String symbol;
  final String label;
  final Color color;

  const _LegendItem({
    required this.symbol,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: TextStyle(color: color, fontSize: 8.sp),
          ),
          SizedBox(width: 3.w),
          Text(
            label,
            style: AgvTypography.technical(
              size: 7.sp,
              color: AgvColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
