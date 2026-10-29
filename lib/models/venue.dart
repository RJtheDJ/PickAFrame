/// The gallery or workshop a Gallery Owner or Frame Shop Owner registers
/// during sign-up (wireframe 02C). The location is picked on Google Maps.
class Venue {
  const Venue({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.unit,
    this.openingHours,
  });

  /// Registered business name.
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// e.g. "Level 2, Suite B".
  final String? unit;

  /// Free text, e.g. "Tue-Sun 11:00-19:00".
  final String? openingHours;

  Map<String, Object?> toJson() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'unit': unit,
        'openingHours': openingHours,
      };

  factory Venue.fromJson(Map<String, Object?> json) => Venue(
        name: json['name'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        unit: json['unit'] as String?,
        openingHours: json['openingHours'] as String?,
      );
}
