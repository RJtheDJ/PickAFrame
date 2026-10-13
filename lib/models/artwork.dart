import 'dart:ui' as ui;

import 'perspective.dart';

/// The user's artwork: the straightened, cropped image shown in the frame,
/// plus the photo it came from and the corners picked on it, so the crop can
/// be adjusted later.
class Artwork {
  const Artwork({required this.image, required this.source, required this.corners});

  /// Cropped and straightened artwork.
  final ui.Image image;

  /// The photo as picked (after any rotation).
  final ui.Image source;

  /// The artwork's corners in [source], in pixels.
  final Quad corners;

  /// Width / height.
  double get aspectRatio => image.width / image.height;
}
