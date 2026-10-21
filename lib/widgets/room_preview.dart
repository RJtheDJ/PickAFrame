import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame_design.dart';
import '../models/units.dart';
import '../rendering/lighting.dart';
import '../rendering/room_painter.dart';
import '../rendering/room_viewport.dart';
import '../rendering/shaded_frame_painter.dart';
import '../services/texture_service.dart';
import '../view_models/room_preview_viewmodel.dart';
import 'frame_renderer.dart';

/// The framed artwork hung in a room at true size. Drag it to move it.
class RoomPreview extends StatelessWidget {
  const RoomPreview({
    super.key,
    required this.room,
    required this.design,
    required this.light,
    this.finishImages,
    this.shaderResources,
    this.artworkImage,
    this.exportKey,
  });

  final RoomPreviewViewModel room;
  final FrameDesign design;
  final Light light;
  final FinishImages? finishImages;
  final FrameShaderResources? shaderResources;
  final ui.Image? artworkImage;

  /// Key for the [RepaintBoundary] around the room, which export renders.
  final GlobalKey? exportKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = constraints.biggest;
        final scene = room.scene;
        final frameMm = design.outerMm;
        final centreMm = room.hangingCentre(frameMm);
        final viewport = RoomViewport.fit(
          screen: screen,
          scene: scene,
          zoom: room.zoom,
          focusMm: centreMm,
        );
        final artworkRect = Rect.fromCenter(
          center: viewport.toScreen(centreMm),
          width: frameMm.width * viewport.scale,
          height: frameMm.height * viewport.scale,
        );
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
                          light: light,
                          artworkRect: artworkRect,
                          floorImage: room.floorImage,
                          floorTextures: room.floorTextureSet,
                        ),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: artworkRect,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) =>
                            room.moveArtwork(viewport.screenDeltaToMm(details.delta), frameMm),
                        child: FrameRenderer(
                          design: design,
                          light: light,
                          finishImages: finishImages,
                          shaderResources: shaderResources,
                          artworkImage: artworkImage,
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
                              light: light,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Not part of the exported image.
            Positioned(
              left: 12,
              top: 12,
              child: _Label(
                'Centre ${formatLength(centreMm.dy)} from floor'
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
