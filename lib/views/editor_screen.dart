import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_dependencies.dart';
import '../models/artwork.dart';
import '../models/design_summary.dart';
import '../models/draft.dart';
import '../models/order.dart';
import '../models/perspective.dart';
import '../models/units.dart';
import '../models/user_profile.dart';
import '../models/vendor.dart';
import '../services/artwork_service.dart';
import '../services/document_scanner_service.dart';
import '../services/export_service.dart';
import '../view_models/editor_viewmodel.dart';
import '../view_models/room_preview_viewmodel.dart';
import '../widgets/editor/frame_panel.dart';
import '../widgets/editor/mat_panel.dart';
import '../widgets/frame_renderer.dart';
import '../widgets/preview/room_panel.dart';
import '../widgets/room_preview.dart';
import 'artwork_crop_screen.dart';

/// The core visualizer: frame preview on top, tabbed controls below. The
/// Edit | Preview toggle switches to hanging the framed artwork in a room.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorViewModel viewModel = EditorViewModel();
  final RoomPreviewViewModel room = RoomPreviewViewModel();
  final _exportKey = GlobalKey();
  bool _exporting = false;
  _ViewMode _mode = _ViewMode.edit;

  @override
  void dispose() {
    viewModel.dispose();
    room.dispose();
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

  /// Renders the framed artwork at high resolution, then saves or shares it.
  Future<void> _export(Rect shareOrigin) async {
    final action = await showModalBottomSheet<_ExportAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canSaveToGallery)
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Save to gallery'),
                onTap: () => Navigator.pop(context, _ExportAction.save),
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              subtitle: const Text('Includes the frame and mat details'),
              onTap: () => Navigator.pop(context, _ExportAction.share),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final png = await renderPng(_exportKey);
      switch (action) {
        case _ExportAction.save:
          await saveToGallery(png);
          messenger.showSnackBar(const SnackBar(content: Text('Saved to your gallery')));
        case _ExportAction.share:
          await sharePng(
            png,
            message: 'Framed with PickAFrame\n${designSummaryText(viewModel.design)}'
                '${_mode == _ViewMode.preview ? '\nShown in: ${room.scene.name}' : ''}',
            origin: shareOrigin,
          );
      }
    } on GalleryPermissionDenied {
      messenger.showSnackBar(
        const SnackBar(content: Text('Allow access to Photos in Settings to save mock-ups')),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(const SnackBar(content: Text('Export failed. Please try again.')));
    } finally {
      if (mounted) setState(() => _exporting = false);
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

  /// Shows an interactive test panel to verify Firebase operations.
  Future<void> _showFirebaseTestDialog() async {
    final dependencies = AppScope.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String statusText = 'Select an operation to test live Firebase connectivity:';
        bool isBusy = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Firebase Diagnostics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                      if (isBusy) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('1. Test Save Draft'),
                        onPressed: isBusy
                            ? null
                            : () async {
                                setDialogState(() {
                                  isBusy = true;
                                  statusText = 'Saving current frame design to Firestore drafts...';
                                });
                                try {
                                  final currentUid = dependencies.auth.currentUser?.uid ?? 'guest_test_uid';
                                  final draft = Draft(
                                    id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
                                    ownerUid: currentUid,
                                    title: 'Custom Frame #${DateTime.now().second}',
                                    design: viewModel.design,
                                    updatedAt: DateTime.now(),
                                  );
                                  await dependencies.drafts.saveDraft(draft);
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✓ Draft saved to Firestore drafts collection!\n\n'
                                        '• Draft ID: ${draft.id}\n'
                                        '• Title: ${draft.title}\n'
                                        '• Moulding width: ${draft.design.moulding.faceWidthMm}mm\n\n'
                                        'Check Firebase Console > Firestore > drafts';
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✗ Error saving draft:\n$e';
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('2. Test Submit Order'),
                        onPressed: isBusy
                            ? null
                            : () async {
                                setDialogState(() {
                                  isBusy = true;
                                  statusText = 'Submitting test order to Firestore orders...';
                                });
                                try {
                                  final currentUid = dependencies.auth.currentUser?.uid ?? 'guest_test_uid';
                                  final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
                                  final order = FramingOrder(
                                    id: orderId,
                                    draftId: 'draft_${DateTime.now().millisecondsSinceEpoch}',
                                    customerUid: currentUid,
                                    vendorId: 'vendor_kl_01',
                                    specLines: describeDesign(viewModel.design),
                                    createdAt: DateTime.now(),
                                    stage: OrderStage.submitted,
                                    quoteRm: 180.0,
                                  );
                                  await dependencies.orders.submitOrder(order);
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✓ Order submitted to Firestore orders collection!\n\n'
                                        '• Order ID: ${order.id}\n'
                                        '• Stage: ${order.stage.label}\n'
                                        '• Quote: RM ${order.quoteRm}\n\n'
                                        'Check Firebase Console > Firestore > orders';
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✗ Error submitting order:\n$e';
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('3. Test Save Vendor'),
                        onPressed: isBusy
                            ? null
                            : () async {
                                setDialogState(() {
                                  isBusy = true;
                                  statusText = 'Creating sample vendor in Firestore vendors...';
                                });
                                try {
                                  final vendorId = 'vendor_${DateTime.now().millisecondsSinceEpoch}';
                                  final vendor = Vendor(
                                    id: vendorId,
                                    ownerUid: dependencies.auth.currentUser?.uid ?? 'vendor_owner_test',
                                    name: 'Artisan Custom Framing KL',
                                    address: 'Jalan Bukit Bintang, Kuala Lumpur',
                                    latitude: 3.1466,
                                    longitude: 101.7118,
                                    phone: '+60 12-345 6789',
                                    specialties: ['Gilding', 'Museum glazing', 'Shadow boxes'],
                                    acceptsBulkOrders: true,
                                  );
                                  await dependencies.vendors.saveVendor(vendor);
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✓ Vendor saved to Firestore vendors collection!\n\n'
                                        '• Vendor ID: ${vendor.id}\n'
                                        '• Name: ${vendor.name}\n'
                                        '• Location: KL (${vendor.latitude}, ${vendor.longitude})\n\n'
                                        'Check Firebase Console > Firestore > vendors';
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✗ Error saving vendor:\n$e';
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Test Auth Sign-Up (Optional)'),
                        onPressed: isBusy
                            ? null
                            : () async {
                                setDialogState(() {
                                  isBusy = true;
                                  statusText = 'Registering test user in Firebase Auth & Firestore users...';
                                });
                                try {
                                  final email = 'test_${DateTime.now().millisecondsSinceEpoch}@pickaframe.com';
                                  final profile = await dependencies.auth.registerWithEmail(
                                    email: email,
                                    password: 'Password123!',
                                    displayName: 'Test Artist',
                                  );
                                  await dependencies.auth.setRole(UserRole.artist);
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✓ Auth & users collection verified!\n\n'
                                        '• Email: $email\n'
                                        '• UID: ${profile.uid}\n'
                                        '• Role: artist\n\n'
                                        'Check Firebase Console > Authentication & Firestore > users';
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isBusy = false;
                                    statusText = '✗ Auth error:\n$e';
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, room]),
      builder: (context, child) {
        final design = viewModel.design;
        final previewing = _mode == _ViewMode.preview;

        return Scaffold(
          backgroundColor: Colors.blueGrey[900],
          appBar: AppBar(
            titleSpacing: 12,
            title: SegmentedButton<_ViewMode>(
              segments: const [
                ButtonSegment(value: _ViewMode.edit, label: Text('Edit'), icon: Icon(Icons.tune)),
                ButtonSegment(
                  value: _ViewMode.preview,
                  label: Text('Preview'),
                  icon: Icon(Icons.chair_outlined),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() => _mode = selection.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.white70,
                selectedForegroundColor: Colors.black,
                selectedBackgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.cloud_sync, color: Colors.amberAccent),
                tooltip: 'Firebase Diagnostics',
                onPressed: _showFirebaseTestDialog,
              ),
              Builder(
                builder: (buttonContext) => IconButton(
                  icon: _exporting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.ios_share),
                  tooltip: 'Export',
                  onPressed: _exporting
                      ? null
                      : () {
                          final box = buttonContext.findRenderObject()! as RenderBox;
                          _export(box.localToGlobal(Offset.zero) & box.size);
                        },
                ),
              ),
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
                child: previewing
                    ? RoomPreview(
                        room: room,
                        design: design,
                        light: viewModel.light,
                        finishImages: viewModel.finishImages,
                        shaderResources: viewModel.shaderResources,
                        artworkImage: viewModel.artwork?.image,
                        exportKey: _exportKey,
                      )
                    : FrameRenderer(
                        design: design,
                        light: viewModel.light,
                        finishImages: viewModel.finishImages,
                        shaderResources: viewModel.shaderResources,
                        artworkImage: viewModel.artwork?.image,
                        wallColor: Colors.blueGrey[900]!,
                        exportKey: _exportKey,
                      ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 8, top: previewing ? 8 : 0),
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
                    child: previewing
                        ? SizedBox(
                            // Same height as the editor's tabs, so the view
                            // doesn't jump when switching.
                            height: 338,
                            child: RoomPanel(room: room, editor: viewModel),
                          )
                        : DefaultTabController(
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

enum _ExportAction { save, share }

enum _ViewMode { edit, preview }
