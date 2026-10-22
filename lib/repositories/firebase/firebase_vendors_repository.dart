import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vendor.dart';
import '../vendor_repository.dart';

class FirestoreVendorRepository implements VendorRepository {
  FirestoreVendorRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _vendorsCollection =>
      _firestore.collection('vendors');

  @override
  Stream<List<Vendor>> watchVendors() {
    return _vendorsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Vendor.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<Vendor?> getVendor(String vendorId) async {
    final doc = await _vendorsCollection.doc(vendorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Vendor.fromJson(doc.data()!);
  }

  @override
  Future<void> saveVendor(Vendor vendor) async {
    await _vendorsCollection.doc(vendor.id).set(vendor.toJson());
  }
}
