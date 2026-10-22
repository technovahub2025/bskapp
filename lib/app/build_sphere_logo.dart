import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Compact, scalable BuildSphere construction mark for splash and app headers.
class BuildSphereLogo extends StatelessWidget {
  const BuildSphereLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _BuildSphereLogoPainter(),
      );
}

class _BuildSphereLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width;
    final sy = size.height;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final navy = Paint()..color = AppTheme.navy;
    final orange = Paint()..color = AppTheme.orange;
    final yellow = Paint()..color = AppTheme.yellow;

    // Sphere/sun tucked behind the structure.
    canvas.drawCircle(p(.72, .25), sx * .13, orange);

    // Roof and building silhouette.
    final roof = Path()
      ..moveTo(p(.12, .48).dx, p(.12, .48).dy)
      ..lineTo(p(.50, .14).dx, p(.50, .14).dy)
      ..lineTo(p(.88, .48).dx, p(.88, .48).dy)
      ..lineTo(p(.77, .48).dx, p(.77, .48).dy)
      ..lineTo(p(.50, .24).dx, p(.50, .24).dy)
      ..lineTo(p(.23, .48).dx, p(.23, .48).dy)
      ..close();
    canvas.drawPath(roof, navy);

    final building = Path()
      ..moveTo(p(.24, .47).dx, p(.24, .47).dy)
      ..lineTo(p(.76, .47).dx, p(.76, .47).dy)
      ..lineTo(p(.76, .81).dx, p(.76, .81).dy)
      ..lineTo(p(.24, .81).dx, p(.24, .81).dy)
      ..close();
    canvas.drawPath(building, navy);

    // Golden doorway and structural bays create the recognizable B/S rhythm.
    final detail = Paint()
      ..color = AppTheme.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(.39, .55), p(.39, .72), detail);
    canvas.drawLine(p(.61, .55), p(.61, .72), detail);
    final door = Path()
      ..moveTo(p(.45, .81).dx, p(.81, .81).dy)
      ..lineTo(p(.45, .65).dx, p(.45, .65).dy)
      ..quadraticBezierTo(p(.50, .59).dx, p(.50, .59).dy, p(.55, .65).dx, p(.55, .65).dy)
      ..lineTo(p(.55, .81).dx, p(.55, .81).dy)
      ..close();
    canvas.drawPath(door, yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
