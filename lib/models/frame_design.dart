import 'dart:ui';

import 'frame_finish.dart';
import 'mat_spec.dart';
import 'moulding.dart';

/// A complete framing job, measured in physical millimetres.
///
/// This is the single source of truth for rendering, and later for saved
/// drafts, the order spec sheet and pricing.
class FrameDesign {
  const FrameDesign({
    required this.artworkMm,
    required this.moulding,
    required this.mat,
    required this.finish,
  });

  /// Visible artwork size. Its aspect ratio matches the uploaded image.
  final Size artworkMm;
  final Moulding moulding;
  final MatSpec mat;
  final FrameFinish finish;

  /// Artwork plus mat borders: the size the frame's inner edge wraps around.
  Size get matOuterMm => Size(
        artworkMm.width + mat.horizontalMm,
        artworkMm.height + mat.verticalMm,
      );

  /// Overall size of the finished frame, outer edge to outer edge.
  Size get outerMm {
    final faces = moulding.faceWidthMm * 2;
    return Size(matOuterMm.width + faces, matOuterMm.height + faces);
  }

  /// Moulding length needed, measured along the outer edges of the mitres.
  double get mouldingLengthMm => 2 * (outerMm.width + outerMm.height);

  /// Resizes the artwork to [widthMm], keeping its aspect ratio.
  FrameDesign withArtworkWidth(double widthMm) {
    final aspect = artworkMm.width / artworkMm.height;
    return copyWith(artworkMm: Size(widthMm, widthMm / aspect));
  }

  /// Applies a new aspect ratio (width / height), keeping the current width.
  FrameDesign withArtworkAspect(double aspect) {
    return copyWith(artworkMm: Size(artworkMm.width, artworkMm.width / aspect));
  }

  FrameDesign copyWith({
    Size? artworkMm,
    Moulding? moulding,
    MatSpec? mat,
    FrameFinish? finish,
  }) {
    return FrameDesign(
      artworkMm: artworkMm ?? this.artworkMm,
      moulding: moulding ?? this.moulding,
      mat: mat ?? this.mat,
      finish: finish ?? this.finish,
    );
  }
}
