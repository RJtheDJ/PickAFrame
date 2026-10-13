import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/artwork.dart';
import '../models/perspective.dart';
import '../services/artwork_service.dart';

/// Lets the user drag four handles onto the corners of their artwork in a
/// photo. The result is cut out and straightened, which removes the wall or
/// table around it and corrects photos taken at a slight angle.
///
/// Pops with the cropped [Artwork], or null if cancelled.
class ArtworkCropScreen extends StatefulWidget {
  const ArtworkCropScreen({super.key, required this.source, this.initialCorners});

  final ui.Image source;

  /// Corners from an earlier crop of [source], to adjust them.
  final Quad? initialCorners;

  @override
  State<ArtworkCropScreen> createState() => _ArtworkCropScreenState();
}

class _ArtworkCropScreenState extends State<ArtworkCropScreen> {
  static const _padding = 28.0;
  static const _handleSize = 44.0;
  static const _magnifierSize = 120.0;

  late ui.Image _source = widget.source;
  late Quad _corners = widget.initialCorners ?? _fullImage;
  int? _dragging;
  bool _busy = false;

  Quad get _fullImage =>
      Quad.full(Size(_source.width.toDouble(), _source.height.toDouble()));

  Future<void> _rotate() async {
    setState(() => _busy = true);
    final oldHeight = _source.height.toDouble();
    final rotated = await rotateClockwise(_source);
    // A quarter turn clockwise moves (x, y) to (oldHeight - y, x), and the
    // old bottom-left corner becomes the new top-left.
    Offset turn(Offset p) => Offset(oldHeight - p.dy, p.dx);
    final c = _corners;
    if (!mounted) return;
    setState(() {
      _source = rotated;
      _corners = Quad(turn(c.bottomLeft), turn(c.topLeft), turn(c.topRight), turn(c.bottomRight));
      _busy = false;
    });
  }

  Future<void> _done() async {
    setState(() => _busy = true);
    try {
      final artwork = await cropArtwork(_source, _corners);
      if (mounted) Navigator.of(context).pop(artwork);
    } catch (e) {
      debugPrint('Crop failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t crop with those corners. Try moving them apart.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop artwork'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            tooltip: 'Rotate',
            onPressed: _busy ? null : _rotate,
          ),
          IconButton(
            icon: const Icon(Icons.crop_free),
            tooltip: 'Reset to whole photo',
            onPressed: _busy ? null : () => setState(() => _corners = _fullImage),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Drag each corner onto a corner of your artwork',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(child: LayoutBuilder(builder: (context, constraints) => _cropArea(constraints))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _busy ? null : _done,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Use artwork'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cropArea(BoxConstraints constraints) {
    final imageSize = Size(_source.width.toDouble(), _source.height.toDouble());
    final scale = math.min(
      (constraints.maxWidth - 2 * _padding) / imageSize.width,
      (constraints.maxHeight - 2 * _padding) / imageSize.height,
    );
    final display = imageSize * scale;
    final origin = Offset(
      (constraints.maxWidth - display.width) / 2,
      (constraints.maxHeight - display.height) / 2,
    );

    Offset toScreen(Offset p) => origin + p * scale;
    Offset toImage(Offset s) {
      final p = (s - origin) / scale;
      return Offset(p.dx.clamp(0.0, imageSize.width), p.dy.clamp(0.0, imageSize.height));
    }

    final screenCorners = _corners.map(toScreen);
    final dragging = _dragging;

    return Stack(
      children: [
        Positioned(
          left: origin.dx,
          top: origin.dy,
          width: display.width,
          height: display.height,
          child: RawImage(image: _source, fit: BoxFit.fill),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _CropOverlayPainter(quad: screenCorners, imageRect: origin & display),
          ),
        ),
        for (var i = 0; i < 4; i++)
          Positioned(
            left: screenCorners.points[i].dx - _handleSize / 2,
            top: screenCorners.points[i].dy - _handleSize / 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => setState(() => _dragging = i),
              onPanUpdate: (details) {
                final moved = _corners.withPoint(
                  i,
                  toImage(toScreen(_corners.points[i]) + details.delta),
                );
                // Refuse moves that would twist the shape inside out.
                if (moved.isConvex) setState(() => _corners = moved);
              },
              onPanEnd: (_) => setState(() => _dragging = null),
              child: SizedBox.square(
                dimension: _handleSize,
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withValues(alpha: 0.35),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (dragging != null) _magnifier(screenCorners.points[dragging], constraints),
      ],
    );
  }

  /// Enlarged view of the corner being dragged, shown in the top corner away
  /// from the finger.
  Widget _magnifier(Offset target, BoxConstraints constraints) {
    const half = _magnifierSize / 2;
    final onLeft = target.dx > constraints.maxWidth / 2;
    final center = Offset(onLeft ? 12 + half : constraints.maxWidth - 12 - half, 12 + half);
    return Positioned(
      left: center.dx - half,
      top: center.dy - half,
      child: IgnorePointer(
        child: RawMagnifier(
          size: const Size.square(_magnifierSize),
          magnificationScale: 2.5,
          focalPointOffset: target - center,
          decoration: const MagnifierDecoration(
            shape: CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
          ),
          child: const Center(child: Icon(Icons.add, color: Colors.white70, size: 20)),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.quad, required this.imageRect});

  final Quad quad;
  final Rect imageRect;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()..addPolygon(quad.points, true);

    // Dim everything that will be cut away.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(imageRect)
        ..addPath(outline, Offset.zero),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Thirds guides, following the quad's perspective.
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final f in [1 / 3, 2 / 3]) {
      canvas
        ..drawLine(
          Offset.lerp(quad.topLeft, quad.topRight, f)!,
          Offset.lerp(quad.bottomLeft, quad.bottomRight, f)!,
          guide,
        )
        ..drawLine(
          Offset.lerp(quad.topLeft, quad.bottomLeft, f)!,
          Offset.lerp(quad.topRight, quad.bottomRight, f)!,
          guide,
        );
    }

    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.imageRect != imageRect || oldDelegate.quad.points.toString() != quad.points.toString();
}
