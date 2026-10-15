import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

/// Longest side of an exported mock-up, in pixels: sharp enough to print at
/// A4 and for social media.
const exportLongSidePx = 3000.0;

/// Album the mock-ups are saved into.
const _album = 'PickAFrame';

/// Thrown when the user refuses permission to save to their photos.
class GalleryPermissionDenied implements Exception {
  const GalleryPermissionDenied();
}

/// Saving straight into the photo gallery is supported on phones; on other
/// platforms the mock-up can still be shared (or downloaded, on the web).
bool get canSaveToGallery =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Re-renders the widget under [boundaryKey] (a [RepaintBoundary]) at high
/// resolution, rather than screenshotting it at screen resolution. The frame
/// is drawn with vector painters and shaders, so it stays crisp at any size.
Future<Uint8List> renderPng(GlobalKey boundaryKey, {double longSidePx = exportLongSidePx}) async {
  final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: longSidePx / boundary.size.longestSide);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// A file name like `pickaframe_20261015_143005`, without extension.
String exportFileName([DateTime? time]) {
  final t = time ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'pickaframe_${t.year}${two(t.month)}${two(t.day)}_'
      '${two(t.hour)}${two(t.minute)}${two(t.second)}';
}

/// Saves [png] into the "PickAFrame" album, asking for permission if needed.
Future<void> saveToGallery(Uint8List png) async {
  if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
    throw const GalleryPermissionDenied();
  }
  await Gal.putImageBytes(png, album: _album, name: exportFileName());
}

/// Opens the system share sheet with [png] and a [message]. [origin] is where
/// the sheet points from on tablets.
Future<void> sharePng(Uint8List png, {String? message, Rect? origin}) async {
  final name = '${exportFileName()}.png';
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
    fileNameOverrides: [name],
    text: message,
    sharePositionOrigin: origin,
  ));
}
