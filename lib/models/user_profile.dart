import 'venue.dart';

/// The account types from the proposal (section 3.1). The role decides which
/// dashboard a user lands on after signing in.
enum UserRole {
  artist('Artist'),
  galleryOwner('Gallery Owner'),
  frameShopOwner('Frame Shop Owner');

  const UserRole(this.label);

  final String label;

  /// Gallery and frame shop owners must pin their location on the map.
  bool get needsLocation => this != UserRole.artist;
}

/// A signed-in user.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role,
    this.vendorId,
    this.venue,
  });

  /// Firebase Auth user id.
  final String uid;
  final String email;
  final String displayName;

  /// Null until the user completes role selection.
  final UserRole? role;

  /// For frame shop owners: their [Vendor] listing.
  final String? vendorId;

  /// For gallery and frame shop owners: the venue picked during sign-up.
  final Venue? venue;

  UserProfile copyWith({
    String? displayName,
    UserRole? role,
    String? vendorId,
    Venue? venue,
  }) =>
      UserProfile(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        vendorId: vendorId ?? this.vendorId,
        venue: venue ?? this.venue,
      );

  Map<String, Object?> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role?.name,
        'vendorId': vendorId,
        'venue': venue?.toJson(),
      };

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        role: switch (json['role']) {
          final String name => UserRole.values.byName(name),
          _ => null,
        },
        vendorId: json['vendorId'] as String?,
        venue: switch (json['venue']) {
          final Map<Object?, Object?> venue => Venue.fromJson(venue.cast()),
          _ => null,
        },
      );
}
