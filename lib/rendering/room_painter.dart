import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame_finish.dart';
import '../models/room_scene.dart';
import 'lighting.dart';
import 'room_viewport.dart';

const _trimColor = Color(0xFFF3F1EC);

Color _grey(double v) {
  final c = v.clamp(0.0, 1.0);
  return Color.from(alpha: 1, red: c, green: c, blue: c);
}

/// Paints the room behind the artwork: wall, ceiling, trim, floor and the
/// way the room is lit. Furniture, which stands in front of the wall, is
/// painted separately by [FurniturePainter].
class RoomBackgroundPainter extends CustomPainter {
  RoomBackgroundPainter({
    required this.scene,
    required this.wallColor,
    required this.viewport,
    required this.light,
    required this.artworkRect,
    this.floorImage,
    this.floorTextures,
  });

  final RoomScene scene;
  final Color wallColor;
  final RoomViewport viewport;
  final Light light;

  /// Where the framed artwork is on screen (for the spotlight and the floor
  /// reflection).
  final Rect artworkRect;

  final ui.Image? floorImage;
  final TextureSet? floorTextures;

  RoomViewport get v => viewport;
  double get px => viewport.scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final left = v.leftMm - 50;
    final right = v.rightMm + 50;
    final wall = v.rect(left: left, right: right, bottom: 0, top: scene.wallHeightMm);

    _paintWall(canvas, wall);
    if (RoomViewport.ceilingStripMm(scene) > 0) _paintSkylightCeiling(canvas, left, right);
    if (scene.crownMoulding) _paintCrownMoulding(canvas, left, right);
    _paintFloor(canvas, left, right);
    if (scene.skirtingMm > 0) _paintSkirting(canvas, left, right);

    // The crease where wall meets floor.
    final crease = v.toScreen(const Offset(0, 0)).dy;
    canvas.drawRect(
      Rect.fromLTRB(0, crease - 30 * px, size.width, crease + 4),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, crease - 30 * px),
          Offset(0, crease + 4),
          [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.22)],
        ),
    );
  }

  void _paintWall(Canvas canvas, Rect wall) {
    final partition = scene.partitionWidthMm;
    if (partition == null) {
      canvas.drawRect(wall, Paint()..color = wallColor);
      _lightWall(canvas, wall);
      return;
    }

    // A freestanding gallery wall in front of the room's own (shadier) walls.
    canvas.drawRect(wall, Paint()..color = Color.lerp(wallColor, Colors.black, 0.14)!);
    final panel = v.rect(left: -partition / 2, right: partition / 2, bottom: 0, top: scene.wallHeightMm);
    for (final edge in [panel.left, panel.right]) {
      final outward = edge == panel.left ? -1.0 : 1.0;
      final shadowWidth = 220 * px;
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(edge, edge + outward * shadowWidth),
          wall.top,
          math.max(edge, edge + outward * shadowWidth),
          wall.bottom,
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(edge, 0),
            Offset(edge + outward * shadowWidth, 0),
            [Colors.black.withValues(alpha: 0.28), Colors.black.withValues(alpha: 0)],
          ),
      );
    }
    canvas.drawRect(panel, Paint()..color = wallColor);
    _lightWall(canvas, panel);
  }

  /// Multiplies the wall's lighting onto it.
  void _lightWall(Canvas canvas, Rect wall) {
    final multiply = Paint()..blendMode = BlendMode.multiply;
    final dir = light.planarDirection;

    switch (scene.lighting) {
      case RoomLighting.soft:
        canvas.drawRect(
          wall,
          multiply
            ..shader = ui.Gradient.linear(
              wall.topCenter,
              wall.bottomCenter,
              [_grey(0.93), _grey(1), _grey(0.9)],
              [0, 0.35, 1],
            ),
        );
        // A little brighter on the side the light comes from.
        canvas.drawRect(
          wall,
          Paint()
            ..blendMode = BlendMode.multiply
            ..shader = ui.Gradient.linear(
              wall.centerLeft,
              wall.centerRight,
              [_grey(1 - 0.07 * (1 + dir.dx)), _grey(1 - 0.07 * (1 - dir.dx))],
            ),
        );

      case RoomLighting.spotlight:
        // A pool of light on the artwork from a ceiling spot, the rest of the
        // wall falling into shade.
        final centre = artworkRect.center +
            Offset(dir.dx * artworkRect.width * 0.12, -artworkRect.height * 0.18);
        final radius = math.max(artworkRect.width, artworkRect.height) * 1.4 + 900 * px;
        final stretch = Matrix4.identity()
          ..translateByDouble(centre.dx, centre.dy, 0, 1)
          ..scaleByDouble(1, 1.3, 1, 1)
          ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
        canvas.drawRect(
          wall,
          multiply
            ..shader = ui.Gradient.radial(
              centre,
              radius,
              [_grey(1), _grey(0.97), _grey(0.86), _grey(0.74)],
              [0, 0.25, 0.6, 1],
              TileMode.clamp,
              stretch.storage,
            ),
        );
        canvas.drawRect(
          wall,
          Paint()
            ..blendMode = BlendMode.multiply
            ..shader = ui.Gradient.linear(
              wall.topCenter,
              wall.bottomCenter,
              [_grey(0.82), _grey(1), _grey(0.95)],
              [0, 0.4, 1],
            ),
        );

      case RoomLighting.skylight:
        canvas.drawRect(
          wall,
          multiply
            ..shader = ui.Gradient.linear(
              wall.topCenter,
              wall.bottomCenter,
              [_grey(1), _grey(0.9)],
            ),
        );
    }
  }

  void _paintSkylightCeiling(Canvas canvas, double left, double right) {
    final strip = v.rect(left: left, right: right, bottom: scene.wallHeightMm, top: v.topMm);
    canvas.drawRect(
      strip,
      Paint()
        ..shader = ui.Gradient.linear(
          strip.bottomCenter,
          strip.topCenter,
          [const Color(0xFFE9EDEF), const Color(0xFFFBFCFC)],
        ),
    );
    // Panel grid, flaring outwards towards the viewer for a sense of depth.
    final grid = Paint()
      ..color = const Color(0xFFB9C0C4)
      ..strokeWidth = math.max(1.0, 22 * px);
    const spacing = 1200.0;
    for (var x = (left / spacing).floor() * spacing; x <= right; x += spacing) {
      canvas.drawLine(
        v.toScreen(Offset(x, scene.wallHeightMm)),
        v.toScreen(Offset(x * 1.5, v.topMm)),
        grid,
      );
    }
    for (final f in [0.0, 0.45, 1.0]) {
      final y = scene.wallHeightMm + (v.topMm - scene.wallHeightMm) * f;
      canvas.drawLine(v.toScreen(Offset(left, y)), v.toScreen(Offset(right, y)), grid);
    }
  }

  void _paintCrownMoulding(Canvas canvas, double left, double right) {
    const depth = 90.0;
    final band = v.rect(left: left, right: right, bottom: scene.wallHeightMm - depth, top: scene.wallHeightMm);
    canvas.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          band.topCenter,
          band.bottomCenter,
          [const Color(0xFFFAF9F5), const Color(0xFFDCD8CE)],
        ),
    );
    final shadow = Rect.fromLTRB(band.left, band.bottom, band.right, band.bottom + 45 * px);
    canvas.drawRect(
      shadow,
      Paint()
        ..shader = ui.Gradient.linear(
          shadow.topCenter,
          shadow.bottomCenter,
          [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0)],
        ),
    );
  }

  void _paintSkirting(Canvas canvas, double left, double right) {
    final board = v.rect(left: left, right: right, bottom: 0, top: scene.skirtingMm);
    canvas.drawRect(
      board,
      Paint()
        ..shader = ui.Gradient.linear(
          board.topCenter,
          board.bottomCenter,
          [Colors.white, _trimColor, const Color(0xFFE4E1D9)],
          [0, 0.15, 1],
        ),
    );
    canvas.drawLine(
      board.topLeft,
      board.topRight,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..strokeWidth = math.max(1.0, 6 * px),
    );
  }

  void _paintFloor(Canvas canvas, double left, double right) {
    final floor = v.rect(left: left, right: right, bottom: v.bottomMm, top: 0);
    if (floor.isEmpty) return;
    canvas.save();
    canvas.clipRect(floor);

    final textures = floorTextures;
    final image = floorImage;
    if (scene.floor == FloorKind.concrete) {
      _paintConcrete(canvas, floor);
    } else if (textures != null && image != null) {
      _paintPlanks(canvas, floor, image, textures);
    } else {
      canvas.drawRect(floor, Paint()..color = const Color(0xFF8A6A4E));
    }

    // Darker where the floor meets the wall, lighter towards the viewer.
    canvas.drawRect(
      floor,
      Paint()
        ..blendMode = BlendMode.multiply
        ..shader = ui.Gradient.linear(
          floor.topCenter,
          floor.bottomCenter,
          [_grey(0.72), _grey(0.95), _grey(1)],
          [0, 0.35, 1],
        ),
    );

    // Polished floors catch a soft reflection of the lit artwork.
    final gloss = switch (scene.floor) {
      FloorKind.concrete => 0.22,
      FloorKind.walnut => 0.12,
      _ => 0.06,
    };
    final streak = Rect.fromLTRB(
      artworkRect.left - artworkRect.width * 0.05,
      floor.top,
      artworkRect.right + artworkRect.width * 0.05,
      floor.bottom,
    );
    canvas.drawRect(
      streak,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, 60 * px))
        ..shader = ui.Gradient.linear(
          streak.topCenter,
          streak.bottomCenter,
          [Colors.white.withValues(alpha: gloss), Colors.white.withValues(alpha: 0)],
        ),
    );
    canvas.restore();
  }

  /// Rows of planks running along the wall, narrowing with distance.
  void _paintPlanks(Canvas canvas, Rect floor, ui.Image image, TextureSet textures) {
    const rows = 9;
    final texPxPerMm = image.width / textures.sizeMm;
    final random = math.Random(7);

    double rowY(int i) => floor.top + floor.height * math.pow(i / rows, 1.6);

    for (var i = 0; i < rows; i++) {
      final top = rowY(i);
      final bottom = rowY(i + 1);
      final depth = (i + 0.5) / rows; // 0 at the wall, 1 at the viewer
      final perspective = 0.55 + 0.45 * depth;

      final along = px * perspective / texPxPerMm; // screen px per texture px, along the plank
      final across = (bottom - top) / (150 * texPxPerMm); // a 150 mm wide board fills the row
      final matrix = Matrix4.identity()
        ..translateByDouble(random.nextDouble() * image.width * along, top, 0, 1)
        ..scaleByDouble(along, across, 1, 1);
      if (textures.grainVertical) matrix.rotateZ(math.pi / 2);

      final row = Rect.fromLTRB(floor.left, top, floor.right, bottom);
      canvas.drawRect(
        row,
        Paint()
          ..shader = ImageShader(image, TileMode.repeated, TileMode.repeated, matrix.storage)
          ..filterQuality = FilterQuality.medium,
      );
      if (scene.floor == FloorKind.walnut) {
        canvas.drawRect(row, Paint()
          ..blendMode = BlendMode.multiply
          ..color = const Color(0xFF8C6C5C));
      }

      final seam = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = math.max(0.6, 4 * px * perspective);
      canvas.drawLine(row.topLeft, row.topRight, seam);
      // Board ends, staggered row to row.
      final boardLength = 1200 * px * perspective;
      for (var x = floor.left - random.nextDouble() * boardLength; x < floor.right; x += boardLength) {
        canvas.drawLine(Offset(x, top), Offset(x, bottom), seam);
      }
    }
  }

  void _paintConcrete(Canvas canvas, Rect floor) {
    canvas.drawRect(
      floor,
      Paint()
        ..shader = ui.Gradient.linear(
          floor.topCenter,
          floor.bottomCenter,
          [const Color(0xFFADA89F), const Color(0xFF8D887F)],
        ),
    );
    // Mottling, fixed per scene so it doesn't flicker.
    final random = math.Random(11);
    for (var i = 0; i < 16; i++) {
      final centre = Offset(
        floor.left + random.nextDouble() * floor.width,
        floor.top + random.nextDouble() * floor.height,
      );
      final radius = (250 + random.nextDouble() * 700) * px;
      final dark = random.nextBool();
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(centre, radius, [
            (dark ? Colors.black : Colors.white).withValues(alpha: 0.07),
            (dark ? Colors.black : Colors.white).withValues(alpha: 0),
          ]),
      );
    }
    // Saw-cut joints converging towards the wall.
    final joint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = math.max(0.8, 8 * px);
    const spacing = 2400.0;
    final depth = v.bottomMm;
    for (var x = ((v.leftMm * 2) / spacing).floor() * spacing; x <= v.rightMm * 2; x += spacing) {
      canvas.drawLine(v.toScreen(Offset(x / 1.8, 0)), v.toScreen(Offset(x, depth)), joint);
    }
    final midY = floor.top + floor.height * 0.42;
    canvas.drawLine(Offset(floor.left, midY), Offset(floor.right, midY), joint);
  }

  @override
  bool shouldRepaint(covariant RoomBackgroundPainter old) =>
      old.scene != scene ||
      old.wallColor != wallColor ||
      old.viewport.scale != viewport.scale ||
      old.viewport.focus != viewport.focus ||
      old.viewport.screen != viewport.screen ||
      old.light != light ||
      old.artworkRect != artworkRect ||
      old.floorImage != floorImage;
}

/// Paints furniture standing in front of the wall, over the artwork if the
/// artwork is dragged down behind it.
class FurniturePainter extends CustomPainter {
  FurniturePainter({required this.furniture, required this.viewport, required this.light});

  final Furniture furniture;
  final RoomViewport viewport;
  final Light light;

  /// Furniture stands a little in front of the wall, so its feet sit on the
  /// visible floor.
  static double baseMm(RoomViewport v) => v.bottomMm * 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final v = viewport;
    final px = v.scale;
    final base = baseMm(v);
    final w = furniture.widthMm;
    final h = furniture.heightMm;

    Rect part(double l, double r, double b, double t) =>
        v.rect(left: l, right: r, bottom: base + b, top: base + t);

    // Shadow cast on the wall behind, and contact shadow on the floor.
    final outline = part(-w / 2, w / 2, 0, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outline.shift(light.shadowOffset(220 * px)), Radius.circular(40 * px)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, 70 * px)),
    );
    final feet = v.toScreen(Offset(0, base));
    canvas.drawOval(
      Rect.fromCenter(center: feet, width: outline.width * 1.05, height: 70 * px),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, 30 * px)),
    );

    void block(Rect rect, Color color, {double radius = 0}) {
      final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius * px));
      // Lit from above and from the light's side.
      final dir = light.planarDirection;
      canvas.drawRRect(
        shape,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            [Color.lerp(color, Colors.white, 0.12)!, color, Color.lerp(color, Colors.black, 0.25)!],
            [0, 0.3, 1],
          ),
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..blendMode = BlendMode.multiply
          ..shader = ui.Gradient.linear(
            rect.centerLeft,
            rect.centerRight,
            [_grey(1 - 0.08 * (1 + dir.dx)), _grey(1 - 0.08 * (1 - dir.dx))],
          ),
      );
    }

    void line(Offset a, Offset b, {double alpha = 0.3}) => canvas.drawLine(
          a,
          b,
          Paint()
            ..color = Colors.black.withValues(alpha: alpha)
            ..strokeWidth = math.max(0.8, 8 * px),
        );

    switch (furniture) {
      case Furniture.sofa:
        const fabric = Color(0xFF5D6166);
        const legs = Color(0xFF2A221C);
        for (final x in [-w / 2 + 120, w / 2 - 160]) {
          block(part(x, x + 40, 0, 130), legs);
        }
        block(part(-w / 2 + 160, w / 2 - 160, 420, h), fabric, radius: 70); // back
        block(part(-w / 2, w / 2, 120, 430), Color.lerp(fabric, Colors.black, 0.1)!, radius: 30); // base
        const armWidth = 190.0;
        final seatLeft = -w / 2 + armWidth;
        final seatRight = w / 2 - armWidth;
        block(part(seatLeft, seatRight, 380, 540), fabric, radius: 50); // seat cushions
        final cushion = (seatRight - seatLeft) / 3;
        for (var i = 1; i < 3; i++) {
          final x = seatLeft + cushion * i;
          line(v.toScreen(Offset(x, base + 380)), v.toScreen(Offset(x, base + 540)));
        }
        block(part(-w / 2, -w / 2 + armWidth, 120, 650), fabric, radius: 70); // arms
        block(part(w / 2 - armWidth, w / 2, 120, 650), fabric, radius: 70);

      case Furniture.sideboard:
        const wood = Color(0xFF7A5539);
        const legs = Color(0xFF3B2A20);
        for (final x in [-w / 2 + 60, w / 2 - 100]) {
          block(part(x, x + 40, 0, 160), legs);
        }
        block(part(-w / 2, w / 2, 150, h - 25), wood, radius: 8);
        block(part(-w / 2 - 10, w / 2 + 10, h - 25, h), Color.lerp(wood, Colors.white, 0.1)!, radius: 6);
        for (final x in [-w / 6, w / 6]) {
          line(v.toScreen(Offset(x, base + 170)), v.toScreen(Offset(x, base + h - 40)), alpha: 0.35);
        }
        for (final x in [-w / 6 - 60, w / 6 - 60, w / 2 - 60]) {
          block(part(x, x + 25, h * 0.55, h * 0.55 + 90), const Color(0xFFC9B48A), radius: 6); // handles
        }

      case Furniture.bench:
        const seat = Color(0xFF2F3537);
        const wood = Color(0xFF2B2019);
        for (final x in [-w / 2 + 70, w / 2 - 210]) {
          block(part(x, x + 140, 0, 400), wood, radius: 6);
        }
        block(part(-w / 2, w / 2, 395, h), seat, radius: 14);
    }
  }

  @override
  bool shouldRepaint(covariant FurniturePainter old) =>
      old.furniture != furniture ||
      old.viewport.scale != viewport.scale ||
      old.viewport.focus != viewport.focus ||
      old.viewport.screen != viewport.screen ||
      old.light != light;
}
