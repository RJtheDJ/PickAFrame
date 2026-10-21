import 'dart:math' as math;
import 'dart:ui';

import '../models/room_scene.dart';

/// Maps room coordinates to the screen. Room coordinates are millimetres:
/// x across the wall from its centre line, y up from the floor.
///
/// At zoom 1 the whole wall height plus a strip of floor fills the screen
/// height. Zooming in moves the view towards [focusMm] (the artwork), without
/// ever showing past the ceiling or the front of the floor.
class RoomViewport {
  RoomViewport._(this.screen, this.scale, this.focus, this.topMm, this.bottomMm);

  factory RoomViewport.fit({
    required Size screen,
    required RoomScene scene,
    required double zoom,
    required Offset focusMm,
  }) {
    final top = scene.wallHeightMm + ceilingStripMm(scene);
    final bottom = -floorDepthMm(scene);
    final scale = screen.height / (top - bottom) * zoom;

    // Ease from the room's centre at zoom 1 to the artwork from zoom 2.
    final roomCentre = Offset(0, (top + bottom) / 2);
    final t = ((zoom - 1) / 1).clamp(0.0, 1.0);
    final wanted = Offset.lerp(roomCentre, focusMm, t)!;

    final halfHeight = screen.height / 2 / scale;
    final focusY = halfHeight * 2 >= top - bottom
        ? (top + bottom) / 2
        : wanted.dy.clamp(bottom + halfHeight, top - halfHeight);
    return RoomViewport._(screen, scale, Offset(wanted.dx, focusY), top, bottom);
  }

  /// Visible depth of floor in front of the wall.
  static double floorDepthMm(RoomScene scene) => scene.wallHeightMm * 0.22;

  /// Visible strip of (skylight) ceiling above the wall.
  static double ceilingStripMm(RoomScene scene) =>
      scene.lighting == RoomLighting.skylight ? 600 : 0;

  final Size screen;

  /// Screen pixels per millimetre.
  final double scale;

  /// Room point shown at the centre of the screen.
  final Offset focus;
  final double topMm;
  final double bottomMm;

  Offset toScreen(Offset mm) => Offset(
        screen.width / 2 + (mm.dx - focus.dx) * scale,
        screen.height / 2 - (mm.dy - focus.dy) * scale,
      );

  /// Screen rectangle of a room rectangle given by its edges in mm.
  Rect rect({required double left, required double right, required double bottom, required double top}) =>
      Rect.fromPoints(toScreen(Offset(left, top)), toScreen(Offset(right, bottom)));

  /// Converts a finger movement on screen to a movement in the room.
  Offset screenDeltaToMm(Offset delta) => Offset(delta.dx / scale, -delta.dy / scale);

  /// Half the visible width of the room, in mm.
  double get halfWidthMm => screen.width / 2 / scale;

  /// Left and right edges of the screen, in room mm.
  double get leftMm => focus.dx - halfWidthMm;
  double get rightMm => focus.dx + halfWidthMm;

  /// Zoom range for the slider.
  static const minZoom = 1.0;
  static const maxZoom = 4.0;

  /// The x-range the artwork can be dragged across, in mm either side of the
  /// wall's centre line.
  static double dragRangeMm(RoomScene scene) =>
      scene.partitionWidthMm != null ? scene.partitionWidthMm! / 2 : 2500;

  @override
  String toString() => 'RoomViewport(scale: ${scale.toStringAsFixed(4)}, focus: $focus)';

  /// Used by tests: the room point at a screen position.
  Offset toMm(Offset screenPoint) => Offset(
        focus.dx + (screenPoint.dx - screen.width / 2) / scale,
        focus.dy - (screenPoint.dy - screen.height / 2) / scale,
      );

  /// The visible room height, in mm.
  double get visibleHeightMm => math.min(topMm - bottomMm, screen.height / scale);
}
