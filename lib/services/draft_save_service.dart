import 'dart:typed_data';

import '../models/draft.dart';
import '../repositories/draft_repository.dart';
import 'artwork_storage.dart';

/// Saves a draft: the artwork image first, then the draft pointing at it, so a
/// failed upload never leaves a draft without its image. The image path is
/// fixed per draft id, so retrying overwrites rather than duplicates.
class DraftSaveService {
  DraftSaveService({required this._drafts, required this._storage});

  final DraftRepository _drafts;
  final ArtworkStorage _storage;

  Future<Draft> saveDraft({required Draft draft, required Uint8List artworkPng}) async {
    final url = await _storage.uploadArtwork(draftId: draft.id, png: artworkPng);
    final saved = draft.copyWith(artworkUrl: url);
    await _drafts.saveDraft(saved);
    return saved;
  }
}
