import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickaframe_application/app/app_dependencies.dart';
import 'package:pickaframe_application/data/finish_catalog.dart';
import 'package:pickaframe_application/models/draft.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/repositories/in_memory/in_memory_repositories.dart';
import 'package:pickaframe_application/services/artwork_storage.dart';
import 'package:pickaframe_application/view_models/exhibit_viewmodel.dart';
import 'package:pickaframe_application/views/exhibit_screen.dart';

// A valid 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

class _FakeStorage implements ArtworkStorage {
  bool fail = false;
  final requested = <String>[];

  @override
  Future<Uint8List> loadArtwork(String workerUrl) async {
    requested.add(workerUrl);
    if (fail) throw Exception('offline');
    return _png;
  }

  @override
  Future<String> uploadArtwork({required String draftId, required Uint8List png}) =>
      throw UnimplementedError();
}

final _design = FrameDesign(
  artworkMm: const Size(400, 300),
  moulding: const Moulding(profile: FrameProfile.flat, faceWidthMm: 30),
  mat: const MatSpec.uniform(50),
  finish: woodFinishes.first,
);

Draft _draft(String id, String owner, int day, {String? artworkUrl}) => Draft(
      id: id,
      ownerUid: owner,
      title: 'Draft $id',
      design: _design,
      updatedAt: DateTime.utc(2026, 10, day),
      artworkUrl: artworkUrl,
    );

void main() {
  testWidgets('shows only the signed-in user\'s drafts and loads their artwork', (tester) async {
    await tester.runAsync(() async {
      final auth = InMemoryAuthRepository();
      final drafts = InMemoryDraftRepository();
      final storage = _FakeStorage()..fail = true;
      final me = await auth.registerWithEmail(email: 'a@b.c', password: 'pw', displayName: 'A');
      await drafts.saveDraft(_draft('old', me.uid, 1, artworkUrl: '/v1/drafts/old/artwork'));
      await drafts.saveDraft(_draft('new', me.uid, 2));
      await drafts.saveDraft(_draft('theirs', 'someone-else', 3));

      final vm = ExhibitViewModel(
        auth: auth,
        drafts: drafts,
        artworkStorage: storage,
        initialSelection: {'new'},
        loadShader: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(vm.drafts!.map((d) => d.id), ['new', 'old'], reason: 'own drafts, newest first');
      expect(vm.selectedDrafts.map((d) => d.id), ['new']);

      // The download failed: a retry is offered, and it works once online.
      final old = vm.drafts!.last;
      expect(vm.artworkFailed('old'), isTrue);
      expect(vm.pieceFor(old).artwork, isNull);
      storage.fail = false;
      vm.retryArtwork(old);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(vm.artworkFailed('old'), isFalse);
      expect(vm.pieceFor(old).artwork, isNotNull);
      expect(storage.requested, ['/v1/drafts/old/artwork', '/v1/drafts/old/artwork']);

      vm.toggle('old');
      vm.toggle('new');
      expect(vm.selectedDrafts.map((d) => d.id), ['old']);

      // A deleted draft drops out of the selection.
      await drafts.deleteDraft('old');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(vm.selectedDrafts, isEmpty);

      await auth.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(vm.user, isNull);
      expect(vm.drafts, isEmpty);
      vm.dispose();
    });
  });

  testWidgets('Exhibit screen: sign-in message, then pick drafts to open the room', (tester) async {
    final deps = AppDependencies.inMemory();
    Widget app() => AppScope(dependencies: deps, child: const MaterialApp(home: ExhibitScreen()));

    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.textContaining('Sign in'), findsOneWidget);

    await tester.runAsync(() async {
      final me = await deps.auth.registerWithEmail(email: 'a@b.c', password: 'pw', displayName: 'A');
      await deps.drafts.saveDraft(_draft('one', me.uid, 1));
      await deps.drafts.saveDraft(_draft('two', me.uid, 2));
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('Draft one'), findsOneWidget);
    expect(find.text('Pick drafts to hang'), findsOneWidget);

    await tester.tap(find.text('Draft one'));
    await tester.tap(find.text('Draft two'));
    await tester.pump();
    expect(find.text('Open room (2)'), findsOneWidget);

    await tester.tap(find.text('Open room (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Exhibit room'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
