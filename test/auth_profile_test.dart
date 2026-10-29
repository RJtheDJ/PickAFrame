import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/models/user_profile.dart';
import 'package:pickaframe_application/models/venue.dart';
import 'package:pickaframe_application/repositories/in_memory/in_memory_repositories.dart';

const _venue = Venue(
  name: 'Sareng Art Gallery',
  address: 'Jalan Telawi 3, Bangsar Baru',
  latitude: 3.1297,
  longitude: 101.6710,
  unit: 'Level 2, Suite B',
);

void main() {
  test('a profile with a venue survives a JSON round trip', () {
    const profile = UserProfile(
      uid: 'u1',
      email: 'a@b.my',
      displayName: 'A',
      role: UserRole.galleryOwner,
      venue: _venue,
    );

    final restored = UserProfile.fromJson(profile.toJson());

    expect(restored.role, UserRole.galleryOwner);
    expect(restored.venue?.name, 'Sareng Art Gallery');
    expect(restored.venue?.latitude, 3.1297);
    expect(restored.venue?.unit, 'Level 2, Suite B');
    expect(restored.venue?.openingHours, isNull);
  });

  test('a profile without a venue reads back as null', () {
    const profile = UserProfile(uid: 'u1', email: 'a@b.my', displayName: 'A');

    expect(UserProfile.fromJson(profile.toJson()).venue, isNull);
  });

  test('a frame shop owner gets their uid as vendor id', () async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerWithEmail(
      email: 'shop@b.my',
      password: 'secret1',
      displayName: 'Shop',
    );

    final updated = await auth.setRole(UserRole.frameShopOwner, venue: _venue);

    expect(updated.vendorId, user.uid);
    expect(updated.venue?.address, _venue.address);
  });

  test('an artist has no vendor id or venue', () async {
    final auth = InMemoryAuthRepository();
    await auth.registerWithEmail(
      email: 'art@b.my',
      password: 'secret1',
      displayName: 'Art',
    );

    final updated = await auth.setRole(UserRole.artist);

    expect(updated.vendorId, isNull);
    expect(updated.venue, isNull);
  });
}
