# PickAFrame architecture

How the app is organised, and where new features (Firebase, Google Maps, the
catalogue, orders) plug in. Read this before adding a screen or a backend.

## Layers (MVVM + repositories)

The app follows the MVVM structure from the proposal (section 3.2.2), plus a
**repository** layer for data access:

```
 views/  widgets/          what the user sees; no business logic
      │  listens to
 view_models/              screen state + actions (ChangeNotifier)
      │  uses
 models/  services/        pure data & maths  /  device features (camera, export, ...)
 rendering/                the frame visualizer engine (painters + GPU shader)
      │  reads & writes through
 repositories/             interfaces for stored data (auth, drafts, vendors, orders)
      ├─ in_memory/        working stand-ins (today, and in tests)
      └─ firebase/         Firebase implementations (to be added)
```

Rules that keep the layers independent:

1. **Screens never import Firebase.** Only `lib/repositories/firebase/` and
   `lib/app/` may. Screens and view models depend on the interfaces in
   `lib/repositories/`, obtained with `AppScope.of(context)`.
2. **Models are plain Dart.** Each stored model has `toJson`/`fromJson` using
   plain maps, which is what Firestore stores. `FrameDesign` uses
   `encodeDesign`/`decodeDesign` in `lib/data/design_codec.dart`.
3. **Lengths are millimetres** everywhere in code and storage. Only the UI
   shows cm/m (`lib/models/units.dart`).
4. **Catalogue items are stored by id** (`'cherry'`, `'gold_leaf'`), never
   copied, so updating a texture updates every saved draft.

## Folder map

| Path | What lives there |
|---|---|
| `lib/main.dart` | Entry point; picks the data sources (`AppDependencies`). |
| `lib/app/` | App-wide wiring: `AppDependencies` + `AppScope`. Routing and theme go here. |
| `lib/models/` | Data and pure logic: `FrameDesign`, `MatSpec`, mat presets, perspective maths, units, `Draft`, `FramingOrder`, `Vendor`, `UserProfile`. |
| `lib/data/` | Built-in catalogues (finishes, mat colours) and the design codec. |
| `lib/rendering/` | The 2.5D frame engine: layout (mm → px), lighting, profile shading, CPU painters, GPU shader painter. |
| `lib/services/` | Device and file work: picking/cropping artwork, ML Kit scanner, textures, export. |
| `lib/repositories/` | Data-access interfaces + `in_memory/` implementations. |
| `lib/view_models/` | One view model per screen. |
| `lib/views/` | Full screens. |
| `lib/widgets/` | Reusable pieces of screens (`widgets/editor/` = editor controls). |
| `shaders/` | `frame_material.frag`, the per-pixel lighting shader. |
| `assets/` | Wood/metal PBR textures, ornate moulding strips. |
| `tools/` | `make_moulding_strip.py`: turns a moulding photo into a strip + normal map. |
| `backend/` | Optional Python helper (background removal); not used by the app. |
| `test/` | Unit and widget tests (`flutter test`). |

## The visualizer engine (done)

- `FrameDesign` (mm) → `FrameLayout.fit` → screen rectangles.
- The moulding is drawn by `ShadedFramePainter` (GPU shader with normal and
  roughness maps, one light), falling back to `FramePainter` (CPU gradients)
  where shaders are unavailable.
- `MatPainter` draws bevels, the double-mat reveal and all cast shadows.
- `FrameRenderer` assembles frame, mat, artwork and wall. Its
  `RepaintBoundary` is what `renderPng` exports at 3000 px.

## Adding Firebase (backend teammate) (done)

1. Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`,
   `firebase_storage`, `google_sign_in`. Run `flutterfire configure`.
2. Create `lib/repositories/firebase/` with `FirebaseAuthRepository`,
   `FirestoreDraftRepository`, `FirestoreVendorRepository`,
   `FirestoreOrderRepository`, each `implements` the matching interface.
   The in-memory versions show the expected behaviour, and
   `test/data_layer_test.dart` shows the contract.
3. Add `AppDependencies.firebase()` in `lib/app/app_dependencies.dart`, then in
   `main.dart`:
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   runApp(FramingApp(dependencies: AppDependencies.firebase()));
   ```

### Firestore collections

Documents are exactly the models' `toJson()` output.

| Collection | Document id | From | Key fields |
|---|---|---|---|
| `users` | auth uid | `UserProfile` | `role` (`artist` / `galleryOwner` / `frameShopOwner`), `vendorId` |
| `vendors` | auto | `Vendor` | `ownerUid`, `latitude`, `longitude`, `specialties` |
| `drafts` | auto | `Draft` | `ownerUid`, `design` (see codec), `status`, `artworkUrl`, `updatedAt` |
| `orders` | auto | `FramingOrder` | `customerUid`, `vendorId`, `specLines`, `stage`, `quoteRm` |

Suggested indexes: `drafts` on (`ownerUid`, `updatedAt` desc); `orders` on
(`customerUid`, `createdAt` desc) and (`vendorId`, `createdAt` desc).

Security rules outline: users read/write their own `users` doc and their own
`drafts`; anyone signed in reads `vendors`; only a vendor's owner writes it;
an order is readable by its customer and its vendor's owner, and only the
vendor's owner changes `stage`.

**Storage:** `artworks/{uid}/{draftId}.jpg` (cropped artwork, from
`Artwork.image`) and `previews/{uid}/{draftId}.png` (from `renderPng`).

## Adding Google Maps (backend teammate)

- `google_maps_flutter` for the workshop directory map; a places
  autocomplete package for the vendor address picker during onboarding.
- The API key goes in `android/app/src/main/AndroidManifest.xml` (a
  `com.google.android.geo.API_KEY` meta-data entry) and `ios/Runner/AppDelegate.swift`.
  **Restrict it** to the app's package name/bundle id in Google Cloud and keep
  it out of public repos.
- Workshop data comes from `VendorRepository.watchVendors()`; the map only
  displays `Vendor.latitude/longitude`.

## Planned screens and navigation

From the BASE APP FUNCTION doc and the proposal wireframes (3.2.1):

| Screen | Wireframe | Data |
|---|---|---|
| Welcome & Discovery (upload hero, workshop carousel) | a | vendors | jasper 
| Sign up / log in, role selection, location pin | b | auth, vendors | Kah Han - ongoing
| Unified Frame Catalogue (search, filters, grid) | c | catalogue (see roadmap) | jasper
| Workshop Map Directory | d | vendors | kah han
| Saved Drafts & Portfolio | e | drafts | Jasper / Me
| Visualizer Workspace (current `EditorScreen`) | f | design, drafts | Me done
| Virtual Gallery Wall / in-room preview | g | drafts | Me - on going
| Order Specification & Production Tracker | h | orders, vendors | Jasper

Navigation: a bottom bar (Discover · Catalogue · Workshops · Drafts ·
Profile) for artists and gallery owners; frame shop owners land on a vendor
dashboard (orders, inventory). Route after sign-in from `UserProfile.role`;
send users with `role == null` to role selection. Put the router in
`lib/app/` (`go_router` handles role redirects well).
