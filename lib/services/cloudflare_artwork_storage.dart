import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'artwork_storage.dart';

/// The artwork Worker's address. Override for a local Worker, e.g.
/// `--dart-define=CLOUDFLARE_WORKER_BASE_URL=http://10.0.2.2:8787` from the
/// Android emulator (debug builds allow plain HTTP for this).
const workerBaseUrl = String.fromEnvironment(
  'CLOUDFLARE_WORKER_BASE_URL',
  defaultValue: 'https://artwork-worker.artwork-worker.workers.dev',
);

/// A storage problem worded for the user.
class ArtworkStorageException implements Exception {
  const ArtworkStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Saves artworks through the Cloudflare Worker in front of R2
/// (cloudflare/artwork-worker). Every request carries the user's Firebase ID
/// token; the Worker stores each user's images under their own uid.
class CloudflareArtworkStorage implements ArtworkStorage {
  CloudflareArtworkStorage({
    required this._idToken,
    String baseUrl = workerBaseUrl,
    http.Client? client,
  })  : _base = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  final Future<String?> Function() _idToken;
  final Uri _base;
  final http.Client _client;

  @override
  Future<String> uploadArtwork({required String draftId, required Uint8List png}) async {
    final response = await _send(() async => _client.put(
          _base.resolve('/v1/drafts/${Uri.encodeComponent(draftId)}/artwork'),
          headers: {...await _auth(), 'Content-Type': 'image/png'},
          body: png,
        ));
    final url = (jsonDecode(response.body) as Map)['url'];
    if (url is! String) throw const ArtworkStorageException('Unexpected reply from the image server.');
    return url;
  }

  @override
  Future<Uint8List> loadArtwork(String workerUrl) async {
    final response = await _send(() async => _client.get(_base.resolve(workerUrl), headers: await _auth()));
    return response.bodyBytes;
  }

  Future<Map<String, String>> _auth() async {
    final token = await _idToken();
    if (token == null) throw const ArtworkStorageException('Sign in to save and load artworks.');
    return {'Authorization': 'Bearer $token'};
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 60));
    } on ArtworkStorageException {
      rethrow;
    } catch (_) {
      throw const ArtworkStorageException("Couldn't reach the image server. Check your connection.");
    }
    if (response.statusCode == 200) return response;
    throw ArtworkStorageException(switch (response.statusCode) {
      401 => 'Your sign-in has expired. Sign in again.',
      404 => 'That image is no longer available.',
      413 => 'The image is too large to save.',
      415 => 'Only PNG images can be saved.',
      _ => 'The image server had a problem (${response.statusCode}). Try again.',
    });
  }
}
