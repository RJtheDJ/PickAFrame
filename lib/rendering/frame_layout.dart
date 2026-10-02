import 'dart:math' as math;
import 'dart:ui';

import '../models/frame_design.dart';

/// Converts a [FrameDesign] in millimetres into on-screen rectangles, scaled
/// to fit the available space.
class FrameLayout {
  const FrameLayout._({
    required this.pxPerMm,
    required this.outerSize,
    required this.faceWidth,
    required this.matRect,
    required this.artworkRect,
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

    return FrameLayout._(
      pxPerMm: scale,
      outerSize: outer * scale,
      faceWidth: face,
      matRect: matRect,
      artworkRect: Rect.fromLTWH(
        matRect.left + design.mat.leftMm * scale,
        matRect.top + design.mat.topMm * scale,
        design.artworkMm.width * scale,
        design.artworkMm.height * scale,
      ),
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
}
