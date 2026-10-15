import '../models/vendor.dart';

/// The Kuala Lumpur workshop directory. Implemented with a Firestore
/// `vendors` collection; locations come from the Google Maps place picker.
abstract interface class VendorRepository {
  /// All listed workshops, now and whenever they change.
  Stream<List<Vendor>> watchVendors();

  Future<Vendor?> getVendor(String vendorId);

  /// Creates or updates a workshop listing (frame shop onboarding).
  Future<void> saveVendor(Vendor vendor);
}
