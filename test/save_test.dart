import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pickaframe_application/data/finish_catalog.dart';
import 'package:pickaframe_application/models/draft.dart';
import 'package:pickaframe_application/models/frame_design.dart';
import 'package:pickaframe_application/models/frame_profile.dart';
import 'package:pickaframe_application/models/mat_spec.dart';
import 'package:pickaframe_application/models/moulding.dart';
import 'package:pickaframe_application/repositories/in_memory/in_memory_repositories.dart';
import 'package:pickaframe_application/services/artwork_storage.dart';
import 'package:pickaframe_application/services/cloudflare_artwork_storage.dart';
import 'package:pickaframe_application/services/draft_save_service.dart';

final _png = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1, 2, 3]);

final _draft = Draft(
  id: 'd1',
  ownerUid: 'u1',
  title: 'Sunset',
  design: FrameDesign(
    artworkMm: const Size(400, 300),
    moulding: const Moulding(profile: FrameProfile.flat, faceWidthMm: 30),
    mat: const MatSpec.uniform(50),
    finish: woodFinishes.first,
  ),
  updatedAt: DateTime.utc(2026, 10, 30),
);

class _FailingStorage implements ArtworkStorage {
  @override
  Future<String> uploadArtwork({required String draftId, required Uint8List png}) =>
      Future.error(const ArtworkStorageException('offline'));

  @override
  Future<Uint8List> loadArtwork(String workerUrl) => throw UnimplementedError();
}

void main() {
  group('CloudflareArtworkStorage', () {
    test('uploads the exact PNG with the user\'s token and keeps the Worker path', () async {
      late http.Request sent;
      final storage = CloudflareArtworkStorage(
        idToken: () async => 'token-123',
        baseUrl: 'https://worker.test',
        client: MockClient((request) async {
          sent = request;
          return http.Response(jsonEncode({'url': '/v1/drafts/d1/artwork'}), 200);
        }),
      );

      final url = await storage.uploadArtwork(draftId: 'd1', png: _png);

      expect(url, '/v1/drafts/d1/artwork');
      expect(sent.method, 'PUT');
      expect(sent.url.toString(), 'https://worker.test/v1/drafts/d1/artwork');
      expect(sent.headers['Authorization'], 'Bearer token-123');
      expect(sent.headers['Content-Type'], 'image/png');
      expect(sent.bodyBytes, _png);
    });

    test('reads back with the token', () async {
      late http.Request sent;
      final storage = CloudflareArtworkStorage(
        idToken: () async => 't',
        baseUrl: 'https://worker.test',
        client: MockClient((request) async {
          sent = request;
          return http.Response.bytes(_png, 200);
        }),
      );
      expect(await storage.loadArtwork('/v1/drafts/d1/artwork'), _png);
      expect(sent.headers['Authorization'], 'Bearer t');
    });

    test('server errors become readable messages', () async {
      for (final (status, words) in [(401, 'sign-in'), (413, 'too large'), (415, 'PNG'), (500, 'problem')]) {
        final storage = CloudflareArtworkStorage(
          idToken: () async => 't',
          client: MockClient((_) async => http.Response('', status)),
        );
        await expectLater(
          storage.uploadArtwork(draftId: 'd1', png: _png),
          throwsA(isA<ArtworkStorageException>().having((e) => e.message, 'message', contains(words))),
        );
      }
    });

    test('signed out: nothing is sent', () async {
      var calls = 0;
      final storage = CloudflareArtworkStorage(
        idToken: () async => null,
        client: MockClient((_) async {
          calls++;
          return http.Response('', 200);
        }),
      );
      await expectLater(storage.loadArtwork('/x'), throwsA(isA<ArtworkStorageException>()));
      expect(calls, 0);
    });
  });

  group('DraftSaveService', () {
    test('uploads the artwork, then saves the draft pointing at it', () async {
      final drafts = InMemoryDraftRepository();
      final storage = _RecordingStorage();
      final saved = await DraftSaveService(drafts: drafts, storage: storage)
          .saveDraft(draft: _draft, artworkPng: _png);

      expect(saved.artworkUrl, '/v1/drafts/d1/artwork');
      expect(storage.uploads, ['d1']);
      final stored = await drafts.watchDrafts('u1').first;
      expect(stored.single.artworkUrl, '/v1/drafts/d1/artwork');
    });

    test('a failed upload never writes the draft', () async {
      final drafts = InMemoryDraftRepository();
      await expectLater(
        DraftSaveService(drafts: drafts, storage: _FailingStorage()).saveDraft(draft: _draft, artworkPng: _png),
        throwsA(isA<ArtworkStorageException>()),
      );
      expect(await drafts.watchDrafts('u1').first, isEmpty);
    });
  });
}

class _RecordingStorage implements ArtworkStorage {
  final uploads = <String>[];

  @override
  Future<String> uploadArtwork({required String draftId, required Uint8List png}) async {
    uploads.add(draftId);
    return '/v1/drafts/$draftId/artwork';
  }

  @override
  Future<Uint8List> loadArtwork(String workerUrl) => throw UnimplementedError();
}
