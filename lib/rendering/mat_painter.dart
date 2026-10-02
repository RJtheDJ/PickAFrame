import 'package:flutter/material.dart';

import '../models/mat_spec.dart';

/// Paints what sits on the mat board: the lower mat in a double mat, and the
/// 45° bevel cuts around each window. The board itself and the artwork are
/// drawn by `FrameRenderer`. Coordinates are relative to the whole frame.
class MatPainter extends CustomPainter {
  MatPainter({
    required this.style,
    required this.artworkRect,
    required this.topMatWindow,
    required this.bevelWidth,
    required this.coreColor,
    required this.innerColor,
  });

  final MountStyle style;
  final Rect artworkRect;
  final Rect topMatWindow;
  final double bevelWidth;
  final Color coreColor;
  final Color innerColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case MountStyle.float:
        return; // No window, so no bevels.
      case MountStyle.flat:
        _paintBevel(canvas, artworkRect);
      case MountStyle.doubleMat:
        canvas.drawRect(topMatWindow, Paint()..color = innerColor);
        _paintBevel(canvas, artworkRect);
        _paintBevel(canvas, topMatWindow);
    }
  }

  /// Draws the bevel as four trapezoids around [window]. With light from the
  /// top-left, the top and left cuts face away from it and fall into shade,
  /// while the bottom and right cuts catch it.
  void _paintBevel(Canvas canvas, Rect window) {
    final o = window.inflate(bevelWidth);
    final w = window;
    final shade = Color.lerp(coreColor, Colors.black, 0.22)!;
    final halfShade = Color.lerp(coreColor, Colors.black, 0.10)!;
    final lit = Color.lerp(coreColor, Colors.white, 0.35)!;

    void face(List<Offset> points, Color color) {
      canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
    }

    face([o.topLeft, o.topRight, w.topRight, w.topLeft], shade);
    face([o.bottomLeft, o.topLeft, w.topLeft, w.bottomLeft], halfShade);
    face([o.topRight, o.bottomRight, w.bottomRight, w.topRight], coreColor);
    face([o.bottomRight, o.bottomLeft, w.bottomLeft, w.bottomRight], lit);
  }

  @override
  bool shouldRepaint(covariant MatPainter oldDelegate) =>
      style != oldDelegate.style ||
      artworkRect != oldDelegate.artworkRect ||
      topMatWindow != oldDelegate.topMatWindow ||
      bevelWidth != oldDelegate.bevelWidth ||
      coreColor != oldDelegate.coreColor ||
      innerColor != oldDelegate.innerColor;
}
