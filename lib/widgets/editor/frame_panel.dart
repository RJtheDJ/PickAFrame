import 'package:flutter/material.dart';

import '../../models/frame_finish.dart';
import '../../models/units.dart';
import '../../view_models/editor_viewmodel.dart';
import 'artwork_size_dialog.dart';
import 'finish_tray.dart';
import 'labeled_slider.dart';
import 'profile_selector.dart';

/// Moulding controls: finish, profile, sizes and lighting.
class FramePanel extends StatelessWidget {
  const FramePanel({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final design = viewModel.design;
    final isPhotoMoulding = design.finish.kind == FinishKind.ornate;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        SegmentedButton<FinishKind>(
          segments: [
            for (final kind in FinishKind.values)
              ButtonSegment(value: kind, label: Text(kind.label)),
          ],
          selected: {design.finish.kind},
          onSelectionChanged: (selection) => viewModel.setFinishKind(selection.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 8),
        SizedBox(height: 60, child: FinishTray(viewModel: viewModel)),
        const SizedBox(height: 8),
        // A photographed moulding brings its own profile.
        if (isPhotoMoulding)
          Text(
            '${design.finish.name}: profile comes from the photographed moulding',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          )
        else
          ProfileSelector(
            selected: design.moulding.profile,
            onSelected: viewModel.setProfile,
          ),
        const SizedBox(height: 8),
        LengthSlider(
          label: 'Artwork',
          valueMm: design.artworkMm.width,
          minMm: 100,
          maxMm: 3000,
          stepMm: 10,
          onChanged: viewModel.setArtworkWidthMm,
        ),
        // The slider keeps the photo's proportions; measured sizes go here.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.straighten, size: 18),
            label: Text('Exact size: ${formatSize(design.artworkMm)}'),
            onPressed: () async {
              final size = await showArtworkSizeDialog(context, design.artworkMm);
              if (size != null) viewModel.setArtworkSizeMm(size);
            },
          ),
        ),
        LengthSlider(
          label: 'Frame',
          valueMm: design.moulding.faceWidthMm,
          minMm: 10,
          maxMm: 120,
          activeColor: Colors.brown[400],
          onChanged: viewModel.setFrameWidthMm,
        ),
        LabeledSlider(
          label: 'Light',
          value: viewModel.light.azimuthDeg,
          min: -180,
          max: 180,
          format: (deg) => '${deg.round()}°',
          activeColor: Colors.amber[300],
          onChanged: viewModel.setLightAzimuth,
        ),
      ],
    );
  }
}
