import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/artwork.dart';
import '../models/perspective.dart';
import '../models/units.dart';
import '../services/artwork_service.dart';
import '../services/document_scanner_service.dart';
import '../view_models/editor_viewmodel.dart';
import '../widgets/editor/frame_panel.dart';
import '../widgets/editor/mat_panel.dart';
import '../widgets/frame_renderer.dart';
import 'artwork_crop_screen.dart';

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

  /// Adds the user's artwork: scanned with automatic edge detection where
  /// available, or picked from the gallery/camera and cropped by hand.
  Future<void> _addArtwork() async {
    final choice = await showModalBottomSheet<_ArtworkSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isArtworkScannerAvailable)
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Scan artwork'),
                subtitle: const Text('Finds the edges automatically'),
                onTap: () => Navigator.pop(context, _ArtworkSource.scan),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, _ArtworkSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, _ArtworkSource.camera),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    try {
      if (choice == _ArtworkSource.scan) {
        final scanned = await scanArtwork();
        if (scanned == null) return;
        // Already cropped and straightened; "Adjust crop" can still trim it.
        viewModel.setArtwork(Artwork(
          image: scanned,
          source: scanned,
          corners: Quad.full(Size(scanned.width.toDouble(), scanned.height.toDouble())),
        ));
        return;
      }

      final photo = await pickArtworkPhoto(
        choice == _ArtworkSource.camera ? ImageSource.camera : ImageSource.gallery,
      );
      if (photo == null || !mounted) return;
      final artwork = await Navigator.of(context).push<Artwork>(
        MaterialPageRoute(builder: (_) => ArtworkCropScreen(source: photo)),
      );
      if (artwork != null) viewModel.setArtwork(artwork);
    } catch (e) {
      debugPrint('Error adding artwork: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't load that artwork. Please try again.")),
        );
      }
    }
  }

  /// Reopens the crop on the current artwork's original photo.
  Future<void> _adjustCrop(Artwork current) async {
    final artwork = await Navigator.of(context).push<Artwork>(
      MaterialPageRoute(
        builder: (_) => ArtworkCropScreen(source: current.source, initialCorners: current.corners),
      ),
    );
    if (artwork != null) viewModel.setArtwork(artwork);
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
              if (viewModel.artwork case final artwork?)
                IconButton(
                  icon: const Icon(Icons.crop),
                  onPressed: () => _adjustCrop(artwork),
                  tooltip: 'Adjust crop',
                ),
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _addArtwork,
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
                    light: viewModel.light,
                    finishImages: viewModel.finishImages,
                    shaderResources: viewModel.shaderResources,
                    artworkImage: viewModel.artwork?.image,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Artwork ${formatSize(design.artworkMm)}  ·  Overall ${formatSize(design.outerMm)}',
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
}

enum _ArtworkSource { scan, gallery, camera }
