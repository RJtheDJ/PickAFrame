import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/draft.dart';
import '../../models/units.dart';
import '../../rendering/lighting.dart';
import '../../view_models/exhibit_viewmodel.dart';
import '../frame_renderer.dart';

/// A saved draft drawn as its framed artwork, with title and size. Shows a
/// pick mark when [selected] is not null.
class DraftCard extends StatelessWidget {
  const DraftCard({
    super.key,
    required this.viewModel,
    required this.draft,
    required this.onTap,
    this.selected,
  });

  final ExhibitViewModel viewModel;
  final Draft draft;
  final VoidCallback onTap;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final selected = this.selected ?? false;
    final piece = viewModel.pieceFor(draft);
    return Semantics(
      selected: this.selected,
      button: true,
      label: draft.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppPalette.obsidianBlack : AppPalette.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FrameRenderer(
                        design: draft.design,
                        light: const Light(),
                        finishImages: piece.finishImages,
                        shaderResources: viewModel.shaderResources,
                        artworkImage: piece.artwork,
                        wallColor: AppPalette.surfaceLight,
                      ),
                    ),
                    if (this.selected != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                          color: selected ? AppPalette.obsidianBlack : AppPalette.borderMedium,
                        ),
                      ),
                    if (viewModel.artworkFailed(draft.id))
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text("Image didn't load · Retry"),
                          onPressed: () => viewModel.retryArtwork(draft),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                draft.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.obsidianBlack,
                ),
              ),
              Text(
                formatSize(draft.design.outerMm),
                style: const TextStyle(fontSize: 12, color: AppPalette.mutedZinc),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
