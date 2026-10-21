import 'dart:ui' show Color, Offset, Size;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../data/room_catalog.dart';
import '../models/frame_finish.dart';
import '../models/room_scene.dart';
import '../rendering/room_viewport.dart';
import '../services/texture_service.dart';

/// State of the in-room preview: which room, wall colour, furniture, zoom,
/// and where the framed artwork hangs.
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

  /// Where the user dragged the artwork (its centre, mm); null = default spot.
  Offset? _draggedCentre;

  ui.Image? _floorImage;
  int _floorRequest = 0;
  bool _disposed = false;

  RoomScene get scene => _scene;
  Color get wallColor => _wallColor;
  double get zoom => _zoom;
  bool get hasFurniture => _scene.furniture != null;
  bool get showFurniture => _showFurniture && hasFurniture;
  bool get isDragged => _draggedCentre != null;

  /// Texture of the current scene's wooden floor (null for concrete).
  TextureSet? get floorTextureSet => floorTextures(_scene.floor);
  ui.Image? get floorImage => _floorImage;

  /// Centre of the framed artwork on the wall, in mm, for a frame of
  /// [frameMm] (its overall size).
  Offset hangingCentre(Size frameMm) {
    final dragged = _draggedCentre;
    if (dragged == null) {
      return defaultHangingCentre(_scene, frameMm, showFurniture: showFurniture);
    }
    return clampHangingCentre(_scene, dragged, frameMm, halfRangeMm: RoomViewport.dragRangeMm(_scene));
  }

  void selectScene(RoomScene scene) {
    if (scene == _scene) return;
    _scene = scene;
    _wallColor = scene.defaultWallColor;
    _draggedCentre = null;
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

  /// Moves the artwork by [deltaMm] (a finger drag converted to mm).
  void moveArtwork(Offset deltaMm, Size frameMm) {
    _draggedCentre = clampHangingCentre(
      _scene,
      hangingCentre(frameMm) + deltaMm,
      frameMm,
      halfRangeMm: RoomViewport.dragRangeMm(_scene),
    );
    notifyListeners();
  }

  void resetPosition() {
    _draggedCentre = null;
    notifyListeners();
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
