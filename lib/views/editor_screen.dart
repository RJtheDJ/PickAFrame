import 'package:flutter/material.dart';

import '../view_models/editor_viewmodel.dart';
import '../widgets/editor/frame_panel.dart';
import '../widgets/editor/mat_panel.dart';
import '../widgets/frame_renderer.dart';

/// The core visualizer: frame preview on top, tabbed controls below.
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
                  padding: const EdgeInsets.all(24.0),
                  child: FrameRenderer(
                    design: design,
                    frameColor: viewModel.frameColor,
                    frameTexture: viewModel.frameTexture,
                    artworkBytes: viewModel.artwork?.bytes,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Artwork ${_mm(design.artworkMm)}  ·  Overall ${_mm(design.outerMm)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              // CONTROL PANEL
              Theme(
                data: ThemeData(brightness: Brightness.dark, useMaterial3: true),
                child: Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SafeArea(
                    top: false,
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(tabs: [Tab(text: 'Frame'), Tab(text: 'Mat')]),
                          SizedBox(
                            height: 290,
                            child: TabBarView(
                              children: [
                                FramePanel(viewModel: viewModel),
                                MatPanel(viewModel: viewModel),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
