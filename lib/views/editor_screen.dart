import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../view_models/editor_viewmodel.dart';
import '../widgets/editor/finish_tray.dart';
import '../widgets/editor/mm_slider.dart';
import '../widgets/editor/profile_selector.dart';
import '../widgets/frame_renderer.dart';

/// The core visualizer: frame preview on top, controls below.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorViewModel viewModel = EditorViewModel();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final design = viewModel.design;

        return Scaffold(
          backgroundColor: Colors.blueGrey[900],
          appBar: AppBar(
            title: const Text('Basic Framing Engine'),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: viewModel.pickArtwork,
                tooltip: 'Upload Artwork',
              ),
            ],
            bottom: viewModel.isLoadingTexture
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : null,
          ),
          body: Column(
            children: [
              // FRAME PREVIEW
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: FrameRenderer(
                    design: design,
                    frameColor: viewModel.frameColor,
                    frameTexture: viewModel.frameTexture,
                    artworkBytes: viewModel.artwork?.bytes,
                  ),
                ),
              ),
              // CONTROL PANEL
              Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: SafeArea(
                  top: false,
                  child: Column(
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
                            color: Colors.white,
                            tooltip: 'Toggle Color/Texture',
                            onPressed: () => viewModel.setMode(
                              viewModel.mode == FrameMode.texture
                                  ? FrameMode.color
                                  : FrameMode.texture,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      MmSlider(
                        label: 'Mat',
                        value: design.mat.topMm,
                        min: 0,
                        max: 150,
                        activeColor: const Color(0xFFF5F5F0),
                        onChanged: viewModel.setMatWidthMm,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Artwork ${_mm(design.artworkMm)}  ·  Overall ${_mm(design.outerMm)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(height: 60, child: FinishTray(viewModel: viewModel)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _mm(Size size) => '${size.width.round()} × ${size.height.round()} mm';
}
