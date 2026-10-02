import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_finish.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_presets.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/rendering/frame_layout.dart';

FrameDesign _design(MatSpec mat) => FrameDesign(
      artworkMm: const Size(400, 300),
      moulding: const Moulding(profile: FrameProfile.flat, faceWidthMm: 30),
      mat: mat,
      finish: const ColorFinish(Color(0xFF000000)),
    );

void main() {
  group('presets', () {
    test('golden ratio border makes mat area φ times artwork area', () {
      const art = Size(400, 300);
      final w = goldenMatWidthMm(art);
      final matArea = (art.width + 2 * w) * (art.height + 2 * w);
      expect(matArea / (art.width * art.height), closeTo(goldenRatio, 1e-9));
    });

    test('3:1 rule is three moulding widths', () {
      expect(threeToOneMatWidthMm(30), 90);
    });
  });

  group('MatSpec', () {
    test('withSide edits one side only', () {
      final mat = const MatSpec.uniform(50).withSide(MatSide.bottom, 70);
      expect([mat.topMm, mat.bottomMm, mat.leftMm, mat.rightMm], [50, 70, 50, 50]);
      expect(mat.isUniform, isFalse);
    });

    test('mount style does not change overall size', () {
      const mat = MatSpec.uniform(50);
      expect(
        _design(mat.copyWith(style: MountStyle.doubleMat)).outerMm,
        _design(mat).outerMm,
      );
    });
  });

  group('FrameLayout matting', () {
    // 1 px per mm: outer size is 400+100+60 by 300+100+60.
    const available = Size(560, 460);

    test('flat mat window is the artwork', () {
      final layout = FrameLayout.fit(_design(const MatSpec.uniform(50)), available);
      expect(layout.topMatWindow, layout.artworkRect);
      expect(layout.bevelWidth, MatSpec.bevelMm);
    });

    test('double mat window is larger by the reveal', () {
      const mat = MatSpec(
        topMm: 50, bottomMm: 50, leftMm: 50, rightMm: 50,
        style: MountStyle.doubleMat, revealMm: 8,
      );
      final layout = FrameLayout.fit(_design(mat), available);
      expect(layout.topMatWindow, layout.artworkRect.inflate(8));
    });

    test('reveal is limited to the narrowest border', () {
      const mat = MatSpec(
        topMm: 50, bottomMm: 50, leftMm: 4, rightMm: 50,
        style: MountStyle.doubleMat, revealMm: 10,
      );
      // 1 px per mm: 400 + 4 + 50 + 60 wide.
      final layout = FrameLayout.fit(_design(mat), const Size(514, 460));
      expect(layout.topMatWindow, layout.artworkRect.inflate(4));
    });
  });
}
