import 'package:flutter/material.dart';

import '../data/finish_catalog.dart';
import '../models/artwork.dart';
import '../models/catalog_moulding.dart';
import '../models/frame_design.dart';
import '../models/frame_finish.dart';
import '../models/frame_profile.dart';
import '../models/mat_presets.dart';
import '../models/mat_spec.dart';
import '../models/moulding.dart';
import '../rendering/lighting.dart';
import '../rendering/shaded_frame_painter.dart';
import '../services/texture_service.dart';

class EditorViewModel extends ChangeNotifier {
  EditorViewModel({TextureService? textureService})
      : _textures = textureService ?? TextureService() {
    selectWood(_wood);
    FrameShaderResources.load().then((resources) {
      if (_disposed) return;
      _shaderResources = resources;
      notifyListeners();
    });
  }

  final TextureService _textures;

  FrameDesign _design = const FrameDesign(
    artworkMm: Size(400, 300),
    moulding: Moulding(profile: FrameProfile.beveled, faceWidthMm: 40),
    mat: MatSpec.uniform(60),
    finish: ColorFinish(Color(0xFF4E342E)),
  );
  Artwork? _artwork;
  Light _light = const Light();
  bool _matLinked = true;

  // The last pick of each kind, restored when switching back to that kind.
  Color _paintColor = paintColors.first;
  WoodFinish _wood = woodFinishes.first;
  MetalFinish _metal = metalFinishes.first;
  PhotoMouldingFinish _photoMoulding = photoMouldings.first;

  FrameShaderResources? _shaderResources;
  FinishImages? _images;
  String? _imagesKey;
  bool _isLoadingImage = false;
  int _imageRequest = 0;
  bool _disposed = false;

  FrameDesign get design => _design;
  Artwork? get artwork => _artwork;
  Light get light => _light;
  bool get isLoadingTexture => _isLoadingImage;

  /// The GPU frame shader, or null while loading or where unsupported (the
  /// frame is then drawn by the CPU fallback renderer).
  FrameShaderResources? get shaderResources => _shaderResources;

  /// The decoded maps or moulding strip for the current finish, or null
  /// while they load (the frame is then drawn in a flat stand-in colour).
  FinishImages? get finishImages {
    final assets = assetsOf(_design.finish);
    return assets != null && assets.first == _imagesKey ? _images : null;
  }

  // Moulding & finish

  void setProfile(FrameProfile profile) {
    _update(_design.copyWith(moulding: _design.moulding.copyWith(profile: profile)));
  }

  void setFrameWidthMm(double mm) {
    _update(_design.copyWith(moulding: _design.moulding.copyWith(faceWidthMm: mm)));
  }

  void setFinishKind(FinishKind kind) {
    if (kind == _design.finish.kind) return;
    switch (kind) {
      case FinishKind.paint:
        setColor(_paintColor);
      case FinishKind.wood:
        selectWood(_wood);
      case FinishKind.metal:
        selectMetal(_metal);
      case FinishKind.ornate:
        selectPhotoMoulding(_photoMoulding);
    }
  }

  void setColor(Color color) {
    _paintColor = color;
    _update(_design.copyWith(finish: ColorFinish(color), moulding: _design.moulding.copyWith()));
  }

  void selectWood(WoodFinish wood) {
    _wood = wood;
    _update(_design.copyWith(finish: wood, moulding: _design.moulding.copyWith()));
    _loadImages(assetsOf(wood)!);
  }

  void selectMetal(MetalFinish metal) {
    _metal = metal;
    _update(_design.copyWith(finish: metal, moulding: _design.moulding.copyWith()));
    _loadImages(assetsOf(metal)!);
  }

  /// Also sets the face width to the real moulding's.
  void selectPhotoMoulding(PhotoMouldingFinish moulding) {
    _photoMoulding = moulding;
    _update(_design.copyWith(
      finish: moulding,
      moulding: _design.moulding.copyWith(faceWidthMm: moulding.faceWidthMm),
    ));
    _loadImages(assetsOf(moulding)!);
  }

  /// The catalogue moulding the frame was started from, while the frame still
  /// matches it (any change to profile, width or finish makes it custom).
  CatalogMoulding? get catalogMoulding =>
      _catalogMoulding?.id == _design.moulding.catalogId ? _catalogMoulding : null;
  CatalogMoulding? _catalogMoulding;

  /// Frames the artwork with a shop's catalogue moulding.
  void applyCatalogMoulding(CatalogMoulding moulding) {
    _catalogMoulding = moulding;
    switch (moulding.finish) {
      case ColorFinish(:final color):
        _paintColor = color;
      case final WoodFinish wood:
        _wood = wood;
      case final MetalFinish metal:
        _metal = metal;
      case final PhotoMouldingFinish photo:
        _photoMoulding = photo;
    }
    _update(moulding.applyTo(_design));
    if (assetsOf(moulding.finish) case final assets?) _loadImages(assets);
  }

  void setLightAzimuth(double degrees) {
    _light = _light.copyWith(azimuthDeg: degrees);
    notifyListeners();
  }

  /// Image assets a finish needs: colour, normal and roughness maps for
  /// textured materials, or the strip for a photographed moulding.
  static List<String>? assetsOf(FrameFinish finish) => switch (finish) {
        WoodFinish(:final textures) || MetalFinish(:final textures) => [
            textures.albedo,
            textures.normal,
            textures.roughness,
          ],
        PhotoMouldingFinish(:final asset, :final normalAsset) => [asset, normalAsset],
        ColorFinish() => null,
      };

  Future<void> _loadImages(List<String> assets) async {
    // Any load still in flight is now stale.
    final request = ++_imageRequest;
    if (assets.first == _imagesKey && _images != null) {
      _isLoadingImage = false;
      return;
    }
    _isLoadingImage = true;
    notifyListeners();

    try {
      final images = await _textures.loadSet(assets);
      if (request == _imageRequest) {
        _images = images;
        _imagesKey = assets.first;
      }
    } catch (e) {
      debugPrint('Error loading ${assets.first}: $e');
    }

    if (_disposed || request != _imageRequest) return;
    _isLoadingImage = false;
    notifyListeners();
  }

  void setArtworkWidthMm(double mm) => _update(_design.withArtworkWidth(mm));

  /// Sets the artwork's measured size exactly. A photo can only suggest the
  /// proportions; the measured size wins and the image is fitted to it.
  void setArtworkSizeMm(Size size) => _update(_design.copyWith(artworkMm: size));

  // Matting Section

  /// When true, editing one mat border edits all four.
  bool get matLinked => _matLinked;

  void setMatLinked(bool linked) {
    _matLinked = linked;
    if (linked) {
      // Snap to the top border so the sides start equal.
      _updateMat(_design.mat.withAllSides(_design.mat.topMm));
    } else {
      notifyListeners();
    }
  }

  void setMatSideMm(MatSide side, double mm) {
    _updateMat(_matLinked ? _design.mat.withAllSides(mm) : _design.mat.withSide(side, mm));
  }

  void applyGoldenRatioMat() => _applyUniformMat(goldenMatWidthMm(_design.artworkMm));

  void applyThreeToOneMat() =>
      _applyUniformMat(threeToOneMatWidthMm(_design.moulding.faceWidthMm));

  /// Keeps the top and sides, and makes the bottom heavier.
  void applyBottomWeightedMat() {
    final mat = _design.mat;
    _matLinked = false;
    _updateMat(mat.copyWith(bottomMm: _roundMm(mat.topMm * bottomWeightFactor)));
  }

  void setMountStyle(MountStyle style) => _updateMat(_design.mat.copyWith(style: style));
  void setMatColor(Color color) => _updateMat(_design.mat.copyWith(color: color));
  void setMatCoreColor(Color color) => _updateMat(_design.mat.copyWith(coreColor: color));
  void setInnerMatColor(Color color) => _updateMat(_design.mat.copyWith(innerColor: color));
  void setRevealMm(double mm) => _updateMat(_design.mat.copyWith(revealMm: mm));

  void _applyUniformMat(double mm) {
    _matLinked = true;
    _updateMat(_design.mat.withAllSides(_roundMm(mm)));
  }

  void _updateMat(MatSpec mat) => _update(_design.copyWith(mat: mat));

  static double _roundMm(double mm) => mm.roundToDouble();

  /// Shows a newly cropped artwork, matching its proportions.
  void setArtwork(Artwork artwork) {
    _artwork = artwork;
    _update(_design.withArtworkAspect(artwork.aspectRatio));
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
