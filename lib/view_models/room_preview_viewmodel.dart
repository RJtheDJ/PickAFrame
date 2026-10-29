import 'dart:math' as math;
import 'dart:ui' show Color, Offset, Size;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../data/room_catalog.dart';
import '../models/frame_finish.dart';
import '../models/room_scene.dart';
import '../rendering/lighting.dart';
import '../rendering/room_viewport.dart';
import '../services/texture_service.dart';

/// State of the in-room preview: which room, wall colour, furniture, zoom,
/// light, and where each framed piece hangs.
class RoomPreviewViewModel extends ChangeNotifier {
  RoomPreviewViewModel({TextureService? textureService})
      : _textures = textureService ?? TextureService() {
    _loadFloor();
  }

  final TextureService _textures;

  RoomScene _scene = roomScenes.first;
  Color _wallColor = roomScenes.first.defaultWallColor;
  bool _showFurniture = true;
  double _zoom = RoomViewport.minZoom;
  Light _light = const Light();

  /// Where the user dragged each piece (its centre, mm), by piece id. Pieces
  /// not in here hang in their default spot.
  final _dragged = <String, Offset>{};
  String? _lastMoved;

  ui.Image? _floorImage;
  int _floorRequest = 0;
  bool _disposed = false;

  RoomScene get scene => _scene;
  Color get wallColor => _wallColor;
  double get zoom => _zoom;
  bool get hasFurniture => _scene.furniture != null;
  bool get showFurniture => _showFurniture && hasFurniture;
  Light get light => _light;
  bool get isDragged => _dragged.isNotEmpty;

  /// The piece the user moved last, if any.
  String? get lastMoved => _lastMoved;

  /// Texture of the current scene's wooden floor (null for concrete).
  TextureSet? get floorTextureSet => floorTextures(_scene.floor);
  ui.Image? get floorImage => _floorImage;

  /// Centre of each piece on the wall, in mm, for pieces of the given
  /// overall frame sizes (in hanging order, keyed by piece id).
  Map<String, Offset> centres(Map<String, Size> framesMm) {
    final defaults = defaultRowCentres(_scene, framesMm.values.toList(), showFurniture: showFurniture);
    final range = _dragRange(framesMm);
    final result = <String, Offset>{};
    var i = 0;
    for (final MapEntry(key: id, value: frame) in framesMm.entries) {
      final dragged = _dragged[id];
      result[id] = dragged == null
          ? defaults[i]
          : clampHangingCentre(_scene, dragged, frame, halfRangeMm: range);
      i++;
    }
    return result;
  }

  void selectScene(RoomScene scene) {
    if (scene == _scene) return;
    _scene = scene;
    _wallColor = scene.defaultWallColor;
    _dragged.clear();
    _lastMoved = null;
    notifyListeners();
    _loadFloor();
  }

  void setWallColor(Color color) {
    _wallColor = color;
    notifyListeners();
  }

  void setShowFurniture(bool show) {
    _showFurniture = show;
    notifyListeners();
  }

  void setZoom(double zoom) {
    _zoom = zoom.clamp(RoomViewport.minZoom, RoomViewport.maxZoom);
    notifyListeners();
  }

  void setLightAzimuth(double degrees) {
    _light = _light.copyWith(azimuthDeg: degrees);
    notifyListeners();
  }

  /// Moves piece [id] by [deltaMm] (a finger drag converted to mm).
  void moveArtwork(String id, Offset deltaMm, Map<String, Size> framesMm) {
    final current = centres(framesMm)[id]!;
    _dragged[id] = clampHangingCentre(
      _scene,
      current + deltaMm,
      framesMm[id]!,
      halfRangeMm: _dragRange(framesMm),
    );
    _lastMoved = id;
    notifyListeners();
  }

  void resetPosition() {
    _dragged.clear();
    _lastMoved = null;
    notifyListeners();
  }

  /// How far either side of the middle pieces can go: the room's usual range,
  /// widened so a long row of pieces always fits.
  double _dragRange(Map<String, Size> framesMm) {
    final rowWidth =
        framesMm.values.fold(0.0, (sum, f) => sum + f.width) + pieceGapMm * (framesMm.length - 1);
    return math.max(RoomViewport.dragRangeMm(_scene), rowWidth / 2 + pieceGapMm);
  }

  Future<void> _loadFloor() async {
    final request = ++_floorRequest;
    final textures = floorTextures(_scene.floor);
    if (textures == null) {
      _floorImage = null;
      return;
    }
    try {
      final image = await _textures.load(textures.albedo);
      if (_disposed || request != _floorRequest) return;
      _floorImage = image;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading floor texture: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _textures.dispose();
    super.dispose();
  }
}
