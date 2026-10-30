import 'dart:async';

import '../../models/catalog_moulding.dart';
import '../../models/draft.dart';
import '../../models/order.dart';
import '../../models/user_profile.dart';
import '../../models/vendor.dart';
import '../../models/venue.dart';
import '../auth_repository.dart';
import '../draft_repository.dart';
import '../moulding_repository.dart';
import '../order_repository.dart';
import '../vendor_repository.dart';

// Working stand-ins for the Firebase repositories: everything is kept in
// memory and lost when the app restarts. They let screens be built and demoed
// before Firebase is set up, and keep widget tests fast and offline.

/// A keyed collection that can be watched, like a Firestore query.
class _Collection<T> {
  final _items = <String, T>{};
  final _changes = StreamController<void>.broadcast();

  Iterable<T> get values => _items.values;

  T? operator [](String id) => _items[id];

  void put(String id, T item) {
    _items[id] = item;
    _changes.add(null);
  }

  void remove(String id) {
    if (_items.remove(id) != null) _changes.add(null);
  }

  Stream<List<T>> watch(bool Function(T) where, int Function(T, T) compare) {
    List<T> snapshot() => _items.values.where(where).toList()..sort(compare);
    return _watch(_changes.stream, snapshot);
  }
}

/// Emits [current] on listen and again after every [changes] event.
Stream<T> _watch<T>(Stream<Object?> changes, T Function() current) {
  StreamSubscription<Object?>? subscription;
  late final StreamController<T> controller;
  controller = StreamController<T>(
    onListen: () {
      controller.add(current());
      subscription = changes.listen((_) => controller.add(current()));
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}

class InMemoryAuthRepository implements AuthRepository {
  final _accounts = <String, ({String password, UserProfile profile})>{};
  final _changes = StreamController<UserProfile?>.broadcast();
  UserProfile? _current;

  @override
  UserProfile? get currentUser => _current;

  @override
  Stream<UserProfile?> watchUser() => _watch(_changes.stream, () => _current);

  @override
  Future<UserProfile> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException('An account already exists for that email.');
    }
    final profile = UserProfile(
      uid: 'local-${_accounts.length + 1}',
      email: key,
      displayName: displayName,
    );
    _accounts[key] = (password: password, profile: profile);
    return _signIn(profile);
  }

  @override
  Future<UserProfile> signInWithEmail({required String email, required String password}) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthException('Wrong email or password.');
    }
    return _signIn(account.profile);
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    const key = 'demo@pickaframe.local';
    final existing = _accounts[key];
    if (existing != null) return _signIn(existing.profile);
    return registerWithEmail(email: key, password: '', displayName: 'Demo User');
  }

  @override
  Future<UserProfile> setRole(UserRole role, {Venue? venue}) async {
    final current = _current;
    if (current == null) throw const AuthException('Not signed in.');
    final updated = current.copyWith(
      role: role,
      venue: venue,
      vendorId: role == UserRole.frameShopOwner ? current.uid : null,
    );
    final account = _accounts[current.email]!;
    _accounts[current.email] = (password: account.password, profile: updated);
    return _signIn(updated);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  UserProfile _signIn(UserProfile profile) {
    _current = profile;
    _changes.add(profile);
    return profile;
  }
}

class InMemoryDraftRepository implements DraftRepository {
  final _drafts = _Collection<Draft>();

  @override
  Stream<List<Draft>> watchDrafts(String ownerUid) => _drafts.watch(
        (d) => d.ownerUid == ownerUid,
        (a, b) => b.updatedAt.compareTo(a.updatedAt),
      );

  @override
  Future<void> saveDraft(Draft draft) async => _drafts.put(draft.id, draft);

  @override
  Future<void> deleteDraft(String draftId) async => _drafts.remove(draftId);
}

class InMemoryVendorRepository implements VendorRepository {
  final _vendors = _Collection<Vendor>();

  @override
  Stream<List<Vendor>> watchVendors() => _vendors.watch((_) => true, (a, b) => a.name.compareTo(b.name));

  @override
  Future<Vendor?> getVendor(String vendorId) async => _vendors[vendorId];

  @override
  Future<void> saveVendor(Vendor vendor) async => _vendors.put(vendor.id, vendor);
}

class InMemoryOrderRepository implements OrderRepository {
  final _orders = _Collection<FramingOrder>();

  int _newestFirst(FramingOrder a, FramingOrder b) => b.createdAt.compareTo(a.createdAt);

  @override
  Stream<List<FramingOrder>> watchCustomerOrders(String customerUid) =>
      _orders.watch((o) => o.customerUid == customerUid, _newestFirst);

  @override
  Stream<List<FramingOrder>> watchVendorOrders(String vendorId) =>
      _orders.watch((o) => o.vendorId == vendorId, _newestFirst);

  @override
  Future<void> submitOrder(FramingOrder order) async => _orders.put(order.id, order);

  @override
  Future<void> updateStage(String orderId, OrderStage stage) async {
    final order = _orders[orderId];
    if (order == null) throw StateError('No order $orderId');
    _orders.put(orderId, order.copyWith(stage: stage));
  }

  @override
  Future<void> setQuote(String orderId, double quoteRm) async {
    final order = _orders[orderId];
    if (order == null) throw StateError('No order $orderId');
    _orders.put(orderId, order.copyWith(quoteRm: quoteRm));
  }
}

class InMemoryMouldingRepository implements MouldingRepository {
  final _mouldings = _Collection<CatalogMoulding>();

  int _newestFirst(CatalogMoulding a, CatalogMoulding b) => b.createdAt.compareTo(a.createdAt);

  @override
  Stream<List<CatalogMoulding>> watchMouldings() => _mouldings.watch((_) => true, _newestFirst);

  @override
  Stream<List<CatalogMoulding>> watchVendorMouldings(String vendorId) =>
      _mouldings.watch((m) => m.vendorId == vendorId, _newestFirst);

  @override
  Future<void> saveMoulding(CatalogMoulding moulding) async => _mouldings.put(moulding.id, moulding);

  @override
  Future<void> deleteMoulding(String mouldingId) async => _mouldings.remove(mouldingId);
}
