# PickAFrame roadmap

Every feature from the BASE APP FUNCTION doc and the proposal (section 3.1),
who owns it, and where it stands. Last updated 28 Oct 2026.

Legend: ✅ done · 🟡 in progress / groundwork in place · ⬜ not started

## Who owns what

| Screen / area | Owner |
|---|---|
| Visualizer workspace, in-room preview, virtual gallery wall | RJ |
| Welcome & discovery, unified frame catalogue, order specification | Jasper |
| Saved drafts | Jasper / RJ |
| Firebase, sign up / log in, R2 image storage, workshop map | Kah Han |

## Done

| Feature | Owner | Notes |
|---|---|---|
| Upload artwork from gallery / camera | RJ | `ArtworkCropScreen` |
| 4-corner perspective crop, rotate, re-crop | RJ | `models/perspective.dart` |
| ML Kit document scanner (auto edge detection) | RJ | Android only |
| Exact artwork size (W × H in cm) | RJ | |
| 8 moulding profiles, paint / wood / metal / ornate finishes | RJ | |
| Texture & lighting control (light angle slider) | RJ | GPU shader + normal maps |
| Precision matting: 4 independent borders, golden ratio, 3:1, bottom-weighted | RJ | |
| Mount styles: flat, double, float; board + core colours | RJ | |
| Export: save to gallery / share with design details | RJ | 3000 px PNG |
| In-room preview: 4 drawn rooms, 10 wall colours, true scale + zoom, drag to hang, furniture for scale, room export | RJ | Edit \| Preview toggle; `RoomPreview` |
| Firebase Auth + Firestore repositories (auth, drafts, vendors, orders) | Kah Han | `lib/repositories/firebase/`; the app runs on them |
| Google sign-in button on the welcome screen | Kah Han | `quick_auth_section.dart` |
| Welcome / landing screen (Screen a) | Jasper | `WelcomeScreen` |
| Catalogue screen layout (Screen c): header, tabs, search, filter and sort bar, moulding grid, exhibition banner, map placeholder, bottom bar | Jasper | `CatalogScreen`, `widgets/catalog/` |

## Now

| # | Feature | Owner | Status | What's needed |
|---|---|---|---|---|
| 1 | Save drafts: images to Cloudflare R2, metadata to Firestore | Kah Han | 🟡 | Worker is a starter project only. Full task list: [plans/r2-exhibition.md](plans/r2-exhibition.md), Tasks 1–2. |
| 2 | Saved Drafts screen + Exhibition View (several framed pieces on one wall) | Kah Han | ⬜ | Same plan, Task 3. Agree with RJ how it relates to the virtual gallery wall. |
| 3 | Virtual gallery wall | RJ | 🟡 | One piece per room works today (`RoomPreview`). |
| 4 | Sign up / log in screens (email, Google) + role selection | Kah Han | 🟡 | Auth methods exist; screens not built. Plan Phase 2. |
| 5 | Catalogue behaviour: real filters, sort, search; buttons wired | Jasper | 🟡 | Layout is done; buttons are styled with callbacks still to fill in. |
| 6 | App shell: bottom navigation, role-based start screen, router | — | ⬜ | See ARCHITECTURE.md, "Screens and navigation". |
| 7 | Order specification sheet | Jasper | 🟡 | `describeDesign` gives the lines. Add rebate/glass/backing cut sizes and a PDF or image export. |
| 8 | Workshop directory on a map | Kah Han | 🟡 | `Vendor` + `VendorRepository` exist; map placeholder card in the catalogue. Add `google_maps_flutter` and a few real KL workshops. |

The proposal's Gantt chart had testing until 19 Oct and demo &
documentation on 20–27 Oct.

## Later

| Feature | Area | Status | Notes |
|---|---|---|---|
| Vendor onboarding with Google Maps location pin | Backend | 🟡 | `UserRole.needsLocation`; plan Phase 3 |
| Send order to a workshop; production tracker (Cut → Assembled → Glazed → Ready) | Backend + UI | 🟡 | `FramingOrder`, `OrderStage`, `OrderRepository` |
| Unified frame catalogue data: search & filters by material, width, rebate, price | Engine + Backend | ⬜ | Mouldings need a code, vendor, rebate depth and price per metre; currently the built-in finishes. |
| Vendors upload their own mouldings | Engine + Backend | 🟡 | `tools/make_moulding_strip.py` does it offline; needs an in-app version. |
| Quote / pricing from moulding length, mat and glass area | Engine | 🟡 | `FrameDesign.mouldingLengthMm` exists. Needs prices. |
| Glazing options (UV-protective, non-glare) and archival mat flags | Engine | ⬜ | Add to `FrameDesign`; show glass reflection in the renderer. |
| In-room preview: photo scenes; a photo of the user's own wall with a scale reference | Engine | ⬜ | Drawn scenes are done. |
| Virtual gallery wall extras: apply a preset to all, bulk cost | Engine + UI | ⬜ | |
| Gallery budgets and bulk discounts | Backend | ⬜ | |
| Pexels sample artworks to try without uploading | Engine | ⬜ | Proposal 3.3.3 |
| Support chat / feedback button | UI | ⬜ | |
| Apple sign-in | Backend | ⬜ | Needs an Apple Developer account. |
| In-app payment | — | ⬜ | Out of scope per proposal 2.2 (invoiced manually). |
