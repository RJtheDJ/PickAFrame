import 'dart:math' as math;
import 'dart:ui';

// Rooms for the in-room preview, all in real millimetres so a framed piece
// can be shown at true size next to furniture. The rooms themselves are in
// lib/data/room_catalog.dart.

enum FloorKind { oak, maple, walnut, concrete }

enum RoomLighting {
  /// Even household light, a little brighter near the ceiling.
  soft,

  /// A ceiling spotlight pooling on the artwork; the rest of the wall falls off.
  spotlight,

  /// A bright, even gallery skylight.
  skylight,
}

/// A piece of furniture for scale, centred under the artwork's default spot.
enum Furniture {
  sofa('3-seater sofa', widthMm: 2100, heightMm: 850),
  sideboard('Sideboard', widthMm: 1600, heightMm: 800),
  bench('Gallery bench', widthMm: 1800, heightMm: 450);

  const Furniture(this.label, {required this.widthMm, required this.heightMm});

  final String label;
  final double widthMm;
  final double heightMm;
}

class RoomScene {
  const RoomScene({
    required this.id,
    required this.name,
    required this.wallHeightMm,
    required this.defaultWallColor,
    required this.floor,
    required this.lighting,
    this.skirtingMm = 0,
    this.crownMoulding = false,
    this.partitionWidthMm,
    this.furniture,
  });

  final String id;
  final String name;

  /// Floor to ceiling.
  final double wallHeightMm;
  final Color defaultWallColor;
  final FloorKind floor;
  final RoomLighting lighting;

  /// Height of the skirting board, 0 for none.
  final double skirtingMm;
  final bool crownMoulding;

  /// For a freestanding gallery wall: its width, with the room's back walls
  /// visible either side. Null for a plain wall running edge to edge.
  final double? partitionWidthMm;

  final Furniture? furniture;

  bool get isGallery => lighting != RoomLighting.soft;
}

/// Standard gallery hanging height for the artwork's centre (about 57 in).
const standardHangingCentreMm = 1450.0;

/// Gap left between the top of furniture and the bottom of the frame.
const furnitureClearanceMm = 250.0;

/// Gap between pieces hung side by side.
const pieceGapMm = 250.0;

/// Default spots for [frames] hung side by side in one row, centred on the
/// wall, each at its own default height.
List<Offset> defaultRowCentres(RoomScene scene, List<Size> frames, {required bool showFurniture}) {
  final rowWidth = frames.fold(0.0, (sum, f) => sum + f.width) + pieceGapMm * (frames.length - 1);
  var left = -rowWidth / 2;
  final centres = <Offset>[];
  for (final frame in frames) {
    final height = defaultHangingCentre(scene, frame, showFurniture: showFurniture).dy;
    centres.add(Offset(left + frame.width / 2, height));
    left += frame.width + pieceGapMm;
  }
  return centres;
}

/// Where a frame of [frameMm] hangs by default: centred at the standard
/// height, or higher if it would otherwise come too close to the furniture.
Offset defaultHangingCentre(RoomScene scene, Size frameMm, {required bool showFurniture}) {
  var centreY = standardHangingCentreMm;
  final furniture = scene.furniture;
  if (showFurniture && furniture != null) {
    centreY = math.max(centreY, furniture.heightMm + furnitureClearanceMm + frameMm.height / 2);
  }
  return Offset(0, _clampHeight(scene, centreY, frameMm));
}

/// Keeps a frame of [frameMm] centred at [centreMm] on the wall: above the
/// skirting and below the ceiling, within [halfRangeMm] of the middle sideways.
Offset clampHangingCentre(RoomScene scene, Offset centreMm, Size frameMm, {required double halfRangeMm}) {
  final halfWidth = frameMm.width / 2;
  final xLimit = math.max(0.0, halfRangeMm - halfWidth);
  return Offset(
    centreMm.dx.clamp(-xLimit, xLimit),
    _clampHeight(scene, centreMm.dy, frameMm),
  );
}

double _clampHeight(RoomScene scene, double centreY, Size frameMm) {
  final low = scene.skirtingMm + 50 + frameMm.height / 2;
  final high = scene.wallHeightMm - 100 - frameMm.height / 2;
  // A frame taller than the wall just sits in the middle.
  if (high < low) return scene.wallHeightMm / 2;
  return centreY.clamp(low, high);
}
