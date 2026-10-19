//use async, stream
import 'dart:async';

//use firebase things like store and login authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

//import the models of user profile and repositories things
import 'package:pickaframe_application/models/user_profile.dart';
import 'package:pickaframe_application/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserProfile? _currentUser;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Stream<UserProfile?> watchUser() {
    return _auth.authStateChanges().asyncExpand((user) {
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
      throw AuthException(e.message ?? 'Registration failed.');
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
      throw AuthException(e.message ?? 'Sign-in failed.');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserProfile> setRole(UserRole role) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'role': role.name,
      });

      final updated = (_currentUser ??
              UserProfile(
                uid: user.uid,
                email: user.email ?? '',
                displayName: user.displayName ?? '',
              ))
          .copyWith(role: role);

      _currentUser = updated;
      return updated;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

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

    } on FirebaseAuthException catch(e){
      throw AuthException(e.message ?? 'Google Sign-in failed.');
    } catch(e){
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
    _currentUser = null;
  }
}
