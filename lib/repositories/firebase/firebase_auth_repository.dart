//use async, stream
import 'dart:async';

//use firebase things like store and login authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

//import the models of user profile and repositories things
import 'package:pickaframe_application/models/user_profile.dart';
import 'package:pickaframe_application/models/venue.dart';
import 'package:pickaframe_application/repositories/auth_repository.dart';
import 'package:pickaframe_application/repositories/switch_latest.dart';

/// Turns Firebase's error codes into messages for the sign-in screens.
String _messageFor(FirebaseAuthException e) => switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'Wrong email or password.',
      'invalid-email' => 'That email address is not valid.',
      'email-already-in-use' =>
        'An account already exists for that email. Log in instead.',
      'weak-password' => 'Password must be at least 6 characters.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
      'network-request-failed' => 'No internet connection.',
      _ => e.message ?? 'Sign-in failed.',
    };

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserProfile? _currentUser;

  /// google_sign_in must be initialised exactly once per app run.
  static Future<void>? _googleInit;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Stream<UserProfile?> watchUser() {
    return switchLatest(_auth.authStateChanges(), (User? user) {
      if (user == null) {
        _currentUser = null;
        return Stream.value(null);
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          final fallback = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
          );
          _currentUser = fallback;
          return fallback;
        }

        final profile = UserProfile.fromJson(snapshot.data()!);
        _currentUser = profile;
        return profile;
      });
    });
  }

  @override
  Future<UserProfile> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(displayName);

      final profile = UserProfile(
        uid: user.uid,
        email: email.trim().toLowerCase(),
        displayName: displayName,
      );

      await _firestore.collection('users').doc(user.uid).set(profile.toJson());

      _currentUser = profile;
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      final doc = await _firestore.collection('users').doc(user.uid).get();

      final UserProfile profile;
      if (doc.exists && doc.data() != null) {
        profile = UserProfile.fromJson(doc.data()!);
      } else {
        profile = UserProfile(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? '',
        );
        await _firestore.collection('users').doc(user.uid).set(profile.toJson());
      }

      _currentUser = profile;
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserProfile> setRole(UserRole role, {Venue? venue}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.');
    }

    final vendorId = role == UserRole.frameShopOwner ? user.uid : null;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'role': role.name,
        'venue': venue?.toJson(),
        'vendorId': vendorId,
      }, SetOptions(merge: true));

      final updated = (_currentUser ??
              UserProfile(
                uid: user.uid,
                email: user.email ?? '',
                displayName: user.displayName ?? '',
              ))
          .copyWith(role: role, venue: venue, vendorId: vendorId);

      _currentUser = updated;
      return updated;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      final user = (kIsWeb
              ? await _auth.signInWithPopup(GoogleAuthProvider())
              : await _signInWithGoogleOnDevice())
          .user!;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromJson(doc.data()!);
        _currentUser = profile;
        return profile;
      } else {
        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
        );
        await _firestore.collection('users').doc(user.uid).set(profile.toJson());
        _currentUser = profile;
        return profile;
      }

    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Google sign-in was cancelled.');
      }
      throw AuthException('Google sign-in failed: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch(e){
      throw AuthException(e.toString());
    }
  }

  /// Android/iOS: pick an account with google_sign_in, then hand its token to
  /// Firebase. (On web, Firebase's own popup is used instead, because
  /// google_sign_in's web version needs a separate client id and button.)
  Future<UserCredential> _signInWithGoogleOnDevice() async {
    final googleSignIn = GoogleSignIn.instance;
    await (_googleInit ??= googleSignIn.initialize());
    final googleUser = await googleSignIn.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    // Only sign out of google_sign_in if it was used in this run.
    if (_googleInit != null) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
    _currentUser = null;
  }
}
