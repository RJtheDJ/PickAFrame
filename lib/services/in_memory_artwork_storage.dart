import 'dart:typed_data';

import 'artwork_storage.dart';

/// Keeps artworks in memory, for development without the Worker and for tests.
class InMemoryArtworkStorage implements ArtworkStorage {
  final _images = <String, Uint8List>{};

  @override
  Future<String> uploadArtwork({required String draftId, required Uint8List png}) async {
    final url = '/v1/drafts/$draftId/artwork';
    _images[url] = png;
    return url;
  }

  @override
  Future<Uint8List> loadArtwork(String workerUrl) async =>
      _images[workerUrl] ?? (throw StateError('No artwork at $workerUrl'));
}
