import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/mat_spec.dart';
import 'lighting.dart';

/// How far the frame's inner lip stands above the mat.
const _frameLipDepthMm = 8.0;

/// Thickness of a (4-ply) mat board.
const _boardThicknessMm = 1.5;

/// Paints everything on top of the mat board and artwork: the lower mat of a
/// double mat, the 45° bevel cuts, and the shadows cast by the frame lip and
/// the mat's window edges. Drawn over the artwork, so it must never cover the
/// artwork window itself except with shadow. Coordinates are relative to the
/// whole frame.
class MatPainter extends CustomPainter {
  MatPainter({
    required this.style,
    required this.matRect,
    required this.artworkRect,
    required this.topMatWindow,
    required this.bevelWidth,
    required this.pxPerMm,
    required this.coreColor,
    required this.innerColor,
    required this.light,
  });

  final MountStyle style;
  final Rect matRect;
  final Rect artworkRect;
  final Rect topMatWindow;
  final double bevelWidth;
  final double pxPerMm;
  final Color coreColor;
  final Color innerColor;
  final Light light;

  @override
  void paint(Canvas canvas, Size size) {
    final board = _boardThicknessMm * pxPerMm;

    switch (style) {
      case MountStyle.float:
        break; // The artwork's own drop shadow is drawn by FrameRenderer.
      case MountStyle.flat:
        _paintBevel(canvas, artworkRect);
        _paintInnerShadow(canvas, artworkRect, board, 0.35);
      case MountStyle.doubleMat:
        // Only the reveal band; the artwork sits inside it.
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(topMatWindow)
            ..addRect(artworkRect),
          Paint()..color = innerColor,
        );
        _paintBevel(canvas, artworkRect);
        _paintInnerShadow(canvas, artworkRect, board, 0.35);
        _paintBevel(canvas, topMatWindow);
        // The top mat's edge shades the reveal band.
        _paintInnerShadow(canvas, topMatWindow, board, 0.3, exclude: artworkRect.inflate(bevelWidth));
    }

    // The frame's lip shades the mat: a soft contact shadow all round, and a
    // longer cast shadow on the side the light comes from.
    _paintInnerShadow(canvas, matRect, 2.5 * pxPerMm, 0.22, directional: false);
    _paintInnerShadow(canvas, matRect, _frameLipDepthMm * pxPerMm, 0.3);
  }

  /// Draws the bevel as four trapezoids around [window], each lit according
  /// to which way it faces (the cut slopes down into the window).
  void _paintBevel(Canvas canvas, Rect window) {
    final o = window.inflate(bevelWidth);
    final w = window;
    const s = math.sqrt1_2; // 45° cut

    Color lit(Offset towardWindow) {
      final r = light.relativeDiffuse(towardWindow.dx * s, towardWindow.dy * s, s);
      return r < 1
          ? Color.lerp(coreColor, Colors.black, (1 - r) * 0.7)!
          : Color.lerp(coreColor, Colors.white, ((r - 1) * 0.8).clamp(0.0, 1.0))!;
    }

    void face(List<Offset> points, Color color) {
      canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
    }

    face([o.topLeft, o.topRight, w.topRight, w.topLeft], lit(const Offset(0, 1)));
    face([o.topRight, o.bottomRight, w.bottomRight, w.topRight], lit(const Offset(-1, 0)));
    face([o.bottomRight, o.bottomLeft, w.bottomLeft, w.bottomRight], lit(const Offset(0, -1)));
    face([o.bottomLeft, o.topLeft, w.topLeft, w.bottomLeft], lit(const Offset(1, 0)));
  }

  /// Shadow along the inside edges of [rect], cast by a wall [heightPx] tall
  /// standing on its border. When [directional], only edges facing the light
  /// cast it and its width depends on the light's angle; otherwise every edge
  /// gets a soft contact shadow [heightPx] wide.
  void _paintInnerShadow(
    Canvas canvas,
    Rect rect,
    double heightPx,
    double opacity, {
    bool directional = true,
    Rect? exclude,
  }) {
    const edges = [
      (Offset(0, 1), Alignment.topCenter),
      (Offset(-1, 0), Alignment.centerRight),
      (Offset(0, -1), Alignment.bottomCenter),
      (Offset(1, 0), Alignment.centerLeft),
    ];

    canvas.save();
    canvas.clipRect(rect);
    if (exclude != null) {
      canvas.clipPath(Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect)
        ..addRect(exclude));
    }
    for (final (inward, side) in edges) {
      final width = directional ? light.edgeShadowWidth(heightPx, inward) : heightPx;
      if (width < 0.3) continue;

      final start = side.withinRect(rect);
      final end = start + inward * width;
      final band = Rect.fromPoints(
        side.withinRect(rect) - Offset(inward.dy, inward.dx) * rect.longestSide,
        end + Offset(inward.dy, inward.dx) * rect.longestSide,
      );
      canvas.drawRect(
        band,
        Paint()
          ..shader = ui.Gradient.linear(
            start,
            end,
            [Colors.black.withValues(alpha: opacity), Colors.black.withValues(alpha: 0)],
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MatPainter oldDelegate) =>
      style != oldDelegate.style ||
      matRect != oldDelegate.matRect ||
      artworkRect != oldDelegate.artworkRect ||
      topMatWindow != oldDelegate.topMatWindow ||
      bevelWidth != oldDelegate.bevelWidth ||
      pxPerMm != oldDelegate.pxPerMm ||
      coreColor != oldDelegate.coreColor ||
      innerColor != oldDelegate.innerColor ||
      light != oldDelegate.light;
}
