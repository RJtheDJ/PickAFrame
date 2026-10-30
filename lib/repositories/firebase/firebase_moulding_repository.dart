import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/catalog_moulding.dart';
import '../moulding_repository.dart';

class FirestoreMouldingRepository implements MouldingRepository {
  FirestoreMouldingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _mouldings => _firestore.collection('mouldings');

  @override
  Stream<List<CatalogMoulding>> watchMouldings() => _mouldings.snapshots().map(_parse);

  @override
  Stream<List<CatalogMoulding>> watchVendorMouldings(String vendorId) =>
      _mouldings.where('vendorId', isEqualTo: vendorId).snapshots().map(_parse);

  @override
  Future<void> saveMoulding(CatalogMoulding moulding) =>
      _mouldings.doc(moulding.id).set(moulding.toJson());

  @override
  Future<void> deleteMoulding(String mouldingId) => _mouldings.doc(mouldingId).delete();

  /// Newest first; documents that can't be read (e.g. an unknown finish) are
  /// skipped rather than breaking the whole catalogue.
  static List<CatalogMoulding> _parse(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final mouldings = <CatalogMoulding>[];
    for (final doc in snapshot.docs) {
      try {
        mouldings.add(CatalogMoulding.fromJson(doc.data()));
      } on FormatException catch (e) {
        debugPrint('Skipping moulding ${doc.id}: $e');
      }
    }
    return mouldings..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
