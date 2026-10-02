import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/finish_catalog.dart';
import '../models/artwork.dart';
import '../models/frame_design.dart';
import '../models/frame_finish.dart';
import '../models/frame_profile.dart';
import '../models/mat_spec.dart';
import '../models/moulding.dart';
import '../services/artwork_service.dart';
import '../services/texture_service.dart';

enum FrameMode { color, texture }

class EditorViewModel extends ChangeNotifier {
  EditorViewModel({TextureService? textureService})
      : _textures = textureService ?? TextureService() {
    selectTexture(polyHavenTextureUrl(woodTextureIds.first));
  }

  final TextureService _textures;

  FrameDesign _design = const FrameDesign(
    artworkMm: Size(400, 300),
    moulding: Moulding(profile: FrameProfile.beveled, faceWidthMm: 40),
    mat: MatSpec.uniform(60),
    finish: ColorFinish(Color(0xFF4E342E)),
  );
  Artwork? _artwork;

  // Remembered so toggling between colour and texture restores the last pick.
  Color _paintColor = paintColors.first;
  String? _textureUrl;

  ui.Image? _texture;
  bool _isLoadingTexture = false;
  int _textureRequest = 0;
  bool _disposed = false;

  FrameDesign get design => _design;
  Artwork? get artwork => _artwork;
  bool get isLoadingTexture => _isLoadingTexture;
  String? get textureUrl => _textureUrl;

  FrameMode get mode =>
      _design.finish is TextureFinish ? FrameMode.texture : FrameMode.color;

  /// Solid colour for the frame; also shown while a texture is loading.
  Color get frameColor => _paintColor;

  /// Texture to paint on the frame, or null to use [frameColor].
  ui.Image? get frameTexture => mode == FrameMode.texture ? _texture : null;

  void setMode(FrameMode mode) {
    if (mode == this.mode) return;
    if (mode == FrameMode.color) {
      _update(_design.copyWith(finish: ColorFinish(_paintColor)));
    } else {
      selectTexture(_textureUrl ?? polyHavenTextureUrl(woodTextureIds.first));
    }
  }

  void setProfile(FrameProfile profile) {
    _update(_design.copyWith(moulding: _design.moulding.copyWith(profile: profile)));
  }

  void setColor(Color color) {
    _paintColor = color;
    _update(_design.copyWith(finish: ColorFinish(color)));
  }

  void setFrameWidthMm(double mm) {
    _update(_design.copyWith(moulding: _design.moulding.copyWith(faceWidthMm: mm)));
  }

  void setMatWidthMm(double mm) {
    _update(_design.copyWith(mat: MatSpec.uniform(mm, color: _design.mat.color)));
  }

  void setArtworkWidthMm(double mm) => _update(_design.withArtworkWidth(mm));

  Future<void> selectTexture(String url) async {
    final request = ++_textureRequest;
    _textureUrl = url;
    _isLoadingTexture = true;
    // Keep showing the previous texture until the new one arrives.
    _update(_design.copyWith(finish: TextureFinish(url)));

    try {
      final image = await _textures.load(url);
      if (request == _textureRequest) _texture = image;
    } catch (e) {
      debugPrint('Error loading texture: $e');
    }

    // A newer selection was made while this one loaded; let that one finish.
    if (_disposed || request != _textureRequest) return;
    _isLoadingTexture = false;
    notifyListeners();
  }

  Future<void> pickArtwork() async {
    try {
      final artwork = await pickArtworkFromGallery();
      if (artwork == null || _disposed) return;
      _artwork = artwork;
      _update(_design.withArtworkAspect(artwork.aspectRatio));
    } catch (e) {
      debugPrint('Error picking artwork: $e');
    }
  }

  void _update(FrameDesign design) {
    _design = design;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _textures.dispose();
    super.dispose();
  }
}
