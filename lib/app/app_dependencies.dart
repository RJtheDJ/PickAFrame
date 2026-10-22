import 'package:flutter/widgets.dart';
import 'package:pickaframe_application/repositories/firebase/firebase_order_repository.dart';
import 'package:pickaframe_application/repositories/firebase/firebase_vendors_repository.dart';

import '../repositories/auth_repository.dart';
import '../repositories/draft_repository.dart';
import '../repositories/in_memory/in_memory_repositories.dart';
import '../repositories/order_repository.dart';
import '../repositories/vendor_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_draft_repository.dart';

/// The app's data sources, chosen once at start-up. Screens and view models
/// get them from [AppScope] instead of creating them, so swapping the
/// in-memory versions for Firebase ones is a one-line change in main.dart.
class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.drafts,
    required this.vendors,
    required this.orders,
  });

  /// Everything in memory: for development before Firebase, and for tests.
  factory AppDependencies.inMemory() => AppDependencies(
        auth: InMemoryAuthRepository(),
        drafts: InMemoryDraftRepository(),
        vendors: InMemoryVendorRepository(),
        orders: InMemoryOrderRepository(),
      );

  /// Live data sources backed by Firebase (Auth & Firestore).
  factory AppDependencies.firebase() => AppDependencies(
        auth: FirebaseAuthRepository(),
        drafts: FirestoreDraftRepository(),
        vendors: FirestoreVendorRepository(),
        orders: FirestoreOrderRepository(),
      );



  final AuthRepository auth;
  final DraftRepository drafts;
  final VendorRepository vendors;
  final OrderRepository orders;
}

/// Makes [AppDependencies] available below it: `AppScope.of(context).drafts`.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget. Wrap the app in AppScope.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => dependencies != oldWidget.dependencies;
}
