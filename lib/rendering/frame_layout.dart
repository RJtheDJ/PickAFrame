import 'dart:math' as math;
import 'dart:ui';

import '../models/frame_design.dart';
import '../models/mat_spec.dart';

/// Converts a [FrameDesign] in millimetres into on-screen rectangles, scaled
/// to fit the available space.
class FrameLayout {
  const FrameLayout._({
    required this.pxPerMm,
    required this.outerSize,
    required this.faceWidth,
    required this.matRect,
    required this.artworkRect,
    required this.topMatWindow,
    required this.bevelWidth,
  });

  factory FrameLayout.fit(FrameDesign design, Size available) {
    final outer = design.outerMm;
    final scale = math.min(
      available.width / outer.width,
      available.height / outer.height,
    );
    final face = design.moulding.faceWidthMm * scale;
    final matOuter = design.matOuterMm;
    final matRect = Rect.fromLTWH(
      face,
      face,
      matOuter.width * scale,
      matOuter.height * scale,
    );

    final mat = design.mat;
    final artworkRect = Rect.fromLTWH(
      matRect.left + mat.leftMm * scale,
      matRect.top + mat.topMm * scale,
      design.artworkMm.width * scale,
      design.artworkMm.height * scale,
    );

    // The reveal can't be wider than the narrowest border.
    final narrowestBorder = [mat.topMm, mat.bottomMm, mat.leftMm, mat.rightMm].reduce(math.min);
    final revealMm = mat.style == MountStyle.doubleMat
        ? math.min(mat.revealMm, narrowestBorder)
        : 0.0;

    return FrameLayout._(
      pxPerMm: scale,
      outerSize: outer * scale,
      faceWidth: face,
      matRect: matRect,
      artworkRect: artworkRect,
      topMatWindow: artworkRect.inflate(revealMm * scale),
      bevelWidth: MatSpec.bevelMm * scale,
    );
  }

  final double pxPerMm;

  /// Whole frame, outer edge to outer edge.
  final Size outerSize;

  /// Moulding face width in pixels.
  final double faceWidth;

  /// Mat board, relative to the frame's top-left corner.
  final Rect matRect;

  /// Artwork window, relative to the frame's top-left corner. Always has the
  /// artwork's exact aspect ratio.
  final Rect artworkRect;

  /// Window cut in the top mat. Equals [artworkRect] unless double matting,
  /// where it is larger by the reveal.
  final Rect topMatWindow;

  /// Visible width of a mat's bevel cut, in pixels.
  final double bevelWidth;
}
