import 'dart:ui';

/// What the face of the moulding is covered with.
sealed class FrameFinish {
  const FrameFinish();
}

/// A solid painted finish.
class ColorFinish extends FrameFinish {
  const ColorFinish(this.color);

  final Color color;
}

/// A photographic material (wood grain, metal leaf) loaded from [url].
class TextureFinish extends FrameFinish {
  const TextureFinish(this.url);

  final String url;
}
