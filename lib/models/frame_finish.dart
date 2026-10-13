import 'dart:ui';

/// The families of finish the editor offers.
enum FinishKind {
  paint('Paint'),
  wood('Wood'),
  metal('Metal'),
  ornate('Ornate');

  const FinishKind(this.label);

  final String label;
}

/// What the face of the moulding is covered with.
sealed class FrameFinish {
  const FrameFinish();

  FinishKind get kind;
  String get name;
}

/// A solid painted finish, shaded by the moulding profile.
class ColorFinish extends FrameFinish {
  const ColorFinish(this.color);

  final Color color;

  @override
  FinishKind get kind => FinishKind.paint;

  @override
  String get name => 'Paint #${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

/// A set of tileable PBR maps for one material, stored side by side:
/// `<base>.jpg` (colour), `<base>_nor.jpg` (OpenGL-style normal map) and
/// `<base>_rough.jpg` (roughness, white = rough).
class TextureSet {
  const TextureSet(this.basePath, {required this.sizeMm, this.grainVertical = false});

  final String basePath;

  /// Real-world width covered by the texture, so detail is true to scale.
  final double sizeMm;

  /// Whether the grain or brushing runs top-to-bottom in the image (it
  /// should run along the rail, so these are turned 90°).
  final bool grainVertical;

  String get albedo => '$basePath.jpg';
  String get normal => '${basePath}_nor.jpg';
  String get roughness => '${basePath}_rough.jpg';
}

/// A wood veneer wrapped along each rail, shaded by the profile.
class WoodFinish extends FrameFinish {
  const WoodFinish({required this.id, required this.name, required this.textures});

  final String id;

  @override
  final String name;

  final TextureSet textures;

  @override
  FinishKind get kind => FinishKind.wood;
}

/// A metal finish. Its colour map is the metal's reflectance, so it is lit
/// by reflections of the room rather than like paint.
class MetalFinish extends FrameFinish {
  const MetalFinish({
    required this.name,
    required this.color,
    required this.textures,
    this.tint = const Color(0xFFFFFFFF),
  });

  @override
  final String name;

  /// Typical look of the finish, for swatches and the fallback renderer.
  final Color color;

  final TextureSet textures;

  /// Multiplied into the colour map, to derive variants (antique, bronze...).
  final Color tint;

  @override
  FinishKind get kind => FinishKind.metal;
}

/// A photographed moulding (ornate gold, carved wood, ...). The strip image
/// already contains the profile's shape and lighting, so it is tiled along
/// each rail instead of being shaded procedurally.
///
/// Strip images have the outer edge on the top row and the inner (artwork
/// side) edge on the bottom row; see `tools/make_moulding_strip.py`.
class PhotoMouldingFinish extends FrameFinish {
  const PhotoMouldingFinish({
    required this.id,
    required this.name,
    required this.asset,
    required this.faceWidthMm,
    this.mirrorTiling = false,
  });

  final String id;

  @override
  final String name;

  final String asset;

  /// Normal map estimated from the strip's shading, written next to it by
  /// tools/make_moulding_strip.py; used to relight the carving.
  String get normalAsset => asset.replaceFirst(RegExp(r'\.jpg$'), '_nor.jpg');

  /// Face width of the real moulding; applied when this finish is chosen.
  final double faceWidthMm;

  /// Mirror alternate tiles instead of repeating them. Use for strips that
  /// were not cut to a whole number of ornament repeats.
  final bool mirrorTiling;

  @override
  FinishKind get kind => FinishKind.ornate;
}
