import 'package:flutter/material.dart';

/// Custom vector-painted Google 'G' mark matching the wireframe button.
class GoogleLogoMark extends StatelessWidget {
  const GoogleLogoMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.21;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red top arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.65, false, paint);

    // Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.35, 1.55, false, paint);

    // Green bottom arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.75, 1.60, false, paint);

    // Blue right arc + crossbar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.15, 0.90, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.41,
        size.width * 0.45,
        stroke * 0.92,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}