import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../models/artwork.dart';

/// Lets the user pick an artwork from their gallery. Returns null if cancelled.
Future<Artwork?> pickArtworkFromGallery() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 4096,
    maxHeight: 4096,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();

  // Decode once to get the displayed dimensions (after EXIF rotation), which
  // set the artwork's aspect ratio.
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final artwork = Artwork(
    bytes: bytes,
    pixelWidth: image.width,
    pixelHeight: image.height,
  );
  image.dispose();
  codec.dispose();
  return artwork;
}
