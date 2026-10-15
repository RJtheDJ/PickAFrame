/// A framing workshop listed in the directory (proposal 3.1.3, wireframe d).
class Vendor {
  const Vendor({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.specialties = const [],
    this.acceptsBulkOrders = false,
  });

  final String id;

  /// The frame shop owner's user id.
  final String ownerUid;
  final String name;

  /// As picked with Google Maps during onboarding.
  final String address;
  final double latitude;
  final double longitude;

  final String? phone;

  /// e.g. "Gilding", "Shadow boxes", "Museum glazing".
  final List<String> specialties;
  final bool acceptsBulkOrders;

  Map<String, Object?> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'specialties': specialties,
        'acceptsBulkOrders': acceptsBulkOrders,
      };

  factory Vendor.fromJson(Map<String, Object?> json) => Vendor(
        id: json['id'] as String,
        ownerUid: json['ownerUid'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phone: json['phone'] as String?,
        specialties: [...(json['specialties'] as List? ?? const []).cast<String>()],
        acceptsBulkOrders: json['acceptsBulkOrders'] as bool? ?? false,
      );
}
