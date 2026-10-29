import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/data/finish_catalog.dart';
import 'package:pickaframe_application/data/room_catalog.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/models/room_scene.dart';
import 'package:pickaframe_application/rendering/room_viewport.dart';
import 'package:pickaframe_application/view_models/room_preview_viewmodel.dart';
import 'package:pickaframe_application/widgets/room_preview.dart';

final livingRoom = roomScenes.firstWhere((s) => s.id == 'living_room');
final whiteCube = roomScenes.firstWhere((s) => s.id == 'white_cube');

void main() {
  group('hanging height', () {
    test('centres at the gallery standard of 145 cm without furniture', () {
      final centre = defaultHangingCentre(whiteCube, const Size(600, 500), showFurniture: false);
      expect(centre, const Offset(0, 1450));
    });

    test('rises to keep clear of furniture', () {
      // Sofa 850 mm + 250 mm clearance + half of a 900 mm frame = 1550 mm.
      final centre = defaultHangingCentre(livingRoom, const Size(1200, 900), showFurniture: true);
      expect(centre.dy, 1550);
    });

    test('dragging stays on the wall, above the skirting and below the ceiling', () {
      const frame = Size(600, 500);
      final low = clampHangingCentre(livingRoom, const Offset(0, 0), frame, halfRangeMm: 2500);
      final high = clampHangingCentre(livingRoom, const Offset(0, 9999), frame, halfRangeMm: 2500);
      final side = clampHangingCentre(livingRoom, const Offset(9999, 1450), frame, halfRangeMm: 2500);
      expect(low.dy - frame.height / 2, greaterThanOrEqualTo(livingRoom.skirtingMm));
      expect(high.dy + frame.height / 2, lessThanOrEqualTo(livingRoom.wallHeightMm));
      expect(side.dx + frame.width / 2, 2500);
    });
  });

  group('RoomViewport', () {
    const screen = Size(400, 600);

    test('at zoom 1 the wall and a strip of floor fill the height', () {
      final v = RoomViewport.fit(screen: screen, scene: livingRoom, zoom: 1, focusMm: const Offset(0, 1450));
      expect(v.toScreen(Offset(0, livingRoom.wallHeightMm)).dy, closeTo(0, 1e-6));
      expect(v.toScreen(Offset(0, -RoomViewport.floorDepthMm(livingRoom))).dy, closeTo(600, 1e-6));
    });

    test('screen and room coordinates convert back and forth', () {
      final v = RoomViewport.fit(screen: screen, scene: livingRoom, zoom: 2.5, focusMm: const Offset(300, 1500));
      const point = Offset(123, 456);
      final back = v.toMm(v.toScreen(point));
      expect(back.dx, closeTo(point.dx, 1e-6));
      expect(back.dy, closeTo(point.dy, 1e-6));
    });

    test('zooming in centres on the artwork but never shows past the ceiling', () {
      final art = RoomViewport.fit(screen: screen, scene: livingRoom, zoom: 3, focusMm: const Offset(200, 1450));
      expect(art.toScreen(const Offset(200, 1450)), const Offset(200, 300));

      final high = RoomViewport.fit(screen: screen, scene: livingRoom, zoom: 3, focusMm: const Offset(0, 2600));
      expect(high.toScreen(Offset(0, livingRoom.wallHeightMm)).dy, closeTo(0, 1e-6));
    });
  });

  test('several pieces hang side by side, centred, with even gaps', () {
    const frames = [Size(600, 500), Size(400, 400)];
    final centres = defaultRowCentres(whiteCube, frames, showFurniture: false);
    // Row is 600 + 250 + 400 = 1250 mm wide, centred on the wall.
    expect(centres[0], const Offset(-325, standardHangingCentreMm));
    expect(centres[1], const Offset(425, standardHangingCentreMm));
  });

  group('RoomPreviewViewModel', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('dragging moves one piece; reset and scene changes put them back', () {
      final room = RoomPreviewViewModel();
      const frames = {'a': Size(600, 500), 'b': Size(400, 400)};
      final start = room.centres(frames);

      room.moveArtwork('a', const Offset(100, 50), frames);
      expect(room.centres(frames)['a'], start['a']! + const Offset(100, 50));
      expect(room.centres(frames)['b'], start['b'], reason: 'the other piece stays put');
      expect(room.isDragged, isTrue);
      expect(room.lastMoved, 'a');

      room.resetPosition();
      expect(room.centres(frames), start);

      room.moveArtwork('b', const Offset(100, 50), frames);
      room.selectScene(whiteCube);
      expect(room.isDragged, isFalse);
      expect(room.wallColor, whiteCube.defaultWallColor);
      room.dispose();
    });

    test('hiding the furniture lowers the default hanging height to the standard', () {
      final room = RoomPreviewViewModel();
      const tall = {'a': Size(1200, 900)};
      expect(room.centres(tall)['a']!.dy, 1550);
      room.setShowFurniture(false);
      expect(room.centres(tall)['a']!.dy, standardHangingCentreMm);
      room.dispose();
    });
  });

  testWidgets('every scene paints without errors, with and without furniture', (tester) async {
    final design = FrameDesign(
      artworkMm: const Size(600, 450),
      moulding: const Moulding(profile: FrameProfile.beveled, faceWidthMm: 40),
      mat: const MatSpec.uniform(60),
      finish: woodFinishes.first,
    );
    final room = RoomPreviewViewModel();

    for (final scene in roomScenes) {
      room.selectScene(scene);
      // Let the floor texture decode, so planked floors are painted too.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      for (final furniture in [true, false]) {
        room.setShowFurniture(furniture);
        for (final zoom in [1.0, 3.0]) {
          room.setZoom(zoom);
          await tester.pumpWidget(MaterialApp(
            home: SizedBox(
              width: 400,
              height: 600,
              child: RoomPreview(
                room: room,
                pieces: [
                  RoomPiece(id: 'a', design: design),
                  RoomPiece(id: 'b', design: design.withArtworkWidth(300)),
                ],
              ),
            ),
          ));
          expect(tester.takeException(), isNull, reason: '${scene.name}, furniture $furniture, zoom $zoom');
        }
      }
    }
    expect(find.textContaining('from floor'), findsOneWidget);
    room.dispose();
  });
}
