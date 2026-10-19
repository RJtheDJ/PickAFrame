import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_dependencies.dart';
import '../models/artwork.dart';
import '../models/design_summary.dart';
import '../models/draft.dart';
import '../models/perspective.dart';
import '../models/units.dart';
import '../models/user_profile.dart';
import '../services/artwork_service.dart';
import '../services/document_scanner_service.dart';
import '../services/export_service.dart';
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
  final _exportKey = GlobalKey();
  bool _exporting = false;

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
            message: 'Framed with PickAFrame\n${designSummaryText(viewModel.design)}',
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

  /// Shows an interactive test panel to verify Firebase Auth and Firestore.
  Future<void> _showFirebaseTestDialog() async {
    final dependencies = AppScope.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String statusText = '点击下方按钮，直接连线真实的 Firebase 云端进行体检测试：';
        bool isBusy = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Firebase 联调体检器', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText, style: const TextStyle(fontSize: 13)),
                  if (isBusy) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          setDialogState(() {
                            isBusy = true;
                            statusText = '⏳ 正在向 Firebase Auth 发起注册并写入 users 表...';
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
                              statusText = '🎉 Auth & Users 写入成功！\n\n'
                                  '• 注册邮箱: $email\n'
                                  '• UID: ${profile.uid}\n'
                                  '• 角色: Artist\n\n'
                                  '👉 去你的 Firebase Console 刷新，即可看到 users 表！';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isBusy = false;
                              statusText = '❌ Auth 报错: $e';
                            });
                          }
                        },
                  child: const Text('1. 测试 Auth 注册'),
                ),
                TextButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          setDialogState(() {
                            isBusy = true;
                            statusText = '⏳ 正在将当前画框存入 Firestore drafts 集合...';
                          });
                          try {
                            final currentUid = dependencies.auth.currentUser?.uid ?? 'guest_test_uid';
                            final draft = Draft(
                              id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
                              ownerUid: currentUid,
                              title: '测试画框作品 #${DateTime.now().second}',
                              design: viewModel.design,
                              updatedAt: DateTime.now(),
                            );
                            await dependencies.drafts.saveDraft(draft);
                            setDialogState(() {
                              isBusy = false;
                              statusText = '🎉 草稿写入 Firestore 成功！\n\n'
                                  '• 草稿 ID: ${draft.id}\n'
                                  '• 草稿标题: ${draft.title}\n'
                                  '• 外框宽度: ${draft.design.moulding.faceWidthMm}mm\n\n'
                                  '👉 去 Firebase Console 刷新，即可看到 drafts 集合！';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isBusy = false;
                              statusText = '❌ 草稿写入报错: $e';
                            });
                          }
                        },
                  child: const Text('2. 测试保存草稿'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('关闭'),
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
                icon: const Icon(Icons.cloud_sync, color: Colors.amberAccent),
                tooltip: 'Firebase 联调测试',
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
                child: FrameRenderer(
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

enum _ExportAction { save, share }
