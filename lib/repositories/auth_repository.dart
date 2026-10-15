import '../models/user_profile.dart';

/// Sign-in and the current user's profile. Implemented with Firebase Auth +
/// a `users/{uid}` Firestore document; see docs/ARCHITECTURE.md.
abstract interface class AuthRepository {
  /// Emits the signed-in user (or null) now and whenever it changes.
  Stream<UserProfile?> watchUser();

  UserProfile? get currentUser;

  Future<UserProfile> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserProfile> signInWithEmail({required String email, required String password});

  Future<UserProfile> signInWithGoogle();

  /// Completes onboarding (role selection screen).
  Future<UserProfile> setRole(UserRole role);

  Future<void> signOut();
}

/// Thrown for wrong credentials, taken emails and similar sign-in problems.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
