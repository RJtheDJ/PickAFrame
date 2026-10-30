import '../models/catalog_moulding.dart';

/// The Unified Frame Catalogue. Implemented with a Firestore `mouldings`
/// collection: anyone can browse; a frame shop manages only its own
/// (enforced by firebase/firestore.rules).
abstract interface class MouldingRepository {
  /// Every shop's mouldings, newest first, now and whenever they change.
  Stream<List<CatalogMoulding>> watchMouldings();

  /// One shop's mouldings, newest first.
  Stream<List<CatalogMoulding>> watchVendorMouldings(String vendorId);

  /// Creates or replaces the moulding with [CatalogMoulding.id].
  Future<void> saveMoulding(CatalogMoulding moulding);

  Future<void> deleteMoulding(String mouldingId);
}
