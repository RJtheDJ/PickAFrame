import 'dart:math' as math;
import 'dart:ui';

/// A single directional light shining on the framed piece, like a window or
/// a gallery spotlight. Everything that is shaded (moulding, bevels, shadows)
/// reads from the same light so the whole frame stays consistent.
///
/// Coordinates: x to the right, y down the screen, z out of the screen
/// towards the viewer.
class Light {
  const Light({this.azimuthDeg = -45, this.elevationDeg = 40});

  /// Where the light comes from, in degrees clockwise from straight above:
  /// 0 = above, -90 = left, 90 = right, ±180 = below.
  final double azimuthDeg;

  /// Height of the light above the wall plane, in degrees.
  final double elevationDeg;

  double get _azimuth => azimuthDeg * math.pi / 180;
  double get _elevation => elevationDeg * math.pi / 180;

  /// Unit vector pointing towards the light.
  double get x => math.sin(_azimuth) * math.cos(_elevation);
  double get y => -math.cos(_azimuth) * math.cos(_elevation);
  double get z => math.sin(_elevation);

  /// Unit direction towards the light, flattened onto the screen.
  Offset get planarDirection => Offset(math.sin(_azimuth), -math.cos(_azimuth));

  /// Diffuse (matte) light falling on a surface with normal (nx, ny, nz),
  /// relative to a surface facing the viewer: 1 = the same, below 1 darker,
  /// above 1 brighter.
  double relativeDiffuse(double nx, double ny, double nz) {
    final length = math.sqrt(nx * nx + ny * ny + nz * nz);
    final dot = (nx * x + ny * y + nz * z) / length;
    return math.max(0.0, dot) / z;
  }

  /// Strength (0..1) of the mirror-like highlight a viewer straight in front
  /// sees on a surface with normal (nx, ny, nz). Higher [shininess] gives a
  /// smaller, sharper highlight.
  double specular(double nx, double ny, double nz, double shininess) {
    final length = math.sqrt(nx * nx + ny * ny + nz * nz);
    final nz1 = nz / length;
    final dot = (nx * x + ny * y + nz * z) / length;
    if (dot <= 0) return 0;
    // z component of the light reflected about the normal.
    final reflectedZ = 2 * dot * nz1 - z;
    return math.pow(math.max(0.0, reflectedZ), shininess).toDouble();
  }

  /// How far the shadow of something [heightPx] above a surface falls.
  Offset shadowOffset(double heightPx) =>
      -planarDirection * (heightPx / math.tan(_elevation));

  /// Width of the shadow an edge [heightPx] tall casts onto the surface on
  /// its [inward] side (a unit vector). Zero when the light is behind it.
  double edgeShadowWidth(double heightPx, Offset inward) {
    final facing = -(inward.dx * planarDirection.dx + inward.dy * planarDirection.dy);
    return math.max(0.0, facing) * heightPx / math.tan(_elevation);
  }

  Light copyWith({double? azimuthDeg, double? elevationDeg}) => Light(
        azimuthDeg: azimuthDeg ?? this.azimuthDeg,
        elevationDeg: elevationDeg ?? this.elevationDeg,
      );

  @override
  bool operator ==(Object other) =>
      other is Light && other.azimuthDeg == azimuthDeg && other.elevationDeg == elevationDeg;

  @override
  int get hashCode => Object.hash(azimuthDeg, elevationDeg);
}
