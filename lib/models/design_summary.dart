import 'frame_design.dart';
import 'frame_finish.dart';
import 'mat_spec.dart';
import 'units.dart';

/// Human-readable lines describing a [FrameDesign], e.g. for the message
/// shared with an exported mock-up. The groundwork for the order
/// specification sheet.
List<(String label, String value)> describeDesign(FrameDesign design) {
  final mat = design.mat;
  final finish = design.finish;
  final profile = finish is PhotoMouldingFinish ? null : design.moulding.profile.label;

  return [
    ('Artwork', formatSize(design.artworkMm)),
    ('Overall', formatSize(design.outerMm)),
    (
      'Frame',
      [finish.name, ?profile, '${formatLength(design.moulding.faceWidthMm)} wide'].join(', '),
    ),
    ('Mat', _describeMat(mat)),
  ];
}

/// [describeDesign] as plain text, one line per item.
String designSummaryText(FrameDesign design) =>
    describeDesign(design).map((line) => '${line.$1}: ${line.$2}').join('\n');

String _describeMat(MatSpec mat) {
  final borders = mat.isUniform
      ? '${formatLength(mat.topMm)} all round'
      : 'top ${formatLength(mat.topMm)}, bottom ${formatLength(mat.bottomMm)}, '
          'left ${formatLength(mat.leftMm)}, right ${formatLength(mat.rightMm)}';
  return switch (mat.style) {
    MountStyle.flat => 'Single mat, $borders',
    MountStyle.doubleMat => 'Double mat, $borders, ${formatLength(mat.revealMm)} reveal',
    MountStyle.float => 'Float mount, $borders',
  };
}
