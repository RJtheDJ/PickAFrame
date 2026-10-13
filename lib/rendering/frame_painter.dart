import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame_profile.dart';
import 'lighting.dart';
import 'moulding_shading.dart';

/// What is wrapped onto the moulding's face.
sealed class RailSkin {
  const RailSkin();
}

class SolidSkin extends RailSkin {
  const SolidSkin(this.color);

  final Color color;

  @override
  bool operator ==(Object other) => other is SolidSkin && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// A tileable material texture (wood grain), true to physical scale.
class TextureSkin extends RailSkin {
  const TextureSkin(this.image, {required this.sizeMm, required this.grainVertical});

  final ui.Image image;
  final double sizeMm;
  final bool grainVertical;

  @override
  bool operator ==(Object other) =>
      other is TextureSkin &&
      other.image == image &&
      other.sizeMm == sizeMm &&
      other.grainVertical == grainVertical;

  @override
  int get hashCode => Object.hash(image, sizeMm, grainVertical);
}

/// A photographed moulding strip: outer edge on the image's top row, inner
/// edge on its bottom row, repeating left to right.
class StripSkin extends RailSkin {
  const StripSkin(this.image, {required this.mirror});

  final ui.Image image;
  final bool mirror;

  @override
  bool operator ==(Object other) =>
      other is StripSkin && other.image == image && other.mirror == mirror;

  @override
  int get hashCode => Object.hash(image, mirror);
}

/// One mitred side of the frame.
///
/// Each rail has a local coordinate system: u runs along the rail and v runs
/// across it, from the outer edge (v = 0) to the inner edge (v = face width).
/// [origin] and [angle] map that local system onto the canvas.
class Rail {
  const Rail({
    required this.path,
    required this.origin,
    required this.angle,
    required this.outward,
    required this.length,
  });

  final Path path;
  final Offset origin;
  final double angle;

  /// Unit vector pointing out of the frame through this rail's outer edge.
  final Offset outward;

  /// Length of the rail's outer edge.
  final double length;

  /// Maps a point from rail-local (u, v) to canvas coordinates.
  Offset toCanvas(Offset local) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return origin + Offset(local.dx * c - local.dy * s, local.dx * s + local.dy * c);
  }
}

/// The four mitred rails of a frame of [size] with [faceWidth]-wide mouldings.
List<Rail> railsFor(Size size, double faceWidth) {
  final w = size.width;
  final h = size.height;
  final fw = faceWidth;
  return [
    Rail(
      path: Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(w - fw, fw)..lineTo(fw, fw)..close(),
      origin: Offset.zero,
      angle: 0,
      outward: const Offset(0, -1),
      length: w,
    ),
    Rail(
      path: Path()..moveTo(w, 0)..lineTo(w, h)..lineTo(w - fw, h - fw)..lineTo(w - fw, fw)..close(),
      origin: Offset(w, 0),
      angle: math.pi / 2,
      outward: const Offset(1, 0),
      length: h,
    ),
    Rail(
      path: Path()..moveTo(w, h)..lineTo(0, h)..lineTo(fw, h - fw)..lineTo(w - fw, h - fw)..close(),
      origin: Offset(w, h),
      angle: math.pi,
      outward: const Offset(0, 1),
      length: w,
    ),
    Rail(
      path: Path()..moveTo(0, h)..lineTo(0, 0)..lineTo(fw, fw)..lineTo(fw, h - fw)..close(),
      origin: Offset(0, h),
      angle: -math.pi / 2,
      outward: const Offset(-1, 0),
      length: h,
    ),
  ];
}

/// Paints the four mitred rails of the frame, filling the canvas. The mat and
/// artwork are drawn on top by `FrameRenderer`.
class FramePainter extends CustomPainter {
  FramePainter({
    required this.faceWidth,
    required this.pxPerMm,
    required this.profile,
    required this.skin,
    required this.material,
    required this.light,
  });

  final double faceWidth;
  final double pxPerMm;
  final FrameProfile profile;
  final RailSkin skin;
  final SurfaceMaterial material;
  final Light light;

  @override
  void paint(Canvas canvas, Size size) {
    final rails = railsFor(size, faceWidth);
    for (var i = 0; i < rails.length; i++) {
      _paintRail(canvas, rails[i], i);
    }
    paintFrameJoins(canvas, size, faceWidth);
  }

  void _paintRail(Canvas canvas, Rail rail, int index) {
    canvas.drawPath(rail.path, _basePaint(rail, index));

    if (skin is StripSkin) {
      // The photo already carries the profile's shading.
      final light = photoRailLight(this.light, rail.outward);
      _paintTone(canvas, rail.path, light);
      return;
    }

    final shading = shadeRail(
      profile: profile,
      outward: rail.outward,
      light: light,
      material: material,
    );
    final outer = rail.toCanvas(Offset.zero);
    final inner = rail.toCanvas(Offset(0, faceWidth));
    canvas.drawPath(
      rail.path,
      Paint()
        ..blendMode = BlendMode.multiply
        ..shader = ui.Gradient.linear(outer, inner, shading.shadows, shading.stops),
    );
    canvas.drawPath(
      rail.path,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(outer, inner, shading.highlights, shading.stops),
    );
  }

  Paint _basePaint(Rail rail, int index) {
    final paint = Paint();
    switch (skin) {
      case SolidSkin(:final color):
        paint.color = color;

      case TextureSkin(:final image, :final sizeMm, :final grainVertical):
        final scale = sizeMm * pxPerMm / image.width;
        final matrix = Matrix4.identity()
          ..translateByDouble(rail.origin.dx, rail.origin.dy, 0, 1)
          ..rotateZ(rail.angle)
          // Each rail is cut from a different part of the board, so the grain
          // doesn't continue around the corners.
          ..translateByDouble(index * 173.0 * pxPerMm, index * 61.0 * pxPerMm, 0, 1)
          ..rotateZ(grainVertical ? math.pi / 2 : 0)
          ..scaleByDouble(scale, scale, 1, 1);
        paint
          ..shader = ImageShader(image, TileMode.repeated, TileMode.repeated, matrix.storage)
          ..filterQuality = FilterQuality.medium;

      case StripSkin(:final image, :final mirror):
        // The strip's height spans the face exactly; it repeats along the rail.
        final scale = faceWidth / image.height;
        final tileLength = image.width * scale;
        // Centre the pattern on each rail so opposite rails match.
        final offset = mirror ? rail.length / 2 : (rail.length - tileLength) / 2;
        final matrix = Matrix4.identity()
          ..translateByDouble(rail.origin.dx, rail.origin.dy, 0, 1)
          ..rotateZ(rail.angle)
          ..translateByDouble(offset, 0, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1);
        paint
          ..shader = ImageShader(
            image,
            mirror ? TileMode.mirror : TileMode.repeated,
            TileMode.clamp,
            matrix.storage,
          )
          ..filterQuality = FilterQuality.medium;
    }
    return paint;
  }

  /// Darkens (below 1) or brightens (above 1) a whole rail.
  void _paintTone(Canvas canvas, Path path, double light) {
    if (light < 1) {
      final v = light.clamp(0.0, 1.0);
      canvas.drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.multiply
          ..color = Color.from(alpha: 1, red: v, green: v, blue: v),
      );
    } else {
      final v = ((light - 1) * 0.5).clamp(0.0, 1.0);
      canvas.drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.screen
          ..color = Color.from(alpha: 1, red: v, green: v, blue: v),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) =>
      faceWidth != oldDelegate.faceWidth ||
      pxPerMm != oldDelegate.pxPerMm ||
      profile != oldDelegate.profile ||
      skin != oldDelegate.skin ||
      material != oldDelegate.material ||
      light != oldDelegate.light;
}

/// Hairlines at the mitre joints and along the outer and inner edges of a
/// frame filling [size], which is where real mouldings catch a sliver of
/// shadow.
void paintFrameJoins(Canvas canvas, Size size, double faceWidth) {
  final w = size.width;
  final h = size.height;
  final fw = faceWidth;
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..color = Colors.black.withValues(alpha: 0.35);
  canvas
    ..drawLine(Offset.zero, Offset(fw, fw), line)
    ..drawLine(Offset(w, 0), Offset(w - fw, fw), line)
    ..drawLine(Offset(w, h), Offset(w - fw, h - fw), line)
    ..drawLine(Offset(0, h), Offset(fw, h - fw), line)
    ..drawRect((Offset.zero & size).deflate(0.4), line)
    ..drawRect(Rect.fromLTRB(fw, fw, w - fw, h - fw), line);
}
