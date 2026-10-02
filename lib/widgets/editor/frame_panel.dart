import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../../view_models/editor_viewmodel.dart';
import 'finish_tray.dart';
import 'mm_slider.dart';
import 'profile_selector.dart';

/// Moulding controls: profile, finish, and artwork/moulding sizes.
class FramePanel extends StatelessWidget {
  const FramePanel({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final design = viewModel.design;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Row(
          children: [
            Expanded(
              child: ProfileSelector(
                selected: design.moulding.profile,
                onSelected: viewModel.setProfile,
              ),
            ),
            IconButton(
              icon: Icon(
                viewModel.mode == FrameMode.texture
                    ? FluentIcons.paint_brush_24_regular
                    : FluentIcons.image_24_regular,
              ),
              tooltip: 'Toggle Color/Texture',
              onPressed: () => viewModel.setMode(
                viewModel.mode == FrameMode.texture ? FrameMode.color : FrameMode.texture,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(height: 60, child: FinishTray(viewModel: viewModel)),
        const SizedBox(height: 8),
        MmSlider(
          label: 'Artwork',
          value: design.artworkMm.width,
          min: 100,
          max: 1500,
          onChanged: viewModel.setArtworkWidthMm,
        ),
        MmSlider(
          label: 'Frame',
          value: design.moulding.faceWidthMm,
          min: 10,
          max: 120,
          activeColor: Colors.brown[400],
          onChanged: viewModel.setFrameWidthMm,
        ),
      ],
    );
  }
}
