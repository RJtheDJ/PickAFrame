import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame_design.dart';
import '../models/mat_spec.dart';
import '../rendering/frame_layout.dart';
import '../rendering/generative_frame_painter.dart';
import '../rendering/mat_painter.dart';

/// Draws a [FrameDesign] at true proportions, scaled to fit its parent.
class FrameRenderer extends StatelessWidget {
  const FrameRenderer({
    super.key,
    required this.design,
    required this.frameColor,
    this.frameTexture,
    this.artworkBytes,
  });

  final FrameDesign design;
  final Color frameColor;

  /// When set, painted instead of [frameColor].
  final ui.Image? frameTexture;

  /// The uploaded artwork, or null to show a placeholder.
  final Uint8List? artworkBytes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = FrameLayout.fit(design, constraints.biggest);

        return Center(
          child: Container(
            width: layout.outerSize.width,
            height: layout.outerSize.height,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(10, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: GenerativeFramePainter(
                      faceWidth: layout.faceWidth,
                      profile: design.moulding.profile,
                      color: frameColor,
                      texture: frameTexture,
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: layout.matRect,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: design.mat.color,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          spreadRadius: -1,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: MatPainter(
                      style: design.mat.style,
                      artworkRect: layout.artworkRect,
                      topMatWindow: layout.topMatWindow,
                      bevelWidth: layout.bevelWidth,
                      coreColor: design.mat.coreColor,
                      innerColor: design.mat.innerColor,
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: layout.artworkRect,
                  child: DecoratedBox(
                    // A floated artwork stands off the board and casts a shadow.
                    decoration: BoxDecoration(
                      boxShadow: design.mat.style == MountStyle.float
                          ? [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 4 * layout.pxPerMm,
                                offset: Offset(1.5, 3) * layout.pxPerMm,
                              ),
                            ]
                          : null,
                    ),
                    // The window already has the artwork's aspect ratio, so
                    // `cover` fills it exactly without cropping.
                    child: artworkBytes != null
                        ? Image.memory(
                            artworkBytes!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : const _ArtworkPlaceholder(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF2C3E50),
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: Colors.white70, size: 48),
              SizedBox(height: 8),
              Text('Your artwork here', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
