import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import '../models/frame_profile.dart';

/// Paints the four mitred rails of the frame, filling [size]. The mat and
/// artwork are drawn on top by `FrameRenderer`.
class GenerativeFramePainter extends CustomPainter {
  final double faceWidth;
  final FrameProfile profile;
  final Color color;

  /// When set, painted instead of [color].
  final ui.Image? texture;

  GenerativeFramePainter({
    required this.faceWidth,
    required this.profile,
    required this.color,
    this.texture,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double fw = faceWidth;

    Paint getEdgePaint(double rotationAngle) {
      final Paint paint = Paint();
      if (texture != null) {
        final Float64List matrix = (Matrix4.identity()..rotateZ(rotationAngle)).storage;
        paint.shader = ImageShader(texture!, TileMode.repeated, TileMode.repeated, matrix);
      } else {
        paint.color = color;
      }
      return paint;
    }

    void drawEdge(Path path, double rotation, Rect bounds, Alignment gradBegin, Alignment gradEnd) {
      // Draw base material with mitered texture rotation
      canvas.drawPath(path, getEdgePaint(rotation));
      
      // Multi-tier 2.5D Lighting Overlay
      if (profile != FrameProfile.flat) {
        final Paint overlayPaint = Paint();
        List<Color> colors = [];
        List<double>? stops;

        switch (profile) {
          case FrameProfile.beveled:
            // Multi-tier contour matching Frame It:
            // - Outer edge rim highlight (0.00 -> 0.12)
            // - Deep cove/scoop drop (0.12 -> 0.65)
            // - Raised inner step/bead ridge (0.65 -> 0.85)
            // - Inner lip shadow falling onto mat (0.85 -> 1.00)
            colors = [
              Colors.white.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.70),
              Colors.white.withValues(alpha: 0.20),
              Colors.black.withValues(alpha: 0.20),
              Colors.black.withValues(alpha: 0.85),
            ];
            stops = [0.0, 0.12, 0.65, 0.78, 0.88, 1.0];
            break;

          case FrameProfile.slope:
            // smooth convex curve, and a very deep inner crease.
            colors = [
              Colors.white.withValues(alpha: 0.40), // Brilliant outer highlight
              Colors.white.withValues(alpha: 0.10), // Gradual mid-tone
              Colors.black.withValues(alpha: 0.50), // Lower slope shadow
              Colors.black.withValues(alpha: 0.90), // Very dark inner lip
            ];
            stops = [0.0, 0.15, 0.85, 1.0];
            break;

          case FrameProfile.reverseSlope: 
            colors = [Colors.white.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.55)];
            break;

          case FrameProfile.scoop: 
            // Thin outer ridge (0.00 -> 0.05)
            // Sharp drop into a dark trench (0.06)
            // Long concave sweep transitioning to a bright peak (0.06 -> 0.80)
            // Flat inner bead dropping to a dark shadow (0.80 -> 1.00)
            colors = [
              Colors.white.withValues(alpha: 0.50), // Outer ridge highlight
              Colors.white.withValues(alpha: 0.50), // Outer ridge edge
              Colors.black.withValues(alpha: 0.80), // Deep trench shadow
              Colors.black.withValues(alpha: 0.20), // Mid-curve transition
              Colors.white.withValues(alpha: 0.60), // Bright sweeping peak
              Colors.black.withValues(alpha: 0.20), // Inner flat bead
              Colors.black.withValues(alpha: 0.90), // Final inner drop shadow
            ];
            stops = [0.0, 0.05, 0.06, 0.45, 0.80, 0.85, 1.0];
            break;

          case FrameProfile.curve: 
            colors = [
              Colors.black.withValues(alpha: 0.50), // Outer bottom edge shadow
              Colors.white.withValues(alpha: 0.60), // Soft top crest highlight
              Colors.black.withValues(alpha: 0.10), // Mid-curve transition
              Colors.black.withValues(alpha: 0.70), // Deep inner curve shadow
              Colors.black.withValues(alpha: 0.20), // Flat inner step transition
              Colors.black.withValues(alpha: 0.90), // Final drop shadow against the mat
            ];
            stops = [0.0, 0.25, 0.55, 0.85, 0.86, 1.0];
            break;

          case FrameProfile.triangular: 
            colors = [
              Colors.black.withValues(alpha: 0.15), // Outer edge base
              Colors.white.withValues(alpha: 0.55), // Bright upward peak highlight
              Colors.black.withValues(alpha: 0.60), // Hard shadow immediately over the crest
              Colors.black.withValues(alpha: 0.75), // Deepening shadow down the inner slope
              Colors.black.withValues(alpha: 0.20), // Inner flat lip
              Colors.black.withValues(alpha: 0.95), // Final inner drop shadow against the mat
            ];
            stops = [0.0, 0.49, 0.50, 0.90, 0.91, 1.0];
            break;

          case FrameProfile.stepped:
            colors = [
              Colors.white.withValues(alpha: 0.45), // Ridge 1 Highlight
              Colors.black.withValues(alpha: 0.50), // Ridge 1 Crease
              Colors.white.withValues(alpha: 0.45), // Ridge 2 Highlight
              Colors.black.withValues(alpha: 0.50), // Ridge 2 Crease
              Colors.white.withValues(alpha: 0.45), // Ridge 3 Highlight
              Colors.black.withValues(alpha: 0.50), // Ridge 3 Crease
              Colors.white.withValues(alpha: 0.10), // Inner flat section
              Colors.black.withValues(alpha: 0.85), // Final drop shadow
            ];
            // Notice how the stops are paired tightly to create sharp drops
            stops = [0.0, 0.25, 0.26, 0.55, 0.56, 0.85, 0.86, 1.0];
            break;

          case FrameProfile.flat:
            break;
        }

        if (colors.isNotEmpty) {
          overlayPaint.shader = ui.Gradient.linear(
            gradBegin.alongSize(bounds.size) + bounds.topLeft,
            gradEnd.alongSize(bounds.size) + bounds.topLeft,
            colors,
            stops,
          );
          canvas.drawPath(path, overlayPaint);
        }
      }
    }

    final Path topPath = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(w - fw, fw)..lineTo(fw, fw)..close();
    drawEdge(topPath, 0, Rect.fromLTWH(0, 0, w, fw), Alignment.topCenter, Alignment.bottomCenter);

    final Path rightPath = Path()..moveTo(w, 0)..lineTo(w, h)..lineTo(w - fw, h - fw)..lineTo(w - fw, fw)..close();
    drawEdge(rightPath, math.pi / 2, Rect.fromLTWH(w - fw, 0, fw, h), Alignment.centerRight, Alignment.centerLeft);

    final Path bottomPath = Path()..moveTo(w, h)..lineTo(0, h)..lineTo(fw, h - fw)..lineTo(w - fw, h - fw)..close();
    drawEdge(bottomPath, math.pi, Rect.fromLTWH(0, h - fw, w, fw), Alignment.bottomCenter, Alignment.topCenter);

    final Path leftPath = Path()..moveTo(0, h)..lineTo(0, 0)..lineTo(fw, fw)..lineTo(fw, h - fw)..close();
    drawEdge(leftPath, -math.pi / 2, Rect.fromLTWH(0, 0, fw, h), Alignment.centerLeft, Alignment.centerRight);
  }

  @override
  bool shouldRepaint(covariant GenerativeFramePainter oldDelegate) =>
      faceWidth != oldDelegate.faceWidth ||
      profile != oldDelegate.profile ||
      color != oldDelegate.color ||
      texture != oldDelegate.texture;
}