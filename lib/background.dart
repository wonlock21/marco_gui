import 'package:flutter/material.dart';

import 'theme/agv_colors.dart';

class BackgroundColor extends StatelessWidget {
  const BackgroundColor({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.3),
                radius: 1.4,
                colors: [
                  AgvColors.surface,
                  AgvColors.background,
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: _GridOverlay()),
      ],
    );
  }
}

/// İnce, neredeyse görünmez grid pattern — endüstriyel dokunuş.
class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  static const double _step = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AgvColors.borderSubtle.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
