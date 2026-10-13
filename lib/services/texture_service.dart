import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// The decoded images a finish needs: a colour map (or moulding strip), and
/// for wood and metal the normal and roughness maps used by the GPU shader.
class FinishImages {
  const FinishImages(this.albedo, {this.normal, this.roughness});

  final ui.Image albedo;
  final ui.Image? normal;
  final ui.Image? roughness;
}

/// Decodes bundled frame textures and moulding strips and keeps them in
/// memory, so re-selecting a finish is instant.
class TextureService {
  TextureService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _cache = <String, ui.Image>{};

  Future<ui.Image> load(String asset) async {
    final cached = _cache[asset];
    if (cached != null) return cached;

    final data = await _bundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return _cache[asset] = image;
  }

  /// Loads [assets] as albedo, then optionally normal and roughness maps.
  Future<FinishImages> loadSet(List<String> assets) async {
    final images = await Future.wait(assets.map(load));
    return FinishImages(
      images[0],
      normal: images.length > 1 ? images[1] : null,
      roughness: images.length > 2 ? images[2] : null,
    );
  }

  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}
