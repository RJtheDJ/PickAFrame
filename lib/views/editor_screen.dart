import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_dependencies.dart';
import '../models/artwork.dart';
import '../models/catalog_moulding.dart';
import '../models/design_summary.dart';
import '../models/draft.dart';
import '../models/ids.dart';
import '../models/perspective.dart';
import '../models/units.dart';
import '../services/artwork_service.dart';
import '../services/document_scanner_service.dart';
import '../services/draft_save_service.dart';
import '../view_models/editor_viewmodel.dart';
import '../widgets/editor/frame_panel.dart';
import '../widgets/editor/mat_panel.dart';
import '../widgets/export_button.dart';
import '../widgets/frame_renderer.dart';
import '../widgets/workspace_layout.dart';
import 'artwork_crop_screen.dart';
import 'exhibit_screen.dart';

/// The core visualizer styled in the Light Architectural Studio theme (Image 1)
/// with a pinned top preview stage + tabbed bottom control deck (`Frame` | `Mat`)
/// so the live frame and mat border remain visible at all times while editing.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.catalogMoulding});

  /// A shop's moulding to start with (catalogue card's "+").
  final CatalogMoulding? catalogMoulding;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorViewModel viewModel = EditorViewModel();
  final _exportKey = GlobalKey();

  /// One id per editing session, so saving again updates the same draft.
  String? _draftId;
  String _draftTitle = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.catalogMoulding case final moulding?) viewModel.applyCatalogMoulding(moulding);
  }

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

  /// Saves the framed artwork as a draft: the artwork image to the Worker,
  /// then the design to Firestore.
  Future<void> _save() async {
    final deps = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final user = deps.auth.currentUser;
    final artwork = viewModel.artwork;
    if (user == null || user.role == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Sign in to save drafts.')));
      return;
    }
    if (artwork == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Add an artwork before saving.')));
      return;
    }
    final title = await _askTitle();
    if (title == null || !mounted) return;

    setState(() => _saving = true);
    _draftId ??= newId('d');
    try {
      final draft = await DraftSaveService(drafts: deps.drafts, storage: deps.artworkStorage).saveDraft(
        draft: Draft(
          id: _draftId!,
          ownerUid: user.uid,
          title: title,
          design: viewModel.design,
          updatedAt: DateTime.now(),
        ),
        artworkPng: await encodeArtworkPng(artwork.image),
      );
      _draftTitle = title;
      messenger.showSnackBar(SnackBar(
        content: Text('Saved "${draft.title}"'),
        action: SnackBarAction(
          label: 'View in Exhibit',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ExhibitScreen(initialSelection: {draft.id}),
          )),
        ),
      ));
    } catch (e) {
      debugPrint('Save failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text("Couldn't save: $e"),
        action: SnackBarAction(label: 'Retry', onPressed: _save),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _askTitle() => showDialog<String>(
        context: context,
        builder: (_) => _DraftTitleDialog(initialTitle: _draftTitle),
      );

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
        final outerWidthMm = design.outerMm.width.round();
        final outerHeightMm = design.outerMm.height.round();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Visualizer',
              style: TextStyle(
                color: Color(0xFF090A0C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF090A0C),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
                tooltip: 'Save draft',
                onPressed: _saving ? null : _save,
              ),
              ExportButton(
                boundaryKey: _exportKey,
                message: () => 'Framed with PickAFrame\n${designSummaryText(viewModel.design)}',
              ),
              if (viewModel.artwork case final artwork?)
                IconButton(
                  icon: const Icon(Icons.crop, size: 20),
                  onPressed: () => _adjustCrop(artwork),
                  tooltip: 'Adjust crop',
                ),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 21),
                onPressed: _addArtwork,
                tooltip: 'Upload Artwork',
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090A0C),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_saving)
                          const SizedBox.square(
                            dimension: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.save_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: viewModel.isLoadingTexture
                  ? const LinearProgressIndicator(
                      minHeight: 2,
                      color: Color(0xFF090A0C),
                      backgroundColor: Color(0xFFEEF2F7),
                    )
                  : const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            ),
          ),
          body: WorkspaceLayout(
            controlsHeight: 350,
            // 1. PINNED TOP PREVIEW STAGE (Always visible while adjusting Frame or Mat!)
            preview: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Top horizontal ruler: |-- [ outer W mm ] --|
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          const Text(
                            '⊢',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE4EE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'outer $outerWidthMm mm',
                              style: const TextStyle(
                                color: Color(0xFF090A0C),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                          ),
                          const Text(
                            '⊣',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Left vertical ruler + Live FrameRenderer
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '⊤',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                ),
                                const SizedBox(height: 4),
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCE4EE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$outerHeightMm mm',
                                      style: const TextStyle(
                                        color: Color(0xFF090A0C),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '⊥',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: viewModel.artwork == null ? _addArtwork : null,
                              child: FrameRenderer(
                                design: design,
                                light: viewModel.light,
                                finishImages: viewModel.finishImages,
                                shaderResources: viewModel.shaderResources,
                                artworkImage: viewModel.artwork?.image,
                                wallColor: Colors.white,
                                exportKey: _exportKey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom dimensions & active moulding readout pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Artwork ${formatSize(design.artworkMm)}  ·  Overall ${formatSize(design.outerMm)}'
                        '${switch (viewModel.catalogMoulding) {
                          final m? => '  ·  ${m.name} (RM ${m.priceFor(design).toStringAsFixed(2)})',
                          null => '',
                        }}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF090A0C),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. BOTTOM ARCHITECTURAL TABBED CONTROL DECK (Frame | Mat)
            controls: Material(
              color: Colors.white,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SafeArea(
                  top: false,
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: const Color(0xFF090A0C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: const Color(0xFF4B5563),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                            tabs: const [
                              Tab(text: 'Frame & Finish'),
                              Tab(text: 'Precision Matting'),
                            ],
                          ),
                        ),
                        Expanded(
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
          ),
        );
      },
    );
  }
}

enum _ArtworkSource { scan, gallery, camera }

/// Asks for the draft's title. Owns its text controller so it is only
/// disposed once the dialog has finished closing; disposing it as soon as
/// showDialog returns breaks the still-animating TextField.
class _DraftTitleDialog extends StatefulWidget {
  const _DraftTitleDialog({this.initialTitle});

  final String? initialTitle;

  @override
  State<_DraftTitleDialog> createState() => _DraftTitleDialogState();
}

class _DraftTitleDialogState extends State<_DraftTitleDialog> {
  late final _controller = TextEditingController(text: widget.initialTitle);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) Navigator.pop(context, title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save draft'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Sunset study'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
