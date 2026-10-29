import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame_design.dart';
import '../models/units.dart';
import '../rendering/room_painter.dart';
import '../rendering/room_viewport.dart';
import '../rendering/shaded_frame_painter.dart';
import '../services/texture_service.dart';
import '../view_models/room_preview_viewmodel.dart';
import 'frame_renderer.dart';

/// One framed artwork to hang in the room.
class RoomPiece {
  const RoomPiece({required this.id, required this.design, this.artwork, this.finishImages});

  final String id;
  final FrameDesign design;

  /// The cropped artwork, or null for a placeholder.
  final ui.Image? artwork;

  /// Texture maps for the piece's finish, or null while they load.
  final FinishImages? finishImages;
}

/// Framed artworks hung in a room at true size, side by side. Drag a piece
/// to move it.
class RoomPreview extends StatelessWidget {
  const RoomPreview({
    super.key,
    required this.room,
    required this.pieces,
    this.shaderResources,
    this.exportKey,
  });

  final RoomPreviewViewModel room;
  final List<RoomPiece> pieces;
  final FrameShaderResources? shaderResources;

  /// Key for the [RepaintBoundary] around the room, which export renders.
  final GlobalKey? exportKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = constraints.biggest;
        final scene = room.scene;
        final framesMm = {for (final piece in pieces) piece.id: piece.design.outerMm};
        final centresMm = room.centres(framesMm);

        // Zoom towards the middle of the group.
        final focusMm = centresMm.isEmpty
            ? const Offset(0, 1450)
            : centresMm.values.reduce((a, b) => a + b) / centresMm.length.toDouble();
        final viewport = RoomViewport.fit(screen: screen, scene: scene, zoom: room.zoom, focusMm: focusMm);

        final rects = {
          for (final piece in pieces)
            piece.id: Rect.fromCenter(
              center: viewport.toScreen(centresMm[piece.id]!),
              width: framesMm[piece.id]!.width * viewport.scale,
              height: framesMm[piece.id]!.height * viewport.scale,
            ),
        };
        final group = rects.isEmpty
            ? Rect.fromCenter(center: viewport.toScreen(focusMm), width: 1, height: 1)
            : rects.values.reduce((a, b) => a.expandToInclude(b));
        final labelled = room.lastMoved ?? pieces.firstOrNull?.id;
        final furniture = scene.furniture;

        return Stack(
          children: [
            RepaintBoundary(
              key: exportKey,
              child: SizedBox.fromSize(
                size: screen,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: RoomBackgroundPainter(
                          scene: scene,
                          wallColor: room.wallColor,
                          viewport: viewport,
                          light: room.light,
                          artworkRect: group,
                          floorImage: room.floorImage,
                          floorTextures: room.floorTextureSet,
                        ),
                      ),
                    ),
                    for (final piece in pieces)
                      Positioned.fromRect(
                        rect: rects[piece.id]!,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) => room.moveArtwork(
                            piece.id,
                            viewport.screenDeltaToMm(details.delta),
                            framesMm,
                          ),
                          child: FrameRenderer(
                            design: piece.design,
                            light: room.light,
                            finishImages: piece.finishImages,
                            shaderResources: shaderResources,
                            artworkImage: piece.artwork,
                            wallColor: null,
                            wallMargin: 0,
                          ),
                        ),
                      ),
                    if (furniture != null && room.showFurniture)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: FurniturePainter(
                              furniture: furniture,
                              viewport: viewport,
                              light: room.light,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Not part of the exported image.
            if (labelled != null)
              Positioned(
                left: 12,
                top: 12,
                child: _Label(
                  'Centre ${formatLength(centresMm[labelled]!.dy)} from floor'
                  '${room.isDragged ? '' : '  ·  drag to move'}',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}
