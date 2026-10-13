import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/units.dart';
import 'package:pickaframe_application/rendering/moulding_shading.dart';

void main() {
  group('formatLength', () {
    test('shows centimetres, dropping a trailing .0', () {
      expect(formatLength(400), '40 cm');
      expect(formatLength(47), '4.7 cm');
      expect(formatLength(5), '0.5 cm');
    });

    test('switches to metres from one metre', () {
      expect(formatLength(999), '99.9 cm');
      expect(formatLength(1000), '1.00 m');
      expect(formatLength(1250), '1.25 m');
    });
  });

  group('formatSize', () {
    test('both sides in the same unit', () {
      expect(formatSize(const Size(400, 300)), '40 × 30 cm');
      expect(formatSize(const Size(1200, 900)), '1.20 × 0.90 m');
    });
  });

  group('profileLookupPixels', () {
    test('a flat profile is level across the middle of the face', () {
      final pixels = profileLookupPixels(FrameProfile.flat);
      // Slope 0 is stored as mid-grey (127 or 128).
      expect(pixels[128 * 4], inInclusiveRange(127, 128));
    });

    test('a slope falling towards the art stores negative slope', () {
      final pixels = profileLookupPixels(FrameProfile.slope);
      expect(pixels[128 * 4], lessThan(127));
    });

    test('coves are darker (more occluded) than the open face', () {
      final pixels = profileLookupPixels(FrameProfile.scoop);
      final coveBottom = pixels[(0.56 * 255).round() * 4 + 1];
      final flatFace = profileLookupPixels(FrameProfile.flat)[128 * 4 + 1];
      expect(coveBottom, lessThan(flatFace));
    });
  });
}
