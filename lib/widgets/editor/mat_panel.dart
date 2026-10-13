import 'package:flutter/material.dart';

import '../../data/mat_catalog.dart';
import '../../models/mat_spec.dart';
import '../../view_models/editor_viewmodel.dart';
import 'color_swatch_row.dart';
import 'labeled_slider.dart';

/// Precision Matting Engine controls: mount style, presets, per-side
/// borders and mat colours.
class MatPanel extends StatelessWidget {
  const MatPanel({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  static const _maxBorderMm = 300.0;

  @override
  Widget build(BuildContext context) {
    final mat = viewModel.design.mat;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        SegmentedButton<MountStyle>(
          segments: [
            for (final style in MountStyle.values)
              ButtonSegment(value: style, label: Text(style.label)),
          ],
          selected: {mat.style},
          onSelectionChanged: (selection) => viewModel.setMountStyle(selection.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Golden ratio'),
              onPressed: viewModel.applyGoldenRatioMat,
            ),
            ActionChip(
              label: const Text('3:1 rule'),
              onPressed: viewModel.applyThreeToOneMat,
            ),
            ActionChip(
              label: const Text('Bottom-weighted'),
              onPressed: viewModel.applyBottomWeightedMat,
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Same border on all sides'),
          value: viewModel.matLinked,
          onChanged: viewModel.setMatLinked,
        ),
        if (viewModel.matLinked)
          LengthSlider(
            label: 'All sides',
            valueMm: mat.topMm,
            minMm: 0,
            maxMm: _maxBorderMm,
            onChanged: (mm) => viewModel.setMatSideMm(MatSide.top, mm),
          )
        else
          for (final side in MatSide.values)
            LengthSlider(
              label: _sideLabel(side),
              valueMm: mat.side(side),
              minMm: 0,
              maxMm: _maxBorderMm,
              onChanged: (mm) => viewModel.setMatSideMm(side, mm),
            ),
        if (mat.style == MountStyle.doubleMat)
          LengthSlider(
            label: 'Reveal',
            valueMm: mat.revealMm,
            minMm: 2,
            maxMm: 20,
            onChanged: viewModel.setRevealMm,
          ),
        const SizedBox(height: 8),
        ColorSwatchRow(
          label: mat.style == MountStyle.float ? 'Backing' : 'Board',
          colors: matBoardColors,
          selected: mat.color,
          onSelected: viewModel.setMatColor,
        ),
        if (mat.style == MountStyle.doubleMat)
          ColorSwatchRow(
            label: 'Inner mat',
            colors: matBoardColors,
            selected: mat.innerColor,
            onSelected: viewModel.setInnerMatColor,
          ),
        if (mat.style != MountStyle.float)
          ColorSwatchRow(
            label: 'Core',
            colors: matCoreColors,
            selected: mat.coreColor,
            onSelected: viewModel.setMatCoreColor,
          ),
      ],
    );
  }

  static String _sideLabel(MatSide side) => switch (side) {
        MatSide.top => 'Top',
        MatSide.bottom => 'Bottom',
        MatSide.left => 'Left',
        MatSide.right => 'Right',
      };
}
