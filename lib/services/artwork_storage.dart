import 'dart:typed_data';

/// Where saved drafts' cropped artwork images live (the Cloudflare Worker in
/// front of R2). Interface as specified in docs/plans/r2-exhibition.md
/// (Task 2), which also adds the Worker and in-memory implementations.
abstract interface class ArtworkStorage {
  /// Uploads [png] as the artwork of draft [draftId]; returns the Worker path
  /// to store in `Draft.artworkUrl`.
  Future<String> uploadArtwork({required String draftId, required Uint8List png});

  /// Downloads the PNG at a Worker path from `Draft.artworkUrl`.
  Future<Uint8List> loadArtwork(String workerUrl);
}
