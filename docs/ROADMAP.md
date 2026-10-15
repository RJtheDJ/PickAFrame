# PickAFrame roadmap

Every feature from the BASE APP FUNCTION doc and the proposal (section 3.1),
with where it stands. Areas: **Engine** = visualizer, matting, export, specs;
**Backend** = Firebase, Google Maps, data; **UI** = app shell, navigation,
styling.

Legend: ✅ done · 🟡 groundwork in place · ⬜ not started

## MVP (done)

| Feature | Status | Notes |
|---|---|---|
| Upload artwork from gallery / camera | ✅ | `ArtworkCropScreen` |
| 4-corner perspective crop, rotate, re-crop | ✅ | `models/perspective.dart` |
| ML Kit document scanner (auto edge detection) | ✅ | Android only |
| Exact artwork size (W × H in cm) | ✅ | |
| 8 moulding profiles, paint / wood / metal / ornate finishes | ✅ | |
| Texture & lighting control (light angle slider) | ✅ | GPU shader + normal maps |
| Precision matting: 4 independent borders, golden ratio, 3:1, bottom-weighted | ✅ | |
| Mount styles: flat, double, float; board + core colours | ✅ | |
| Export: save to gallery / share with design details | ✅ | 3000 px PNG |

## Next: suggested before the demo

The proposal's Gantt chart has testing until 19 Oct and demo & documentation
on 20–27 Oct, so keep this list short.

| # | Feature | Area | Status | What's needed |
|---|---|---|---|---|
| 1 | Sign up / log in (email, Google) + role selection | Backend + UI | 🟡 | `AuthRepository`, `UserProfile`, `UserRole` exist. Implement with Firebase Auth. |
| 2 | Save & reopen drafts | Engine + Backend | 🟡 | `Draft` + codec + `DraftRepository` exist. Add "Save" in the editor, a Drafts grid, artwork upload to Storage. |
| 3 | Order specification sheet | Engine | 🟡 | `describeDesign` gives the lines. Add rebate/glass/backing cut sizes and a PDF or image export. |
| 4 | App shell: bottom navigation, role-based start screen | UI | ⬜ | See ARCHITECTURE.md, "Planned screens". |
| 5 | Workshop directory on a map | Backend | 🟡 | `Vendor` + `VendorRepository` exist. Add `google_maps_flutter` and a few real KL workshops. |

## Later

| Feature | Area | Status | Notes |
|---|---|---|---|
| Vendor onboarding with Google Maps location pin | Backend | 🟡 | `UserRole.needsLocation` |
| Send order to a workshop; production tracker (Cut → Assembled → Glazed → Ready) | Backend + UI | 🟡 | `FramingOrder`, `OrderStage`, `OrderRepository` |
| Unified frame catalogue with search & filters (material, width, rebate, price) | Engine + Backend | ⬜ | Mouldings need a code, vendor, rebate depth and price per metre; currently the built-in finishes. |
| Vendors upload their own mouldings | Engine + Backend | 🟡 | `tools/make_moulding_strip.py` does it offline; needs an in-app version. |
| Quote / pricing from moulding length, mat and glass area | Engine | 🟡 | `FrameDesign.mouldingLengthMm` exists. Needs prices. |
| Glazing options (UV-protective, non-glare) and archival mat flags | Engine | ⬜ | Add to `FrameDesign`; show glass reflection in the renderer. |
| In-room preview: environment backgrounds, scale against furniture | Engine | ⬜ | `FrameRenderer` already draws at true mm scale. |
| Virtual gallery wall: several framed pieces, apply a preset to all, bulk cost | Engine + UI | ⬜ | |
| Gallery budgets and bulk discounts | Backend | ⬜ | |
| Pexels sample artworks to try without uploading | Engine | ⬜ | Proposal 3.3.3 |
| Support chat / feedback button | UI | ⬜ | |
| Apple sign-in | Backend | ⬜ | Needs an Apple Developer account. |
| In-app payment | — | ⬜ | Out of scope per proposal 2.2 (invoiced manually). |
