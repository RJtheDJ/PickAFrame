import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/data/design_codec.dart';
import 'package:pickaframe_application/data/finish_catalog.dart';
import 'package:pickaframe_application/models/design_summary.dart';
import 'package:pickaframe_application/models/draft.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_finish.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/models/order.dart';
import 'package:pickaframe_application/models/user_profile.dart';
import 'package:pickaframe_application/repositories/auth_repository.dart';
import 'package:pickaframe_application/repositories/in_memory/in_memory_repositories.dart';

const _design = FrameDesign(
  artworkMm: Size(612, 455),
  moulding: Moulding(profile: FrameProfile.stepped, faceWidthMm: 38),
  mat: MatSpec(
    topMm: 60, bottomMm: 75, leftMm: 55, rightMm: 55,
    color: Color(0xFFEFE6D2), coreColor: Color(0xFF151515),
    style: MountStyle.doubleMat, innerColor: Color(0xFF1F2A44), revealMm: 8,
  ),
  finish: ColorFinish(Color(0xFF7B1F1F)),
);

void expectSameDesign(FrameDesign actual, FrameDesign expected) {
  expect(encodeDesign(actual), encodeDesign(expected));
}

void main() {
  group('design codec', () {
    test('round-trips every field', () {
      expectSameDesign(decodeDesign(encodeDesign(_design)), _design);
    });

    test('catalogue finishes are stored by id and restored to the same finish', () {
      for (final finish in [...woodFinishes, ...metalFinishes, ...photoMouldings]) {
        final decoded = decodeDesign(encodeDesign(_design.copyWith(finish: finish)));
        expect(identical(decoded.finish, finish), isTrue, reason: finish.name);
      }
    });

    test('accepts whole numbers as ints, as Firestore returns them', () {
      final json = encodeDesign(_design);
      (json['moulding'] as Map)['faceWidthMm'] = 38;
      expect(decodeDesign(json).moulding.faceWidthMm, 38.0);
    });

    test('unknown finishes are a FormatException, not a crash', () {
      final json = encodeDesign(_design)..['finish'] = {'kind': 'wood', 'id': 'unobtanium'};
      expect(() => decodeDesign(json), throwsFormatException);
    });
  });

  test('drafts and orders survive a JSON round trip', () {
    final draft = Draft(
      id: 'd1',
      ownerUid: 'u1',
      title: 'Sunset study',
      design: _design,
      status: DraftStatus.exhibit,
      updatedAt: DateTime.utc(2026, 10, 15, 9),
    );
    final restored = Draft.fromJson(draft.toJson());
    expect(restored.toJson(), draft.toJson());

    final order = FramingOrder(
      id: 'o1',
      draftId: 'd1',
      customerUid: 'u1',
      vendorId: 'v1',
      specLines: describeDesign(_design),
      createdAt: DateTime.utc(2026, 10, 15),
      quoteRm: 180,
    );
    expect(FramingOrder.fromJson(order.toJson()).toJson(), order.toJson());
  });

  test('order stages advance in production order', () {
    expect(OrderStage.submitted.next, OrderStage.cut);
    expect(OrderStage.readyForDispatch.next, OrderStage.completed);
    expect(OrderStage.completed.next, isNull);
  });

  group('in-memory repositories', () {
    test('auth: register, role onboarding, sign out and back in', () async {
      final auth = InMemoryAuthRepository();
      final user = await auth.registerWithEmail(email: 'Ana@Example.com', password: 'pw', displayName: 'Ana');
      expect(user.role, isNull);

      await auth.setRole(UserRole.frameShopOwner);
      expect(auth.currentUser!.role!.needsLocation, isTrue);

      await auth.signOut();
      expect(auth.currentUser, isNull);
      await expectLater(
        auth.signInWithEmail(email: 'ana@example.com', password: 'nope'),
        throwsA(isA<AuthException>()),
      );
      final back = await auth.signInWithEmail(email: 'ana@example.com', password: 'pw');
      expect(back.role, UserRole.frameShopOwner);
    });

    test('drafts: watchers see saves and deletes, newest first, per owner', () async {
      final repo = InMemoryDraftRepository();
      Draft draft(String id, String owner, int day) => Draft(
            id: id, ownerUid: owner, title: id, design: _design,
            updatedAt: DateTime.utc(2026, 10, day),
          );

      final seen = <List<String>>[];
      final sub = repo.watchDrafts('me').listen((drafts) => seen.add([for (final d in drafts) d.id]));
      await pumpEventQueue();
      await repo.saveDraft(draft('old', 'me', 1));
      await repo.saveDraft(draft('theirs', 'someone else', 2));
      await repo.saveDraft(draft('new', 'me', 3));
      await repo.deleteDraft('old');
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.first, isEmpty);
      expect(seen.last, ['new']);
      expect(seen, contains(equals(['new', 'old'])));
    });

    test('orders: workshop moves an order through production', () async {
      final repo = InMemoryOrderRepository();
      await repo.submitOrder(FramingOrder(
        id: 'o1', draftId: 'd1', customerUid: 'artist', vendorId: 'shop',
        specLines: const [], createdAt: DateTime.utc(2026, 10, 15),
      ));
      await repo.updateStage('o1', OrderStage.cut);

      final forShop = await repo.watchVendorOrders('shop').first;
      final forArtist = await repo.watchCustomerOrders('artist').first;
      expect(forShop.single.stage, OrderStage.cut);
      expect(forArtist.single.id, 'o1');
    });
  });
}
