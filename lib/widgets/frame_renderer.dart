import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame_design.dart';
import '../models/frame_finish.dart';
import '../models/mat_spec.dart';
import '../rendering/frame_layout.dart';
import '../rendering/frame_painter.dart';
import '../rendering/lighting.dart';
import '../rendering/mat_painter.dart';
import '../rendering/moulding_shading.dart';
import '../rendering/shaded_frame_painter.dart';
import '../services/texture_service.dart';

/// How far the frame stands off the wall, for its drop shadow.
const _frameDepthMm = 25.0;

/// How far a floated artwork stands off its backing board.
const _floatHeightMm = 4.0;

/// Draws a [FrameDesign] at true proportions, scaled to fit its parent.
class FrameRenderer extends StatelessWidget {
  const FrameRenderer({
    super.key,
    required this.design,
    required this.light,
    this.finishImages,
    this.shaderResources,
    this.artworkImage,
  });

  final FrameDesign design;
  final Light light;

  /// Decoded maps or moulding strip for wood, metal and ornate finishes.
  /// While null those finishes are drawn in a flat stand-in colour.
  final FinishImages? finishImages;

  /// The GPU frame shader. When null (still loading, or unsupported) the
  /// frame is drawn with the CPU gradient renderer instead.
  final FrameShaderResources? shaderResources;

  /// The cropped artwork, or null to show a placeholder.
  final ui.Image? artworkImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = FrameLayout.fit(design, constraints.biggest);
        final px = layout.pxPerMm;

        return Center(
          child: Container(
            width: layout.outerSize.width,
            height: layout.outerSize.height,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 12 * px,
                  offset: light.shadowOffset(_frameDepthMm * px * 0.5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _framePainter(layout)),
                ),
                Positioned.fromRect(
                  rect: layout.matRect,
                  child: ColoredBox(color: design.mat.color),
                ),
                Positioned.fromRect(
                  rect: layout.artworkRect,
                  child: DecoratedBox(
                    // A floated artwork stands off the board and casts a shadow.
                    decoration: BoxDecoration(
                      boxShadow: design.mat.style == MountStyle.float
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 3 * px,
                                offset: light.shadowOffset(_floatHeightMm * px),
                              ),
                            ]
                          : null,
                    ),
                    // The window has the artwork's real proportions. The photo
                    // normally matches them; after a measured size is entered
                    // it is stretched slightly to fit, which corrects for the
                    // angle it was taken at.
                    child: artworkImage != null
                        ? RawImage(
                            image: artworkImage,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.medium,
                          )
                        : const _ArtworkPlaceholder(),
                  ),
                ),
                // Bevels and shadows go over the mat and the artwork edges.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: MatPainter(
                        style: design.mat.style,
                        matRect: layout.matRect,
                        artworkRect: layout.artworkRect,
                        topMatWindow: layout.topMatWindow,
                        bevelWidth: layout.bevelWidth,
                        pxPerMm: px,
                        coreColor: design.mat.coreColor,
                        innerColor: design.mat.innerColor,
                        light: light,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shades the moulding on the GPU when possible, falling back to the CPU
  /// renderer while maps load or where shaders aren't supported.
  CustomPainter _framePainter(FrameLayout layout) {
    final resources = shaderResources;
    final shaderMaterial = _shaderMaterialFor(design.finish, finishImages);
    if (resources != null && shaderMaterial != null) {
      return ShadedFramePainter(
        resources: resources,
        faceWidth: layout.faceWidth,
        pxPerMm: layout.pxPerMm,
        profile: design.moulding.profile,
        material: shaderMaterial,
        light: light,
      );
    }

    final (skin, material) = _skinFor(design.finish, finishImages?.albedo);
    return FramePainter(
      faceWidth: layout.faceWidth,
      pxPerMm: layout.pxPerMm,
      profile: design.moulding.profile,
      skin: skin,
      material: material,
      light: light,
    );
  }

  static ShaderMaterial? _shaderMaterialFor(FrameFinish finish, FinishImages? images) {
    ShaderMaterial? textured(TextureSet textures, {required double metallic, Color? tint}) {
      final normal = images?.normal;
      final roughness = images?.roughness;
      if (images == null || normal == null || roughness == null) return null;
      return ShaderMaterial.textured(
        albedo: images.albedo,
        normal: normal,
        roughnessMap: roughness,
        sizeMm: textures.sizeMm,
        grainVertical: textures.grainVertical,
        metallic: metallic,
        tint: tint ?? const Color(0xFFFFFFFF),
      );
    }

    return switch (finish) {
      ColorFinish(:final color) => ShaderMaterial.paint(color),
      WoodFinish(:final textures) => textured(textures, metallic: 0),
      MetalFinish(:final textures, :final tint) => textured(textures, metallic: 1, tint: tint),
      PhotoMouldingFinish(:final mirrorTiling) => images?.normal == null
          ? null
          : ShaderMaterial.strip(
              albedo: images!.albedo,
              normal: images.normal!,
              mirror: mirrorTiling,
            ),
    };
  }

  static (RailSkin, SurfaceMaterial) _skinFor(FrameFinish finish, ui.Image? image) {
    return switch (finish) {
      ColorFinish(:final color) => (SolidSkin(color), SurfaceMaterial.paint),
      MetalFinish(:final color) => (SolidSkin(color), SurfaceMaterial.metal(color)),
      WoodFinish(:final textures) => (
          image != null
              ? TextureSkin(image, sizeMm: textures.sizeMm, grainVertical: textures.grainVertical)
              : const SolidSkin(Color(0xFF6D4C35)),
          SurfaceMaterial.wood,
        ),
      PhotoMouldingFinish(:final mirrorTiling) => (
          image != null
              ? StripSkin(image, mirror: mirrorTiling)
              : const SolidSkin(Color(0xFFA8842F)),
          SurfaceMaterial.metal(const Color(0xFFA8842F)),
        ),
    };
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF2C3E50),
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: Colors.white70, size: 48),
              SizedBox(height: 8),
              Text('Your artwork here', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
