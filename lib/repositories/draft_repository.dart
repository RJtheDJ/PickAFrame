import '../models/draft.dart';

/// Saved designs (Drafts & Portfolio). Implemented with a Firestore `drafts`
/// collection; artwork images and previews go to Firebase Storage.
abstract interface class DraftRepository {
  /// The user's drafts, newest first, now and whenever they change.
  Stream<List<Draft>> watchDrafts(String ownerUid);

  /// Creates or replaces the draft with [Draft.id].
  Future<void> saveDraft(Draft draft);

  Future<void> deleteDraft(String draftId);
}
