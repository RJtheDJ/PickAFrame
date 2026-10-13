import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

/// Google's ML Kit document scanner is only available on Android (through
/// Google Play services). Elsewhere the manual corner crop is used.
bool get isArtworkScannerAvailable =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Opens Google's scanner: it finds the artwork's edges in the camera view
/// (or in a gallery photo), lets the user adjust the corners, and returns it
/// already cropped and straightened. Returns null if the user cancels.
Future<ui.Image?> scanArtwork() async {
  final scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormats: const {DocumentFormat.jpeg},
      pageLimit: 1,
      // Crop and rotate only. The other modes add document filters and
      // "stain removal", which would alter the artwork's colours and marks.
      mode: ScannerMode.base,
      isGalleryImport: true,
    ),
  );
  try {
    final result = await scanner.scanDocument();
    final path = result.images?.firstOrNull;
    if (path == null) return null;

    final codec = await ui.instantiateImageCodec(await XFile(path).readAsBytes());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return image;
  } on PlatformException catch (e) {
    // Backing out of the scanner is reported as an error.
    if (e.message?.toLowerCase().contains('cancel') ?? false) return null;
    rethrow;
  } finally {
    await scanner.close();
  }
}
