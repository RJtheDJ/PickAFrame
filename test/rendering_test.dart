import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/rendering/frame_painter.dart';
import 'package:pickaframe_application/rendering/lighting.dart';
import 'package:pickaframe_application/rendering/moulding_shading.dart';

double _brightness(Color c) => c.r;

void main() {
  const topLeftLight = Light(azimuthDeg: -45, elevationDeg: 40);

  group('Light', () {
    test('a surface facing the viewer gets relative light 1', () {
      expect(topLeftLight.relativeDiffuse(0, 0, 1), closeTo(1, 1e-9));
    });

    test('surfaces tilted towards the light are brighter', () {
      // Tilted up-left (towards the light) vs down-right (away).
      expect(topLeftLight.relativeDiffuse(-0.5, -0.5, 1), greaterThan(1));
      expect(topLeftLight.relativeDiffuse(0.5, 0.5, 1), lessThan(1));
    });

    test('shadows fall away from the light', () {
      final offset = topLeftLight.shadowOffset(10);
      expect(offset.dx, greaterThan(0));
      expect(offset.dy, greaterThan(0));
    });

    test('only edges between the light and a surface cast shadow on it', () {
      // Light from above: the top edge shades downwards, the bottom one doesn't.
      const above = Light(azimuthDeg: 0);
      expect(above.edgeShadowWidth(10, const Offset(0, 1)), greaterThan(0));
      expect(above.edgeShadowWidth(10, const Offset(0, -1)), 0);
    });
  });

  group('profiles', () {
    test('heights stay within 0..1', () {
      for (final profile in FrameProfile.values) {
        for (var i = 0; i <= 100; i++) {
          final h = profileHeight(profile, i / 100);
          expect(h, inInclusiveRange(0, 1), reason: '$profile at ${i / 100}');
        }
      }
    });

    test('a slope falling towards the art is lit on the bottom rail, shaded on the top', () {
      const above = Light(azimuthDeg: 0);
      double middleBrightness(Offset outward) {
        final shading = shadeRail(
          profile: FrameProfile.slope,
          outward: outward,
          light: above,
          material: SurfaceMaterial.paint,
        );
        final mid = shading.stops.length ~/ 2;
        // Combine the multiply (shadow) and screen (highlight) passes.
        return _brightness(shading.shadows[mid]) + _brightness(shading.highlights[mid]);
      }

      final top = middleBrightness(const Offset(0, -1));
      final bottom = middleBrightness(const Offset(0, 1));
      expect(top, lessThan(1));
      expect(bottom, greaterThan(top));
    });
  });

  group('rails', () {
    const size = Size(300, 200);
    const fw = 20.0;
    final rails = railsFor(size, fw);

    test('local origin is each rail\'s outer starting corner', () {
      expect(rails.map((r) => r.toCanvas(Offset.zero)), [
        Offset.zero,
        const Offset(300, 0),
        const Offset(300, 200),
        const Offset(0, 200),
      ]);
    });

    test('v runs from the outer edge inwards by one face width', () {
      for (final rail in rails) {
        final inner = rail.toCanvas(const Offset(0, fw));
        final outer = rail.toCanvas(Offset.zero);
        final step = inner - outer;
        // Moving across the rail goes opposite to its outward direction.
        expect(step.dx, closeTo(-rail.outward.dx * fw, 1e-9));
        expect(step.dy, closeTo(-rail.outward.dy * fw, 1e-9));
      }
    });

    test('u runs along the outer edge for the rail\'s full length', () {
      for (final rail in rails) {
        final end = rail.toCanvas(Offset(rail.length, 0));
        expect(end.dx, inInclusiveRange(-1e-9, 300 + 1e-9));
        expect(end.dy, inInclusiveRange(-1e-9, 200 + 1e-9));
        expect((end - rail.toCanvas(Offset.zero)).distance, closeTo(rail.length, 1e-9));
      }
    });
  });
}
