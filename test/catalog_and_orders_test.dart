import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/app/app_dependencies.dart';
import 'package:pickaframe_application/data/design_codec.dart';
import 'package:pickaframe_application/data/moulding_starter_set.dart';
import 'package:pickaframe_application/models/catalog_moulding.dart';
import 'package:pickaframe_application/models/draft.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_finish.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/models/order.dart';
import 'package:pickaframe_application/models/vendor.dart';
import 'package:pickaframe_application/views/catalog/catalog_screen.dart';
import 'package:pickaframe_application/views/orders/new_order_screen.dart';

final _base = FrameDesign(
  artworkMm: const Size(400, 300),
  moulding: const Moulding(profile: FrameProfile.flat, faceWidthMm: 20),
  mat: const MatSpec.uniform(50),
  finish: const ColorFinish(Color(0xFF000000)),
);

const _shop = Vendor(
  id: 'shop',
  ownerUid: 'shop',
  name: 'Bangsar Frames',
  address: 'Jalan Telawi, Bangsar',
  latitude: 3.13,
  longitude: 101.67,
);

void main() {
  group('CatalogMoulding', () {
    final walnut = starterMouldings('shop').first; // Cherry Classic 35mm, RM 38/m

    test('round-trips through JSON, finish included', () {
      for (final m in starterMouldings('shop')) {
        expect(CatalogMoulding.fromJson(m.toJson()).toJson(), m.toJson(), reason: m.name);
      }
    });

    test('applies its look to a design and remembers which product it is', () {
      final design = walnut.applyTo(_base);
      expect(design.moulding.catalogId, walnut.id);
      expect(design.moulding.faceWidthMm, walnut.faceWidthMm);
      expect(identical(design.finish, walnut.finish), isTrue);
      expect(decodeDesign(encodeDesign(design)).moulding.catalogId, walnut.id);
    });

    test('changing the moulding makes it a custom frame', () {
      final design = walnut.applyTo(_base);
      expect(design.moulding.copyWith(faceWidthMm: 40).catalogId, isNull);
    });

    test('prices from the moulding length the design needs', () {
      final design = walnut.applyTo(_base);
      // Outer 400+100+70 x 300+100+70 = 570 x 470 mm -> 2.08 m of moulding.
      expect(design.mouldingLengthMm, 2080);
      expect(walnut.priceFor(design), closeTo(38 * 2.08, 1e-9));
    });

    test('unknown finishes are a FormatException', () {
      final json = walnut.toJson()..['finish'] = {'kind': 'wood', 'id': 'unobtanium'};
      expect(() => CatalogMoulding.fromJson(json), throwsFormatException);
    });
  });

  test('orders keep their design, title and estimate through JSON', () {
    final order = FramingOrder(
      id: 'o1',
      draftId: 'd1',
      customerUid: 'artist',
      vendorId: 'shop',
      title: 'Sunset',
      specLines: const [('Artwork', '40 × 30 cm')],
      design: _base,
      estimateRm: 79.04,
      createdAt: DateTime.utc(2026, 10, 30),
    );
    final back = FramingOrder.fromJson(order.toJson());
    expect(back.toJson(), order.toJson());
    expect(back.priceRm, 79.04, reason: 'estimate until the shop quotes');
    expect(back.copyWith(quoteRm: 90).priceRm, 90);
  });

  testWidgets('catalogue shows live mouldings with their workshop', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final deps = AppDependencies.inMemory();
    await deps.vendors.saveVendor(_shop);
    for (final m in starterMouldings('shop').take(2)) {
      await deps.mouldings.saveMoulding(m);
    }

    await tester.pumpWidget(AppScope(dependencies: deps, child: const MaterialApp(home: CatalogScreen())));
    await tester.pump();
    await tester.pump();

    expect(find.text('Cherry Classic 35mm'), findsOneWidget);
    expect(find.text('Natural Oak 25mm'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget, reason: 'no fake draft count when signed out');

    // A moulding added elsewhere appears without reloading.
    await deps.mouldings.saveMoulding(starterMouldings('shop')[2]);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50)); // let the stream reach the screen
    }
    expect(find.text('Matte Black 20mm', skipOffstage: false), findsOneWidget);
  });

  testWidgets('an artist orders a catalogue draft; the shop is suggested and priced', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final deps = AppDependencies.inMemory();
    final walnut = starterMouldings('shop').first;
    await deps.vendors.saveVendor(_shop);
    await deps.vendors.saveVendor(const Vendor(
      id: 'other', ownerUid: 'other', name: 'Other Shop', address: 'Cheras', latitude: 3.1, longitude: 101.7,
    ));
    await deps.mouldings.saveMoulding(walnut);
    final artist = await deps.auth.registerWithEmail(email: 'a@b.c', password: 'pw', displayName: 'Ana');
    final design = walnut.applyTo(_base);
    await deps.drafts.saveDraft(Draft(
      id: 'd1', ownerUid: artist.uid, title: 'Sunset', design: design, updatedAt: DateTime.utc(2026, 10, 30),
    ));

    await tester.pumpWidget(AppScope(dependencies: deps, child: const MaterialApp(home: NewOrderScreen())));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bangsar Frames (sells this moulding)'), findsOneWidget);
    final estimate = walnut.priceFor(design);
    expect(find.textContaining('RM ${estimate.toStringAsFixed(2)}'), findsOneWidget);

    await tester.tap(find.text('Send order to Bangsar Frames'));
    await tester.pump();

    // Widget tests run on a fake clock; real stream reads need runAsync.
    final orders = (await tester.runAsync(() => deps.orders.watchVendorOrders('shop').first))!;
    expect(orders, hasLength(1));
    final order = orders.single;
    expect(order.customerUid, artist.uid);
    expect(order.title, 'Sunset');
    expect(order.estimateRm, closeTo(estimate, 1e-9));
    expect(order.quoteRm, isNull);
    expect(order.stage, OrderStage.submitted);
    expect(order.design!.moulding.catalogId, walnut.id);

    // The workshop prices and progresses it.
    final updated = (await tester.runAsync(() async {
      await deps.orders.setQuote(order.id, 95);
      await deps.orders.updateStage(order.id, OrderStage.cut);
      return deps.orders.watchCustomerOrders(artist.uid).first;
    }))!
        .single;
    expect(updated.priceRm, 95);
    expect(updated.stage, OrderStage.cut);
  });
}
