import 'package:flutter/material.dart';

import '../../models/frame_finish.dart';
import '../../models/units.dart';
import '../../view_models/editor_viewmodel.dart';
import 'artwork_size_dialog.dart';
import 'finish_tray.dart';
import 'labeled_slider.dart';
import 'profile_selector.dart';

/// Moulding controls styled in the Light Architectural Studio theme:
/// Finish strip, Light Angle quick presets, Mouldings Carousel & Profile,
/// and Artwork / Frame / Light calibration sliders.
class FramePanel extends StatelessWidget {
  const FramePanel({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  static const _lightPresets = <(String, double)>[
    ('TL', -45),
    ('Front', 0),
    ('TR', 45),
    ('Raking', 75),
  ];

  @override
  Widget build(BuildContext context) {
    final design = viewModel.design;
    final isPhotoMoulding = design.finish.kind == FinishKind.ornate;
    final currentAzimuth = viewModel.light.azimuthDeg;

    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      children: [
        // 1. FINISH STRIP (Image 1 style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              const Text(
                'FINISH:',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final kind in FinishKind.values)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _StripPill(
                            label: kind.label,
                            selected: design.finish.kind == kind,
                            onTap: () => viewModel.setFinishKind(kind),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 2. LIGHT ANGLE STRIP (Image 1 style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              const Text(
                'LIGHT ANGLE:',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (label, deg) in _lightPresets)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _StripPill(
                            label: label,
                            selected: (currentAzimuth - deg).abs() < 5,
                            onTap: () => viewModel.setLightAzimuth(deg),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. MOULDINGS CAROUSEL & PROFILE SECTION (Image 1 style)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Mouldings Carousel',
                    style: TextStyle(
                      color: Color(0xFF090A0C),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '(${design.finish.name})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      '${design.moulding.faceWidthMm.round()} mm',
                      style: const TextStyle(
                        color: Color(0xFF090A0C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(height: 62, child: FinishTray(viewModel: viewModel)),
              const SizedBox(height: 8),
              if (isPhotoMoulding)
                Text(
                  '${design.finish.name}: profile comes from the photographed moulding',
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                  ),
                )
              else
                ProfileSelector(
                  selected: design.moulding.profile,
                  onSelected: viewModel.setProfile,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. DIMENSIONS & LIGHTING CALIBRATION CARD (Fixed overflow!)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Dimensions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF090A0C),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () async {
                      final size = await showArtworkSizeDialog(context, design.artworkMm);
                      if (size != null) viewModel.setArtworkSizeMm(size);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE4EE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten, size: 14, color: Color(0xFF090A0C)),
                          const SizedBox(width: 4),
                          Text(
                            'Exact size: ${formatSize(design.artworkMm)}',
                            style: const TextStyle(
                              color: Color(0xFF090A0C),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              LengthSlider(
                label: 'Artwork',
                valueMm: design.artworkMm.width,
                minMm: 100,
                maxMm: 3000,
                stepMm: 10,
                onChanged: viewModel.setArtworkWidthMm,
              ),
              LengthSlider(
                label: 'Frame',
                valueMm: design.moulding.faceWidthMm,
                minMm: 10,
                maxMm: 120,
                activeColor: const Color(0xFF1E2229),
                onChanged: viewModel.setFrameWidthMm,
              ),
              LabeledSlider(
                label: 'Light',
                value: viewModel.light.azimuthDeg,
                min: -180,
                max: 180,
                format: (deg) => '${deg.round()}°',
                activeColor: const Color(0xFF2C3E50),
                onChanged: viewModel.setLightAzimuth,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StripPill extends StatelessWidget {
  const _StripPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF090A0C) : const Color(0xFFDCE4EE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF090A0C),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
