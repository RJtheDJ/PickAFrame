import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/artwork.dart';
import '../models/perspective.dart';

/// Longest side of a cropped artwork, in pixels. Plenty for a phone screen
/// and an exported mock-up, while keeping memory in check.
const _maxArtworkSide = 3000;

/// Lets the user take or choose a photo of their artwork. Returns null if
/// cancelled.
Future<ui.Image?> pickArtworkPhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 4096,
    maxHeight: 4096,
  );
  if (file == null) return null;
  return _decode(await file.readAsBytes());
}

/// [image] as PNG bytes for saving, scaled down to at most [maxSide] pixels
/// on its longer side (keeps uploads well under the Worker's 25 MiB limit).
Future<Uint8List> encodeArtworkPng(ui.Image image, {int maxSide = 2048}) async {
  final scale = math.min(1.0, maxSide / math.max(image.width, image.height));
  var source = image;
  if (scale < 1) {
    final width = math.max(1, (image.width * scale).round());
    final height = math.max(1, (image.height * scale).round());
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    source = await picture.toImage(width, height);
    picture.dispose();
  }
  try {
    final data = await source.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    if (!identical(source, image)) source.dispose();
  }
}

/// Turns [image] a quarter turn clockwise.
Future<ui.Image> rotateClockwise(ui.Image image) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..translate(image.height.toDouble(), 0)
    ..rotate(math.pi / 2)
    ..drawImage(image, ui.Offset.zero, ui.Paint()..filterQuality = ui.FilterQuality.none);
  final picture = recorder.endRecording();
  final rotated = await picture.toImage(image.height, image.width);
  picture.dispose();
  return rotated;
}

/// Cuts the artwork out of [source] along [corners] and straightens it into
/// a rectangle, removing the background and any keystone tilt.
Future<Artwork> cropArtwork(ui.Image source, Quad corners) async {
  final size = corners.straightenedSize;
  final scale = math.min(1.0, _maxArtworkSide / size.longestSide);
  final width = math.max(1, (size.width * scale).round());
  final height = math.max(1, (size.height * scale).round());

  final pixels = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
  final job = _WarpJob(
    source: pixels!.buffer.asUint8List(),
    sourceWidth: source.width,
    sourceHeight: source.height,
    homography: Homography.rectToQuad(width.toDouble(), height.toDouble(), corners).coefficients,
    width: width,
    height: height,
  );
  final warped = await compute(_warp, job);

  final image = await _fromPixels(warped, width, height);
  return Artwork(image: image, source: source, corners: corners);
}

class _WarpJob {
  const _WarpJob({
    required this.source,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.homography,
    required this.width,
    required this.height,
  });

  final Uint8List source;
  final int sourceWidth;
  final int sourceHeight;
  final List<double> homography;
  final int width;
  final int height;
}

/// For each output pixel, finds where it lands in the photo and samples it
/// (bilinear). Runs in a background isolate.
Uint8List _warp(_WarpJob job) {
  final h = job.homography;
  final src = job.source;
  final sw = job.sourceWidth;
  final sh = job.sourceHeight;
  final out = Uint8List(job.width * job.height * 4);

  for (var y = 0; y < job.height; y++) {
    final py = y + 0.5;
    for (var x = 0; x < job.width; x++) {
      final px = x + 0.5;
      final w = h[6] * px + h[7] * py + h[8];
      final sx = ((h[0] * px + h[1] * py + h[2]) / w - 0.5).clamp(0.0, sw - 1.0);
      final sy = ((h[3] * px + h[4] * py + h[5]) / w - 0.5).clamp(0.0, sh - 1.0);

      final x0 = sx.floor();
      final y0 = sy.floor();
      final x1 = math.min(x0 + 1, sw - 1);
      final y1 = math.min(y0 + 1, sh - 1);
      final fx = sx - x0;
      final fy = sy - y0;

      final i00 = (y0 * sw + x0) * 4;
      final i10 = (y0 * sw + x1) * 4;
      final i01 = (y1 * sw + x0) * 4;
      final i11 = (y1 * sw + x1) * 4;
      final o = (y * job.width + x) * 4;
      for (var c = 0; c < 4; c++) {
        final top = src[i00 + c] + (src[i10 + c] - src[i00 + c]) * fx;
        final bottom = src[i01 + c] + (src[i11 + c] - src[i01 + c]) * fx;
        out[o + c] = (top + (bottom - top) * fy).round();
      }
    }
  }
  return out;
}

Future<ui.Image> _decode(Uint8List bytes) async {
  // Decoding applies the photo's EXIF orientation.
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  return image;
}

Future<ui.Image> _fromPixels(Uint8List rgba, int width, int height) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return image;
}
