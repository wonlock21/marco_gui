import 'dart:math';

import 'package:flutter/material.dart';

import 'agv_settings.dart';
import 'services/autonomy_controller.dart';
import 'services/connection_controller.dart';
import 'services/joystick_command_throttler.dart';
import 'theme/agv_colors.dart';
import 'widgets/control_lock_overlay.dart';

class Joystick extends StatefulWidget {
  final bool isCameraOn;

  const Joystick({super.key, this.isCameraOn = false});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  final ValueNotifier<Offset> _knobOffset = ValueNotifier(Offset.zero);
  final JoystickCommandThrottler _commandThrottler = JoystickCommandThrottler();
  final _connection = ConnectionController.instance;
  final _autonomy = AutonomyController.instance;

  @override
  void initState() {
    super.initState();
    _connection.state.addListener(_onLockChanged);
    _autonomy.isAuto.addListener(_onLockChanged);
  }

  @override
  void dispose() {
    _connection.state.removeListener(_onLockChanged);
    _autonomy.isAuto.removeListener(_onLockChanged);
    _knobOffset.dispose();
    super.dispose();
  }

  void _onLockChanged() {
    final conn = _connection.state.value;
    final locked = conn.status != AgvConnectionStatus.connected ||
        _autonomy.isAuto.value;
    if (locked && _knobOffset.value != Offset.zero) {
      _knobOffset.value = Offset.zero;
      _commandThrottler.onOffset(Offset.zero, deadZone: double.infinity);
      _commandThrottler.reset();
    }
  }

  void _resetKnob() {
    _knobOffset.value = Offset.zero;
    _commandThrottler.reset();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: SettingsManager.joystickScaleNotifier,
      builder: (context, scale, _) {
        final screenHeight = MediaQuery.of(context).size.height;
        final radius = (screenHeight * 0.18) * scale;
        final deadZone = radius * 0.12;
        final knobSize = radius * 0.42;

        final joystick = GestureDetector(
          onPanUpdate: (details) {
            var next = _knobOffset.value + details.delta;
            if (next.distance > radius) {
              next = Offset.fromDirection(next.direction, radius);
            }
            _knobOffset.value = next;
            _commandThrottler.onOffset(next, deadZone: deadZone);
          },
          onPanEnd: (_) {
            _resetKnob();
            _commandThrottler.onOffset(Offset.zero, deadZone: deadZone);
          },
          child: ValueListenableBuilder<Offset>(
            valueListenable: _knobOffset,
            builder: (context, offset, _) {
              final isActive = offset.distance >= deadZone;
              final strength = (offset.distance / radius).clamp(0.0, 1.0);

              return Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Belirgin koyu zemin
                  color: widget.isCameraOn
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFF080B14).withValues(alpha: 0.88),
                  // Sert çerçeve
                  border: Border.all(
                    color: isActive
                        ? AgvColors.accent.withValues(alpha: 0.75)
                        : AgvColors.accent.withValues(alpha: 0.35),
                    width: isActive ? 2.2 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AgvColors.accent.withValues(
                        alpha: isActive ? 0.22 : 0.08,
                      ),
                      blurRadius: isActive ? 18 : 10,
                      spreadRadius: isActive ? 1 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ── Sektör çizgileri + aktif vurgu ────────────────
                    CustomPaint(
                      size: Size(radius * 2, radius * 2),
                      painter: _SectorPainter(
                        knobOffset: offset,
                        radius: radius,
                        deadZone: deadZone,
                        activeColor: AgvColors.accent,
                      ),
                    ),

                    // ── Knob ──────────────────────────────────────────
                    Transform.translate(
                      offset: offset,
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color.lerp(
                                    const Color(0xFF6200EA),
                                    AgvColors.accent,
                                    strength,
                                  ) ??
                                  AgvColors.accent,
                              Color.lerp(
                                    const Color(0xFF3700B3),
                                    AgvColors.accent.withValues(alpha: 0.6),
                                    strength,
                                  ) ??
                                  AgvColors.accent,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AgvColors.accent
                                        .withValues(alpha: 0.45 * strength),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _directionIcon(offset, deadZone),
                          color: Colors.white.withValues(alpha: 0.9),
                          size: knobSize * 0.48,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        return ControlLockOverlay(
          lockOnAutonomy: true,
          child: joystick,
        );
      },
    );
  }

  /// Knob içinde yönü gösteren ok ikonu.
  IconData _directionIcon(Offset offset, double deadZone) {
    if (offset.distance < deadZone) return Icons.circle;
    double angle = atan2(-offset.dy, offset.dx) * 180 / pi;
    if (angle < 0) angle += 360;
    final dir = ((angle + 22.5) / 45).floor() % 8;
    const icons = [
      Icons.arrow_forward,       // SAĞ
      Icons.arrow_upward,        // SAĞ_İLERİ (approx)
      Icons.arrow_upward,        // İLERİ
      Icons.arrow_upward,        // SOL_İLERİ (approx)
      Icons.arrow_back,          // SOL
      Icons.arrow_downward,      // SOL_GERİ (approx)
      Icons.arrow_downward,      // GERİ
      Icons.arrow_downward,      // SAĞ_GERİ (approx)
    ];
    return icons[dir];
  }
}

// ── Sektör ve yön çizgileri painter ──────────────────────────────────────────

class _SectorPainter extends CustomPainter {
  final Offset knobOffset;
  final double radius;
  final double deadZone;
  final Color activeColor;

  const _SectorPainter({
    required this.knobOffset,
    required this.radius,
    required this.deadZone,
    required this.activeColor,
  });

  /// Aktif yön sektörünü hesaplar (-1 = deadzone/dur).
  int _activeDir() {
    if (knobOffset.distance < deadZone) return -1;
    double angle = atan2(-knobOffset.dy, knobOffset.dx) * 180 / pi;
    if (angle < 0) angle += 360;
    return ((angle + 22.5) / 45).floor() % 8;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = radius;
    final activeDir = _activeDir();

    // ── Aktif sektör vurgusu ────────────────────────────────────────────────
    if (activeDir >= 0) {
      final highlightPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.13)
        ..style = PaintingStyle.fill;
      // canvas_start = -(dir*45 + 22.5)° → dönüştürülmüş
      final startRad = (-activeDir * 45.0 - 22.5) * pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 2),
        startRad,
        45 * pi / 180,
        true,
        highlightPaint,
      );
    }

    // ── Deadzone iç halkası ─────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      deadZone,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // ── 8 sektör sınır çizgisi ──────────────────────────────────────────────
    // Sınırlar math uzayında 22.5°, 67.5°, ... (her 45°)
    // Canvas'ta: endpoint = (cos(-α), sin(-α)) * r
    final sectorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final mathAngle = (22.5 + i * 45.0) * pi / 180;
      final end = Offset(
        center.dx + r * cos(-mathAngle),
        center.dy + r * sin(-mathAngle),
      );
      // Sadece deadzone dışına çiz
      final start = Offset(
        center.dx + deadZone * cos(-mathAngle),
        center.dy + deadZone * sin(-mathAngle),
      );
      canvas.drawLine(start, end, sectorPaint);
    }

    // ── 8 yön tiki (rim üzerinde küçük işaret) ──────────────────────────────
    final tickPaint = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Yön etiketleri: 0=SAĞ, 2=İLERİ, 4=SOL, 6=GERİ ana eksenler
    for (int d = 0; d < 8; d++) {
      final isCardinal = d % 2 == 0; // 0,2,4,6 ana eksen
      final isCurrent = d == activeDir;

      tickPaint.color = isCurrent
          ? activeColor.withValues(alpha: 0.9)
          : isCardinal
              ? Colors.white.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.15);

      // Yönün math açısı (sektör merkezi)
      final mathAngle = d * 45.0 * pi / 180;
      final outerR = r - 2;
      final innerR = isCardinal ? r - 8 : r - 6;

      final outer = Offset(
        center.dx + outerR * cos(-mathAngle),
        center.dy + outerR * sin(-mathAngle),
      );
      final inner = Offset(
        center.dx + innerR * cos(-mathAngle),
        center.dy + innerR * sin(-mathAngle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_SectorPainter old) =>
      old.knobOffset != knobOffset || old.activeColor != activeColor;
}
