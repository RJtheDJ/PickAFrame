import 'dart:typed_data';

/// An uploaded artwork image, plus its pixel dimensions.
class Artwork {
  const Artwork({
    required this.bytes,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final Uint8List bytes;
  final int pixelWidth;
  final int pixelHeight;

  /// Width / height.
  double get aspectRatio => pixelWidth / pixelHeight;
}
