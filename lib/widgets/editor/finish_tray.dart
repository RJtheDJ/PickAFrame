import 'package:flutter/material.dart';

import '../../data/finish_catalog.dart';
import '../../view_models/editor_viewmodel.dart';

/// Row of round swatches: paint colours in colour mode, wood and metal
/// textures in texture mode.
class FinishTray extends StatelessWidget {
  const FinishTray({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.mode == FrameMode.color) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final color in paintColors)
            _Swatch(
              selected: viewModel.frameColor == color,
              color: color,
              onTap: () => viewModel.setColor(color),
            ),
        ],
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final id in woodTextureIds)
          _Swatch(
            selected: viewModel.textureUrl == polyHavenTextureUrl(id),
            image: NetworkImage(polyHavenThumbnailUrl(id)),
            onTap: () => viewModel.selectTexture(polyHavenTextureUrl(id)),
          ),
        for (final url in metalTextureUrls)
          _Swatch(
            selected: viewModel.textureUrl == url,
            image: NetworkImage(url),
            idleBorderColor: Colors.amber, // Marks the metal finishes
            onTap: () => viewModel.selectTexture(url),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.selected,
    required this.onTap,
    this.color,
    this.image,
    this.idleBorderColor = Colors.white38,
  });

  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final ImageProvider? image;
  final Color idleBorderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.blueAccent : idleBorderColor,
            width: selected ? 3 : 1,
          ),
          image: image == null
              ? null
              : DecorationImage(image: image!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
