import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame_profile.dart';
import 'frame_painter.dart';
import 'lighting.dart';
import 'moulding_shading.dart';

/// The compiled frame shader plus the small images every draw needs: a
/// profile lookup texture per [FrameProfile], and stand-in maps for finishes
/// without textures (plain paint).
class FrameShaderResources {
  FrameShaderResources._(this.program, this.white, this.flatNormal, this.profiles);

  final ui.FragmentProgram program;

  /// 1x1 white: a neutral colour or roughness map.
  final ui.Image white;

  /// 1x1 normal map pointing straight out (no surface detail).
  final ui.Image flatNormal;

  final Map<FrameProfile, ui.Image> profiles;

  /// Returns null if shaders aren't available here, in which case the frame
  /// falls back to the CPU gradient renderer.
  static Future<FrameShaderResources?> load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/frame_material.frag');
      final white = await _image(Uint8List.fromList([255, 255, 255, 255]), 1, 1);
      final flatNormal = await _image(Uint8List.fromList([128, 128, 255, 255]), 1, 1);
      final profiles = {
        for (final profile in FrameProfile.values)
          profile: await _image(profileLookupPixels(profile), 256, 1),
      };
      return FrameShaderResources._(program, white, flatNormal, profiles);
    } catch (e) {
      debugPrint('Frame shader unavailable, using fallback renderer: $e');
      return null;
    }
  }

  static Future<ui.Image> _image(Uint8List rgba, int width, int height) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return image;
  }
}

/// The material to shade the moulding with.
class ShaderMaterial {
  /// Plain paint: a colour, satin sheen, no surface detail.
  const ShaderMaterial.paint(Color color)
      : tint = color,
        albedo = null,
        normal = null,
        roughnessMap = null,
        sizeMm = 1,
        grainVertical = false,
        metallic = 0,
        roughness = 0.55,
        isStrip = false,
        mirror = false;

  /// A textured material (wood, metal) with colour, normal and roughness maps.
  const ShaderMaterial.textured({
    required ui.Image this.albedo,
    required ui.Image this.normal,
    required ui.Image this.roughnessMap,
    required this.sizeMm,
    required this.grainVertical,
    required this.metallic,
    this.tint = const Color(0xFFFFFFFF),
  })  : roughness = 1,
        isStrip = false,
        mirror = false;

  /// A photographed moulding strip, relit using a normal map estimated from
  /// its shading (see tools/make_moulding_strip.py).
  const ShaderMaterial.strip({
    required ui.Image this.albedo,
    required ui.Image this.normal,
    required this.mirror,
  })  : tint = const Color(0xFFFFFFFF),
        roughnessMap = null,
        sizeMm = 1,
        grainVertical = false,
        metallic = 0,
        roughness = 1,
        isStrip = true;

  final Color tint;
  final ui.Image? albedo;
  final ui.Image? normal;
  final ui.Image? roughnessMap;
  final double sizeMm;
  final bool grainVertical;
  final double metallic;

  /// Multiplies the roughness map (or is the roughness, without a map).
  final double roughness;

  /// Whether [albedo] is a moulding strip spanning the face (outer edge on
  /// top), rather than a material texture of [sizeMm].
  final bool isStrip;

  /// For strips: mirror alternate tiles instead of repeating them.
  final bool mirror;

  @override
  bool operator ==(Object other) =>
      other is ShaderMaterial &&
      other.tint == tint &&
      other.albedo == albedo &&
      other.normal == normal &&
      other.roughnessMap == roughnessMap &&
      other.sizeMm == sizeMm &&
      other.grainVertical == grainVertical &&
      other.metallic == metallic &&
      other.roughness == roughness &&
      other.isStrip == isStrip &&
      other.mirror == mirror;

  @override
  int get hashCode => Object.hash(
      tint, albedo, normal, roughnessMap, sizeMm, grainVertical, metallic, roughness, isStrip, mirror);
}

/// Paints the frame's four rails with the GPU shader (per-pixel lighting with
/// normal maps). Same geometry and conventions as [FramePainter].
class ShadedFramePainter extends CustomPainter {
  ShadedFramePainter({
    required this.resources,
    required this.faceWidth,
    required this.pxPerMm,
    required this.profile,
    required this.material,
    required this.light,
  });

  final FrameShaderResources resources;
  final double faceWidth;
  final double pxPerMm;
  final FrameProfile profile;
  final ShaderMaterial material;
  final Light light;

  @override
  void paint(Canvas canvas, Size size) {
    final albedo = material.albedo ?? resources.white;
    final shader = resources.program.fragmentShader();

    var i = 0;
    void set(double value) => shader.setFloat(i++, value);

    set(size.width);
    set(size.height);
    set(faceWidth);
    set(pxPerMm);
    set(light.x);
    set(light.y);
    set(light.z);
    set(material.tint.r);
    set(material.tint.g);
    set(material.tint.b);
    set(albedo.width.toDouble());
    set(albedo.height.toDouble());
    // Screen pixels per image pixel: a strip's height spans the face; a
    // material texture covers its real-world size.
    set(material.isStrip ? faceWidth / albedo.height : material.sizeMm * pxPerMm / albedo.width);
    set(material.grainVertical ? 1.5707963 : 0);
    set(material.metallic);
    set(material.roughness);
    set(material.normal == null ? 0 : 1);
    set(material.isStrip ? 1 : 0);
    set(material.mirror ? 1 : 0);

    shader
      ..setImageSampler(0, albedo)
      ..setImageSampler(1, material.normal ?? resources.flatNormal)
      ..setImageSampler(2, material.roughnessMap ?? resources.white)
      ..setImageSampler(3, resources.profiles[profile]!);

    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(Rect.fromLTRB(faceWidth, faceWidth, size.width - faceWidth, size.height - faceWidth));
    canvas.drawPath(ring, Paint()..shader = shader);

    paintFrameJoins(canvas, size, faceWidth);
  }

  @override
  bool shouldRepaint(covariant ShadedFramePainter oldDelegate) =>
      faceWidth != oldDelegate.faceWidth ||
      pxPerMm != oldDelegate.pxPerMm ||
      profile != oldDelegate.profile ||
      material != oldDelegate.material ||
      light != oldDelegate.light ||
      resources != oldDelegate.resources;
}
