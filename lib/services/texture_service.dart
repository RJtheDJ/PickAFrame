import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

/// Downloads frame textures and keeps them in memory, so re-selecting a
/// finish is instant.
class TextureService {
  TextureService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _cache = <String, ui.Image>{};

  Future<ui.Image> load(String url) async {
    final cached = _cache[url];
    if (cached != null) return cached;

    final response = await _client.get(
      Uri.parse(url),
      headers: {'User-Agent': 'PickAFrameApp/1.0'}, // Required by Poly Haven
    );
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} loading $url');
    }

    final codec = await ui.instantiateImageCodec(response.bodyBytes);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return _cache[url] = image;
  }

  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _client.close();
  }
}
