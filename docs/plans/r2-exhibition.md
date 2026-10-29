# Plan: save artwork to Cloudflare R2 and show it in Exhibition View

Owner: Kah Han. Written 26 Oct 2026; status updated 28 Oct 2026.

This plan has three phases. Phase 1 is the current work.

1. **Phase 1 (current): R2 storage and Exhibition View.** A signed-in user
   saves a framed artwork; the images go to Cloudflare R2, the draft
   metadata goes to Firestore. The user then picks several saved drafts and
   sees them together on one wall.
2. **Phase 2 (next): login and sign-up screens.** Dedicated screens built from
   the team's screenshot, wired to the existing `AuthRepository`.
3. **Phase 3 (later): Google Maps onboarding.** Real location search and pin
   for Gallery Owner and Frame Shop Owner accounts.

## Status

| Part | Status |
|---|---|
| Task 1: Worker API | 🟡 Done and deployed to `https://artwork-worker.artwork-worker.workers.dev` on the real `pick-a-frame` bucket; checked by hand with real tokens, locally and deployed. Automated tests not written yet. |
| Task 2: Flutter storage + Save | ⬜ Not started. `Draft.artworkUrl` already exists. |
| Task 3: Saved Drafts + Exhibition View | 🟡 Built by RJ (29 Oct): Exhibit tab → `ExhibitScreen` (pick drafts) → `ExhibitRoomScreen` (several pieces in the existing rooms). Shows a placeholder artwork until Task 2 sets `AppDependencies.artworkStorage`. |
| Task 4: End-to-end walkthrough | ⬜ Not started. |

The R2 binding `ARTWORKS` already points at a bucket named `pick-a-frame` in
`wrangler.jsonc`.

## Decisions

- **Images go to R2, not Firebase Storage.** The proposal named Firebase
  Cloud Storage; the team has since decided on R2. Firebase Auth and
  Firestore stay for identity and draft metadata. Do not move metadata to D1.
- **The Worker writes to R2 for the app.** The app sends the image plus the
  user's Firebase ID token; the Worker verifies the token and writes through
  its R2 binding. Rejected alternatives:
  - Presigned upload URLs: less image traffic through the Worker, but adds
    URL signing and expiry handling the demo does not need.
  - R2 credentials inside the Flutter app: anyone can extract them from the
    app and read the whole bucket.
- **One image per draft: the cropped artwork.** The framed look is not
  stored as an image. Firestore already holds the full `design`, so Saved
  Drafts and Exhibition View draw each piece on the device with
  `FrameRenderer` from the artwork plus its design. This halves storage,
  needs only one upload per save, and a changed frame design shows up
  without re-uploading. The cost is rendering several frames on the phone
  in Exhibition View. (Decided 29 Oct 2026; the first draft of this plan
  also stored a rendered preview PNG.) `Draft.previewUrl` stays in the
  model, unused.
- **Exhibition View is not saved.** It is a temporary arrangement for the
  session. Removing a piece from the view never deletes the draft.

### Out of scope for this plan

- Public exhibitions or sharing between users; each user sees only their
  own drafts.
- Saved exhibition layouts, drag-and-drop placement, spacing guides,
  furniture-based scale, presets, bulk pricing, shared reviews.
- Deploying the Worker to production (needs the Cloudflare account details).

## Security rules (check these in review)

- The Worker validates the Firebase ID token before touching R2. Missing,
  expired, malformed or wrong-project tokens get `401`.
- The owner UID comes only from the verified token, never from the request.
  User A must not be able to read or overwrite user B's objects.
- No R2 credentials in the app, and no public object URLs.
- Only PNG, at most 25 MiB per object, counted from the actual body bytes
  (not only the client-supplied `Content-Length`). Otherwise `415` / `413`.
- The Firestore draft is written only after the artwork upload succeeds.
  The object path is fixed per draft, so a retry overwrites instead of
  duplicating. An upload whose Firestore write then fails is not cleaned
  up; objects are deleted when the user deletes the draft.
- A missing artwork or a network error shows a retryable message, never a
  broken image or a crash.

## Worker API

- `PUT /v1/drafts/{draftId}/artwork` with
  `Authorization: Bearer <Firebase ID token>` and `Content-Type: image/png`.
  Returns `{ "url": "/v1/drafts/{draftId}/artwork" }`.
- `GET` on the same path returns the PNG, only to its owner.
- R2 key: `drafts/{verifiedUid}/{draftId}/artwork.png`.
- The last path segment is an allow-list with one entry, `artwork`; any
  other name gets `404`. Keeping the segment leaves room for another image
  type later without changing the URL shape.
- Worker config: R2 binding `ARTWORKS`, variable
  `FIREBASE_PROJECT_ID = pick-a-frame` (not a secret). No API secrets or
  account ID in source control.

> The earlier design draft used keys `artworks/{uid}/{draftId}.png` and
> `previews/{uid}/{draftId}.png`, and `ARCHITECTURE.md` used to describe
> Firebase Storage paths. The key above replaces both.

Status codes: `401` missing, malformed or invalid token; `404` unknown route,
unknown asset name or missing object; `415` not `image/png`; `413` over
25 MiB. The `Content-Type` check runs before the body is read, so a wrong
type is rejected without reading the upload.

## Task 1: Authenticated Worker API

Files (in `cloudflare/artwork-worker/`): `package.json`, `tsconfig.json`,
`wrangler.jsonc`, `src/index.ts`, `src/firebase_token.ts`,
`test/index.test.ts`.

- [x] Verify the token with `jose` against Google's Secure Token JWKs
      (`createRemoteJWKSet`): RS256 signature, `aud == FIREBASE_PROJECT_ID`,
      `iss == https://securetoken.google.com/{FIREBASE_PROJECT_ID}`, not
      expired, non-empty `sub`. Use `sub` as the UID. (Inline in
      `src/index.ts`.)
- [x] `src/index.ts`: authenticate first; accept only the exact route and
      the `artwork` asset; require PNG; enforce the size limit on the bytes
      actually read; derive the key from the verified UID.
- [x] Add the `FIREBASE_PROJECT_ID` variable to `wrangler.jsonc` and run
      `npx wrangler types`.
- [x] `npx tsc --noEmit` shows no errors.
- [x] Prove by hand that user A cannot read user B's artwork (two test
      accounts, same `draftId`): B's GET returns 404, and B's PUT to the
      same URL leaves A's object unchanged. Passed 29 Oct 2026.
- [x] Add `Cache-Control: private, no-store` to GET and PUT responses.
- [x] Replace the Wrangler starter comment at the top of `src/index.ts`
      with a description of the Worker.
- [ ] Replace the starter test in `test/index.spec.ts` with route tests
      (inject a token verifier, so tests don't need real Google tokens):
      owner upload/read works; missing or invalid token → 401; user A
      cannot read user B's draft; unknown asset → 404; non-PNG → 415; over
      25 MiB → 413; unknown object → 404. Set the `test` script to
      `vitest run`; `npm test` passes.

## Task 2: Flutter storage and the Save button

Files: modify `pubspec.yaml`, `lib/app/app_dependencies.dart`,
`lib/models/draft.dart`, `lib/views/editor_screen.dart`; create
`lib/services/artwork_storage.dart`,
`lib/services/cloudflare_artwork_storage.dart`,
`lib/services/in_memory_artwork_storage.dart`,
`lib/services/draft_save_service.dart`; tests in `test/services/`.

Interfaces:

```dart
// ArtworkStorage
Future<String> uploadArtwork({required String draftId, required Uint8List png});
Future<Uint8List> loadArtwork(String workerUrl);

// DraftSaveService
Future<Draft> saveDraft({required Draft draft, required Uint8List artworkPng});
```

- [ ] Storage-client tests (`http/testing.dart`): uploads send the ID token,
      PNG content type and exact bytes; the returned Worker path is kept;
      reads send the token; error responses throw a user-readable exception.
- [ ] Add `http: ^1.6.0`. Implement the Worker client (base URL from
      `--dart-define=CLOUDFLARE_WORKER_BASE_URL=...`, token from
      `getIdToken()`) and an in-memory version for
      `AppDependencies.inMemory()`.
- [ ] Save-order tests: the upload finishes before
      `DraftRepository.saveDraft`; the draft stores the Worker path; a
      failed upload never writes the draft; retrying the same `Draft.id`
      reuses the same path.
- [ ] Implement `DraftSaveService`; store the path in `artworkUrl`.
- [ ] Add **Save** to `EditorScreen`: requires sign-in and an artwork;
      create one draft ID before the first upload and keep it across
      retries; upload the cropped `Artwork.image` as PNG; show progress and
      a retry message. The 3,000 px export stays as it is.
- [ ] Both service tests pass.

## Task 3: Saved Drafts and Exhibition View

Files: modify `lib/views/catalog/catalog_screen.dart`,
`lib/views/editor_screen.dart`; create `lib/views/saved_drafts_screen.dart`,
`lib/views/exhibition_view_screen.dart`,
`lib/widgets/exhibition/exhibition_wall.dart`; test
`test/views/saved_drafts_screen_test.dart`.

- [ ] Widget test: only the current user's drafts show; selecting two
      enables "Open Exhibition"; empty list shows an empty state; a failed
      preview shows a retryable error.
- [ ] `SavedDraftsScreen`: `watchDrafts(currentUser.uid)`; for each draft,
      load its artwork through `ArtworkStorage` and draw it framed with
      `FrameRenderer` and the draft's `design`; selection kept on the
      screen; open the exhibition once two or more are selected.
- [ ] `ExhibitionWall` + `ExhibitionViewScreen`: draw each selected draft
      the same way and space them evenly on a wall using the existing room
      palette. Leaving or deselecting never deletes anything.
- [ ] Navigation: Catalog's centre `+` → `EditorScreen`; the Drafts tab →
      `SavedDraftsScreen`; Exhibit → the selection flow; after saving, link
      to Saved Drafts.
- [ ] The widget test passes.

> Decided 29 Oct (RJ): Exhibition View extends `RoomPreview`, which now
> hangs several pieces (`RoomPiece`), each draggable. The editor's
> Edit | Preview toggle is gone; rooms are only reached from the Exhibit tab.
> `lib/services/artwork_storage.dart` holds the `ArtworkStorage` interface
> from Task 2 (interface only); `AppDependencies.artworkStorage` is null
> until Task 2 fills it. For "after saving, link to Saved Drafts", open
> `ExhibitScreen(initialSelection: {draft.id})`.

## Task 4: End-to-end check

- [ ] Document local Worker setup in the README: `npm install`, the R2
      binding name, the `pick-a-frame` project ID, `npx wrangler dev`, and
      `CLOUDFLARE_WORKER_BASE_URL` for the Android emulator and for a phone.
- [ ] `flutter analyze` is clean and the three new test files pass.
- [ ] Walk through it against the local Worker: sign in with Google, Catalog
      `+`, crop an image, frame it, save; check one R2 object and one
      Firestore draft; save a second one; open both in Exhibition View.
      Stop the Worker, try to save, restart, retry: no half-saved draft.
- [x] Deploy the Worker (it uses the real bucket) and repeat the Worker
      checks against the deployed address: 401 without or with a fake
      token, owner PUT/GET, another user gets 404 and cannot overwrite,
      415 for non-PNG, 404 for an unknown asset. Passed 29 Oct 2026. Local
      `npm run dev` stays on the simulated bucket (no `remote: true`).

## Phase 2: login and sign-up screens

- Separate login and sign-up/role-setup screens in the screenshot's style.
- Login: Google and email/password. Sign-up: Google or email/password, role
  cards, and a required consent checkbox before authentication.
- Artist needs no venue fields. Gallery Owner and Frame Shop Owner show
  venue/address and business fields: name and address required; unit/suite
  and opening hours optional. Email sign-up also needs a name field (the
  registration API requires a display name).
- Consent text: "Consent to Personal Data Protection Act (PDPA 2010)
  processing of commercial workshop coordinates, architectural order specs,
  and business profile metrics". Required, but not stored in this prototype.
- Google sign-up: pick a role and consent first, then authenticate, then
  save the role. An existing account without a role goes to role setup on
  every sign-in until it is finished. Accounts with a role skip onboarding.
- Email sign-up: register, then save the role; if saving the role fails,
  the next sign-in returns to role setup.
- Must fit small phone screens.
- `UserProfile` has no fields yet for venue details or consent; add them in
  this phase.

## Phase 3: Google Maps onboarding

Real place search and a location pin for Gallery Owner and Frame Shop
Owner, saved with the venue. The proposal calls this essential; it comes
after Phase 1. See `ARCHITECTURE.md` for the API-key setup.

## Open questions

- Worker base URL for local runs and, later, the deployed Worker.
- Final image size limit and PNG quality (25 MiB cap for now).
- Does the assignment need a live map search in onboarding, or can the
  screenshot's map be static?
