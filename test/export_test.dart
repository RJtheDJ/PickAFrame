import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/data/finish_catalog.dart';
import 'package:pickaframe_application/models/design_summary.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/rendering/lighting.dart';
import 'package:pickaframe_application/services/export_service.dart';
import 'package:pickaframe_application/widgets/frame_renderer.dart';

void main() {
  final design = FrameDesign(
    artworkMm: const Size(400, 300),
    moulding: const Moulding(profile: FrameProfile.scoop, faceWidthMm: 40),
    mat: const MatSpec.uniform(60),
    finish: woodFinishes.first,
  );

  group('designSummaryText', () {
    test('lists sizes, frame and mat in cm', () {
      expect(designSummaryText(design), [
        'Artwork: 40 × 30 cm',
        'Overall: 60 × 50 cm',
        'Frame: Cherry, Scoop, 4 cm wide',
        'Mat: Single mat, 6 cm all round',
      ].join('\n'));
    });

    test('describes uneven borders and the double-mat reveal', () {
      final doubleMat = design.copyWith(
        mat: const MatSpec(
          topMm: 60, bottomMm: 75, leftMm: 60, rightMm: 60,
          style: MountStyle.doubleMat, revealMm: 6,
        ),
      );
      expect(
        describeDesign(doubleMat).last.$2,
        'Double mat, top 6 cm, bottom 7.5 cm, left 6 cm, right 6 cm, 0.6 cm reveal',
      );
    });

    test('photographed mouldings leave out the generated profile', () {
      final ornate = design.copyWith(finish: photoMouldings.first);
      expect(describeDesign(ornate)[2].$2, 'Ornate gold scroll, 4 cm wide');
    });
  });

  test('export file names are date-stamped', () {
    expect(exportFileName(DateTime(2026, 10, 5, 9, 3, 7)), 'pickaframe_20261005_090307');
  });

  testWidgets('renders the framed piece to a high-resolution PNG', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 500,
        child: FrameRenderer(design: design, light: const Light(), exportKey: key),
      ),
    ));

    final png = await tester.runAsync(() => renderPng(key));
    final size = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(png!);
      final image = (await codec.getNextFrame()).image;
      return Size(image.width.toDouble(), image.height.toDouble());
    });

    expect(size!.longestSide, closeTo(exportLongSidePx, 1));
    // A 60 x 50 cm frame plus an even margin of wall (7% of 60 cm) each side.
    expect(size.width / size.height, closeTo((60 + 8.4) / (50 + 8.4), 0.005));
  });
}
