import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_finish.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/rendering/frame_layout.dart';

void main() {
  const design = FrameDesign(
    artworkMm: Size(400, 300),
    moulding: Moulding(profile: FrameProfile.flat, faceWidthMm: 30),
    mat: MatSpec(topMm: 50, bottomMm: 70, leftMm: 40, rightMm: 40),
    finish: ColorFinish(Color(0xFF000000)),
  );

  group('FrameDesign', () {
    test('adds mat borders and moulding faces to the artwork size', () {
      expect(design.matOuterMm, const Size(480, 420));
      expect(design.outerMm, const Size(540, 480));
      expect(design.mouldingLengthMm, 2 * (540 + 480));
    });

    test('withArtworkWidth keeps the aspect ratio', () {
      expect(design.withArtworkWidth(800).artworkMm, const Size(800, 600));
    });

    test('withArtworkAspect keeps the width', () {
      expect(design.withArtworkAspect(0.5).artworkMm, const Size(400, 800));
    });
  });

  group('FrameLayout', () {
    test('scales to fit the limiting dimension', () {
      // 540 x 480 mm into 270 x 1000 px: width limits, 0.5 px per mm.
      final layout = FrameLayout.fit(design, const Size(270, 1000));
      expect(layout.pxPerMm, 0.5);
      expect(layout.outerSize, const Size(270, 240));
      expect(layout.faceWidth, 15);
      expect(layout.matRect, const Rect.fromLTWH(15, 15, 240, 210));
    });

    test('artwork window keeps the artwork aspect ratio and mat offsets', () {
      final layout = FrameLayout.fit(design, const Size(540, 480));
      expect(layout.artworkRect, const Rect.fromLTWH(30 + 40, 30 + 50, 400, 300));
      expect(layout.artworkRect.width / layout.artworkRect.height, 400 / 300);
    });
  });
}
