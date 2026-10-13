import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../models/frame_profile.dart';
import 'lighting.dart';

/// How a surface responds to light.
class SurfaceMaterial {
  const SurfaceMaterial({
    required this.specular,
    required this.shininess,
    this.contrast = 1.0,
    this.highlightTint = const Color(0xFFFFFFFF),
  });

  /// Satin paint: soft, broad sheen.
  static const paint = SurfaceMaterial(specular: 0.18, shininess: 10);

  /// Oiled or lacquered wood: soft sheen, the grain does most of the work.
  static const wood = SurfaceMaterial(specular: 0.15, shininess: 8);

  /// Metal leaf or foil: dark where it faces away, sharp highlights tinted by
  /// the metal's own colour.
  factory SurfaceMaterial.metal(Color base) => SurfaceMaterial(
        specular: 0.95,
        shininess: 24,
        contrast: 1.7,
        highlightTint: Color.lerp(base, const Color(0xFFFFFFFF), 0.55)!,
      );

  /// 0..1 strength of the mirror-like highlight.
  final double specular;
  final double shininess;

  /// Exaggerates light and dark (metals reflect their dark surroundings).
  final double contrast;
  final Color highlightTint;
}

/// How much the profile rises out of the wall, as a fraction of face width.
const reliefDepth = 0.35;

double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Cross-section of a moulding: height (0..1) at [t] across the face, from
/// the outer edge (t = 0) to the inner, artwork-side edge (t = 1).
double profileHeight(FrameProfile profile, double t) {
  final double h = switch (profile) {
    FrameProfile.flat => 0.6,
    // Falls towards the artwork.
    FrameProfile.slope => _lerp(1.0, 0.3, t),
    // Rises towards the artwork.
    FrameProfile.reverseSlope => _lerp(0.3, 1.0, t),
    // Outer bead, then a concave cove.
    FrameProfile.scoop => t < 0.12
        ? 0.85 + 0.1 * math.sin(math.pi * t / 0.12)
        : 0.3 + 0.55 * math.pow(2 * (t - 0.12) / 0.88 - 1, 2),
    // Half-round bullnose.
    FrameProfile.curve => 0.2 + 0.8 * math.sqrt(math.sin(math.pi * t)),
    // Ridge along the middle.
    FrameProfile.triangular => 1 - 0.8 * (2 * t - 1).abs(),
    // Three flat steps down towards the artwork, with crisp risers.
    FrameProfile.stepped =>
      1 - 0.3 * (_smoothstep(0.32, 0.345, t) + _smoothstep(0.65, 0.675, t)),
    // Ogee: flat outer rim, S-curve down, then a small inner bead.
    FrameProfile.beveled => t < 0.15
        ? 1.0
        : t < 0.8
            ? 0.35 + 0.65 * (0.5 + 0.5 * math.cos(math.pi * (t - 0.15) / 0.65))
            : 0.35 + 0.2 * math.sin(math.pi * (t - 0.8) / 0.2),
  };
  // Every moulding has a rounded outer edge and drops at its inner lip
  // into the rabbet where the mat sits.
  final outerRound = 0.55 + 0.45 * _smoothstep(0.0, 0.06, t);
  final innerDrop = 0.4 + 0.6 * (1 - _smoothstep(0.95, 1.0, t));
  return h * outerRound * innerDrop;
}

/// Gradient stops to overlay on one rail: [shadows] are multiplied onto the
/// finish (white = unchanged) and [highlights] are screened on top
/// (black = unchanged), so the finish's own colour and grain are kept.
class RailShading {
  const RailShading(this.stops, this.shadows, this.highlights);

  final List<double> stops;
  final List<Color> shadows;
  final List<Color> highlights;
}

/// Lights [profile] for a rail whose outer edge faces [outward] (a unit
/// vector in screen space, e.g. (0, -1) for the top rail).
RailShading shadeRail({
  required FrameProfile profile,
  required Offset outward,
  required Light light,
  required SurfaceMaterial material,
  int samples = 64,
}) {
  final stops = <double>[];
  final shadows = <Color>[];
  final highlights = <Color>[];
  const dt = 0.004;

  for (var i = 0; i <= samples; i++) {
    final t = i / samples;
    final t0 = math.max(0.0, t - dt);
    final t1 = math.min(1.0, t + dt);
    final slope = reliefDepth *
        (profileHeight(profile, t1) - profileHeight(profile, t0)) / (t1 - t0);

    // Where the surface rises towards the artwork it tilts to face outward.
    final nx = outward.dx * slope;
    final ny = outward.dy * slope;
    const nz = 1.0;

    final diffuse = math.pow(light.relativeDiffuse(nx, ny, nz), material.contrast).toDouble();
    final shine = material.specular * light.specular(nx, ny, nz, material.shininess);

    final shade = diffuse.clamp(0.12, 1.0);
    final glow = ((diffuse - 1) * 0.5 + shine).clamp(0.0, 1.0);

    stops.add(t);
    shadows.add(Color.from(alpha: 1, red: shade, green: shade, blue: shade));
    highlights.add(Color.lerp(const Color(0xFF000000), material.highlightTint, glow)!);
  }
  return RailShading(stops, shadows, highlights);
}

/// Overall brightness factor for a photographed moulding on a rail facing
/// [outward]. The photo already contains the profile's shading; this only
/// makes rails facing the light a little brighter than those facing away.
double photoRailLight(Light light, Offset outward) {
  const tilt = 0.3;
  return light.relativeDiffuse(outward.dx * tilt, outward.dy * tilt, 1);
}

/// Largest slope the profile lookup texture can hold; steeper risers are
/// clamped. Must match MAX_SLOPE in shaders/frame_material.frag.
const maxLookupSlope = 6.0;

/// RGBA pixels of a [width] x 1 lookup texture describing [profile] for the
/// GPU shader. Across the face (left to right = outer to inner edge):
///   r: surface slope, mapped from -[maxLookupSlope]..[maxLookupSlope] to 0..255
///   g: ambient occlusion, 255 = fully open, darker in coves and creases.
Uint8List profileLookupPixels(FrameProfile profile, {int width = 256}) {
  final pixels = Uint8List(width * 4);
  const dt = 0.004;
  const curveSpan = 0.03;

  for (var i = 0; i < width; i++) {
    final t = i / (width - 1);
    double h(double x) => profileHeight(profile, x.clamp(0.0, 1.0));

    final t0 = math.max(0.0, t - dt);
    final t1 = math.min(1.0, t + dt);
    final slope = reliefDepth * (h(t1) - h(t0)) / (t1 - t0);

    // Concave spots (coves, the inside corner of a step) catch less light.
    final curvature = (h(t + curveSpan) - 2 * h(t) + h(t - curveSpan)) / (curveSpan * curveSpan);
    final cavity = (curvature * reliefDepth * 0.15).clamp(0.0, 0.45);
    final occlusion = (1 - cavity) * (0.85 + 0.15 * h(t));

    pixels[i * 4] = (((slope / maxLookupSlope).clamp(-1.0, 1.0) * 0.5 + 0.5) * 255).round();
    pixels[i * 4 + 1] = (occlusion.clamp(0.0, 1.0) * 255).round();
    pixels[i * 4 + 2] = 0;
    pixels[i * 4 + 3] = 255;
  }
  return pixels;
}
