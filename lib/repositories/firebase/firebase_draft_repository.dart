import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pickaframe_application/models/draft.dart';
import 'package:pickaframe_application/repositories/draft_repository.dart';

/// Concrete implementation of [DraftRepository] using Cloud Firestore.
///
/// Stores designs in the top-level `drafts` collection in Firestore.
class FirestoreDraftRepository implements DraftRepository {
  FirestoreDraftRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns a reference to the 'drafts' collection in Firestore.
  CollectionReference<Map<String, dynamic>> get _draftsCollection =>
      _firestore.collection('drafts');

  @override
  Stream<List<Draft>> watchDrafts(String ownerUid) {
    // based on the user ownerUid check for all its draft
    return _draftsCollection
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final drafts = snapshot.docs.map((doc) {
        return Draft.fromJson(doc.data());
      }).toList();

      // in user interface update (newest first)
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    });
  }

  @override
  Future<void> saveDraft(Draft draft) async {
    // use draft id to search, if no then create new
    await _draftsCollection.doc(draft.id).set(draft.toJson());
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    // based on draft id to delete
    await _draftsCollection.doc(draftId).delete();
  }
}
