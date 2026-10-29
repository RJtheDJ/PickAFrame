# PickAFrame

A Flutter app for visualising custom picture framing: photograph or scan an
artwork, choose a moulding (paint, wood, metal or ornate), set up precision
matting in real measurements, and export a realistic mock-up. Built for
artists, galleries and framing workshops in Kuala Lumpur.

## Run

```bash
flutter pub get
flutter run
```

The ML Kit document scanner needs a real Android phone with Google Play
services; everywhere else, artworks are cropped by hand.

## Test

```bash
flutter test
```

## Docs

- [Architecture](docs/ARCHITECTURE.md): how the code is organised, and how
  Firebase, Cloudflare R2 and Google Maps plug in.
- [Roadmap](docs/ROADMAP.md): every planned feature, its owner and its status.
- [Plan: R2 storage and Exhibition View](docs/plans/r2-exhibition.md): the
  current task list for saving drafts and showing several on one wall.
- [Artwork Worker](cloudflare/artwork-worker/README.md): what to install and
  how to run the Cloudflare Worker locally.

## Asset credits

Wood textures: [Poly Haven](https://polyhaven.com) (CC0). Metal textures:
[ambientCG](https://ambientcg.com) (CC0). The ornate moulding strip in
`assets/mouldings/` is for development only and must be replaced with
licensed vendor photos before release.
