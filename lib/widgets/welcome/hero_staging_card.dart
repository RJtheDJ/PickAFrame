import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';
import '../../models/artwork.dart';
import '../../models/mat_spec.dart';
import '../../models/perspective.dart';
import '../../models/units.dart';
import '../../services/artwork_service.dart';
import '../../services/document_scanner_service.dart';
import '../../view_models/editor_viewmodel.dart';
import '../../views/artwork_crop_screen.dart';
import '../frame_renderer.dart';

/// Interactive 1:1 Real-Time Staging Box on the Landing Page.
///
/// Lets prospective customers upload/scan their artwork and immediately preview
/// it inside an A3 calibrated frame (with 50mm mat) right on the Landing Page
/// before signing in—without modifying or jumping to `EditorScreen`.
class HeroStagingCard extends StatefulWidget {
  const HeroStagingCard({super.key});

  @override
  State<HeroStagingCard> createState() => _HeroStagingCardState();
}

class _HeroStagingCardState extends State<HeroStagingCard> {
  late final EditorViewModel _previewVm;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Reuse EditorViewModel for real-time shader/texture loading, calibrated
    // to A3 (297 × 420 mm) and 50 mm mat to match the wireframe specification.
    _previewVm = EditorViewModel()
      ..setArtworkSizeMm(const Size(297, 420))
      ..setMatLinked(true)
      ..setMatSideMm(MatSide.top, 50);
  }

  @override
  void dispose() {
    _previewVm.dispose();
    super.dispose();
  }

  /// Opens the upload picker (ML Kit Document Scanner on Android, Gallery, or Camera),
  /// crops with [ArtworkCropScreen], and renders the framed artwork inside this card.
  Future<void> _pickAndPreviewArtwork() async {
    final choice = await showModalBottomSheet<_StagingArtworkSource>(
      context: context,
      backgroundColor: AppPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'STAGE YOUR ARTWORK // 1:1 PREVIEW',
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    color: AppPalette.mutedZinc,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Upload an artwork to preview framing before signing in',
                  style: TextStyle(
                    color: AppPalette.obsidianBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppPalette.borderLight),
              if (isArtworkScannerAvailable)
                ListTile(
                  leading: const Icon(Icons.document_scanner_outlined, color: AppPalette.midnightSlate),
                  title: const Text(
                    'Scan artwork',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppPalette.obsidianBlack),
                  ),
                  subtitle: const Text(
                    'Finds corners automatically and straightens perspective',
                    style: TextStyle(color: AppPalette.coolSlate, fontSize: 12.5),
                  ),
                  onTap: () => Navigator.pop(context, _StagingArtworkSource.scan),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppPalette.midnightSlate),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppPalette.obsidianBlack),
                ),
                subtitle: const Text(
                  'JPG, PNG, HEIC — manual 4-corner perspective crop',
                  style: TextStyle(color: AppPalette.coolSlate, fontSize: 12.5),
                ),
                onTap: () => Navigator.pop(context, _StagingArtworkSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppPalette.midnightSlate),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppPalette.obsidianBlack),
                ),
                subtitle: const Text(
                  'Flat capture recommended for accurate millimeter scale',
                  style: TextStyle(color: AppPalette.coolSlate, fontSize: 12.5),
                ),
                onTap: () => Navigator.pop(context, _StagingArtworkSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      if (choice == _StagingArtworkSource.scan) {
        final scanned = await scanArtwork();
        if (scanned == null || !mounted) return;
        _applyStagedArtwork(
          Artwork(
            image: scanned,
            source: scanned,
            corners: Quad.full(Size(scanned.width.toDouble(), scanned.height.toDouble())),
          ),
        );
        return;
      }

      final photo = await pickArtworkPhoto(
        choice == _StagingArtworkSource.camera ? ImageSource.camera : ImageSource.gallery,
      );
      if (photo == null || !mounted) return;

      final artwork = await Navigator.of(context).push<Artwork>(
        MaterialPageRoute(builder: (_) => ArtworkCropScreen(source: photo)),
      );
      if (artwork != null && mounted) {
        _applyStagedArtwork(artwork);
      }
    } catch (e) {
      debugPrint('Error staging artwork on landing page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't load that artwork. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _applyStagedArtwork(Artwork artwork) {
    // Keep A3 base width (297 mm) and adjust aspect ratio to the uploaded artwork.
    _previewVm.setArtworkSizeMm(const Size(297, 420));
    _previewVm.setArtwork(artwork);
    _previewVm.applyThreeToOneMat(); // Clean proportional mat (~50-60mm)
  }

  Future<void> _recropCurrentArtwork() async {
    final current = _previewVm.artwork;
    if (current == null) return;
    final updated = await Navigator.of(context).push<Artwork>(
      MaterialPageRoute(
        builder: (_) => ArtworkCropScreen(
          source: current.source,
          initialCorners: current.corners,
        ),
      ),
    );
    if (updated != null && mounted) {
      _applyStagedArtwork(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _previewVm,
      builder: (context, _) {
        final hasArtwork = _previewVm.artwork != null;
        final design = _previewVm.design;

        return CustomPaint(
          painter: const _DashedRectPainter(
            color: AppPalette.mutedZinc,
            strokeWidth: 1.2,
            dashWidth: 5,
            dashSpace: 4,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            color: AppPalette.surfaceLight.withValues(alpha: 0.55),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Technical Readout Row: SCALE: 1:1 REAL-TIME | STATUS: STANDBY / ACTIVE
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Subtle background engineering dimension markers ("420.0mm")
                    Positioned(
                      left: 0,
                      top: -4,
                      child: Text(
                        '420.0mm',
                        style: AppTheme.monoStyle(
                          fontSize: 8.5,
                          color: AppPalette.mutedZinc.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: -4,
                      child: Text(
                        '420.0mm',
                        style: AppTheme.monoStyle(
                          fontSize: 8.5,
                          color: AppPalette.mutedZinc.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.crop_free_rounded,
                                size: 13,
                                color: AppPalette.coolSlate,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'SCALE: 1:1 REAL-TIME',
                                style: AppTheme.monoStyle(
                                  fontSize: 10,
                                  color: AppPalette.coolSlate,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: hasArtwork
                                      ? AppPalette.midnightSlate
                                      : AppPalette.mutedZinc,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                hasArtwork ? 'STATUS: STAGED' : 'STATUS: STANDBY',
                                style: AppTheme.monoStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: hasArtwork
                                      ? AppPalette.midnightSlate
                                      : AppPalette.mutedZinc,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Center Frame Preview Area (Standby Wireframe vs. Live Framed Artwork)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: AspectRatio(
                      aspectRatio: 0.78,
                      child: hasArtwork
                          ? _ActiveFramedPreview(
                              viewModel: _previewVm,
                              onRecrop: _recropCurrentArtwork,
                              onReset: () {
                                setState(() {
                                  // Reset by recreating or clearing artwork
                                  Navigator.of(context);
                                });
                              },
                            )
                          : _StandbyFrameIllustration(onTap: _pickAndPreviewArtwork),
                    ),
                  ),
                ),

                if (hasArtwork) ...[
                  const SizedBox(height: 10),
                  // Live millimeter spec readout + quick actions for staged artwork
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppPalette.slateTintSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppPalette.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.straighten_rounded,
                          size: 14,
                          color: AppPalette.midnightSlate,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Art ${formatSize(design.artworkMm)} · Outer ${formatSize(design.outerMm)}',
                            style: AppTheme.monoStyle(
                              fontSize: 10,
                              color: AppPalette.midnightSlate,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: _recropCurrentArtwork,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              '[ RE-CROP ]',
                              style: AppTheme.monoStyle(
                                fontSize: 9.5,
                                color: AppPalette.obsidianBlack,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Primary CTA Button: [ + UPLOAD YOUR ARTWORK ]
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _pickAndPreviewArtwork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.obsidianBlack,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppPalette.coolSlate,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                hasArtwork
                                    ? '[ + TRY ANOTHER ARTWORK ]'
                                    : '[ + UPLOAD YOUR ARTWORK ]',
                                style: AppTheme.monoStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Bottom Technical Note + 297.0mm dimension marker
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      bottom: -3,
                      child: Text(
                        '297.0mm',
                        style: AppTheme.monoStyle(
                          fontSize: 8.5,
                          color: AppPalette.mutedZinc.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: AppPalette.mutedZinc,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasArtwork
                                ? 'Live preview ready! Sign in or create an account below to save this spec & order from KL workshops.'
                                : 'JPG, PNG, HEIC - up to 25 MB (Flat capture recommended)',
                            style: AppTheme.monoStyle(
                              fontSize: 9.8,
                              fontWeight: FontWeight.w500,
                              color: hasArtwork
                                  ? AppPalette.midnightSlate
                                  : AppPalette.mutedZinc,
                              letterSpacing: 0.2,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wireframe standby frame illustration shown before the customer uploads an image.
class _StandbyFrameIllustration extends StatelessWidget {
  const _StandbyFrameIllustration({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.background,
                border: Border.all(color: AppPalette.darkCharcoal, width: 1.4),
              ),
              padding: const EdgeInsets.all(10),
              child: CustomPaint(
                painter: const _MitreCornerLinesPainter(color: AppPalette.borderLight),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppPalette.slateTintSurface,
                    border: Border.all(color: AppPalette.borderLight, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Framed mountain/sun artwork icon matching wireframe
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppPalette.coolSlate, width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(
                          Icons.landscape_outlined,
                          size: 22,
                          color: AppPalette.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '# # # # # # #',
                        style: AppTheme.monoStyle(
                          fontSize: 9.5,
                          color: AppPalette.coolSlate,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'SAMPLE ARTWORK',
                        style: AppTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.obsidianBlack,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '# # # # # # #',
                        style: AppTheme.monoStyle(
                          fontSize: 9.5,
                          color: AppPalette.coolSlate,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Pill badge: A3 PROFILE · MAT: 50mm
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppPalette.midnightSlate.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'A3 PROFILE · MAT: 50mm',
                          style: AppTheme.monoStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.midnightSlate,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Architectural heavy bottom shadow bar from wireframe
          Container(
            height: 3.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: AppPalette.obsidianBlack,
          ),
        ],
      ),
    );
  }
}

/// Renders the uploaded [Artwork] inside the real [FrameRenderer] right inside
/// the Landing Page's 1:1 staging box.
class _ActiveFramedPreview extends StatelessWidget {
  const _ActiveFramedPreview({
    required this.viewModel,
    required this.onRecrop,
    required this.onReset,
  });

  final EditorViewModel viewModel;
  final VoidCallback onRecrop;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.slateTintSurface,
        border: Border.all(color: AppPalette.darkCharcoal, width: 1.2),
      ),
      child: ClipRect(
        child: FrameRenderer(
          design: viewModel.design,
          light: viewModel.light,
          finishImages: viewModel.finishImages,
          shaderResources: viewModel.shaderResources,
          artworkImage: viewModel.artwork?.image,
          wallColor: AppPalette.slateTintSurface,
        ),
      ),
    );
  }
}

/// Draws subtle 45-degree mitre joint lines at the 4 corners of the standby frame.
class _MitreCornerLinesPainter extends CustomPainter {
  const _MitreCornerLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const inset = 10.0;
    // Top-left mitre
    canvas.drawLine(Offset.zero, const Offset(inset, inset), paint);
    // Top-right mitre
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - inset, inset), paint);
    // Bottom-left mitre
    canvas.drawLine(Offset(0, size.height), Offset(inset, size.height - inset), paint);
    // Bottom-right mitre
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MitreCornerLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Draws a technical dashed border around the 1:1 staging container.
class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 5.0,
    this.dashSpace = 4.0,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Top edge
    _drawDashedLine(canvas, Offset.zero, Offset(size.width, 0), paint);
    // Right edge
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(size.width, size.height), paint);
    // Bottom edge
    _drawDashedLine(canvas, Offset(size.width, size.height), Offset(0, size.height), paint);
    // Left edge
    _drawDashedLine(canvas, Offset(0, size.height), Offset.zero, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (end - start).distance;
    if (distance == 0) return;

    final ux = dx / distance;
    final uy = dy / distance;
    var current = 0.0;

    while (current < distance) {
      final next = (current + dashWidth).clamp(0.0, distance);
      canvas.drawLine(
        Offset(start.dx + ux * current, start.dy + uy * current),
        Offset(start.dx + ux * next, start.dy + uy * next),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}

enum _StagingArtworkSource { scan, gallery, camera }
