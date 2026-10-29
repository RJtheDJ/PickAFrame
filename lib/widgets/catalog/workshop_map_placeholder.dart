import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'moulding_grid_card.dart';

/// Placeholder card for the `KL Workshop Map Directory` section on `CatalogScreen`.
///
/// - When [selectedMoulding] is null, displays the overview (`9 VERIFIED WORKSHOPS CONNECTED`).
/// - When the user taps a moulding card (e.g. `Gilded 50mm`), [selectedMoulding]
///   updates this map card to display the origin workshop for that moulding.
/// - Tapping the map (`onMapTap`) opens the full `Map (KL)` directory page (Image 2).
class WorkshopMapPlaceholder extends StatelessWidget {
  const WorkshopMapPlaceholder({
    super.key,
    required this.onCloseTap,
    required this.onMapTap,
    this.selectedMoulding,
  });

  final VoidCallback onCloseTap;
  final VoidCallback onMapTap;
  final CatalogMouldingItem? selectedMoulding;

  @override
  Widget build(BuildContext context) {
    final moulding = selectedMoulding;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.background,
        border: Border.all(
          color: moulding != null ? AppPalette.obsidianBlack : AppPalette.borderLight,
          width: moulding != null ? 1.4 : 1.1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Storefront Icon + KL Workshop Map Directory | [CLOSE]
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 16,
                color: AppPalette.obsidianBlack,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  moulding != null
                      ? 'KL Workshop Map · ${moulding.name}'
                      : 'KL Workshop Map Directory',
                  style: AppTheme.monoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.obsidianBlack,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              InkWell(
                onTap: onCloseTap,
                borderRadius: BorderRadius.circular(3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '[CLOSE]',
                    style: AppTheme.monoStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.mutedZinc,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Stylized KL Map Canvas Placeholder (Tap to go to Catalog - Map (KL) view)
          GestureDetector(
            onTap: onMapTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 154,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Custom-painted stylized KL road/park map canvas
                    const CustomPaint(
                      painter: _StylizedKlMapPainter(),
                    ),

                    // Subtle district labels matching wireframe
                    const Positioned(
                      top: 26,
                      left: 16,
                      child: _MapDistrictLabel('KEPONG'),
                    ),
                    const Positioned(
                      top: 46,
                      right: 26,
                      child: _MapDistrictLabel('WANGSA MAJU'),
                    ),
                    const Positioned(
                      bottom: 24,
                      left: 14,
                      child: _MapDistrictLabel('PETALING JAYA'),
                    ),
                    const Positioned(
                      bottom: 18,
                      right: 18,
                      child: _MapDistrictLabel('AMPANG'),
                    ),

                    // Center Overlay: either Selected Moulding Workshop Origin or Default Overview
                    Center(
                      child: moulding != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.background.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: AppPalette.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'FRAME SOURCE · ${moulding.name.toUpperCase()}',
                                    style: AppTheme.monoStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppPalette.coolSlate,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.obsidianBlack,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppPalette.obsidianBlack.withValues(alpha: 0.18),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          moulding.workshopName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.background.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${moulding.workshopDistrict} · Tap map for details →',
                                    style: const TextStyle(
                                      color: AppPalette.obsidianBlack,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.background.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: AppPalette.borderLight,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppPalette.obsidianBlack.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '9 VERIFIED WORKSHOPS CONNECTED',
                                    style: AppTheme.monoStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppPalette.obsidianBlack,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppPalette.background.withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Text(
                                    'Bangsar · Cheras · Ampang Corridor',
                                    style: TextStyle(
                                      color: AppPalette.obsidianBlack,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Kuala Lumpur',
                                  style: TextStyle(
                                    color: AppPalette.darkCharcoal,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapDistrictLabel extends StatelessWidget {
  const _MapDistrictLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.monoStyle(
        fontSize: 7.5,
        fontWeight: FontWeight.w700,
        color: AppPalette.coolSlate.withValues(alpha: 0.75),
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Paints a realistic vector map background (parks, rivers, highways, and pins)
/// so the placeholder looks crisp without needing an external image or API key.
class _StylizedKlMapPainter extends CustomPainter {
  const _StylizedKlMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Base map land tint
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE5EAEF),
    );

    // Green park patches
    final parkPaint = Paint()..color = const Color(0xFFCFE6D4);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.36, size.height * 0.08, size.width * 0.22, size.height * 0.30),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.74, size.height * 0.14, size.width * 0.22, size.height * 0.28),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.62, size.width * 0.20, size.height * 0.26),
      parkPaint,
    );

    // Secondary road grid
    final minorRoad = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 6; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 10), minorRoad);
    }
    for (var i = 1; i < 7; i++) {
      final x = size.width * (i / 7);
      canvas.drawLine(Offset(x, 0), Offset(x - 14, size.height), minorRoad);
    }

    // Major Klang Valley arterial highways (blue-slate & amber highway lines)
    final highwayPaint = Paint()
      ..color = const Color(0xFF9FB4CE)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final h1 = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.42,
        size.width,
        size.height * 0.22,
      );
    canvas.drawPath(h1, highwayPaint);

    final h2 = Path()
      ..moveTo(size.width * 0.18, 0)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.55,
        size.width * 0.62,
        size.height,
      );
    canvas.drawPath(h2, highwayPaint);

    final ringRoad = Paint()
      ..color = const Color(0xFFF3C969)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.54),
        width: size.width * 0.56,
        height: size.height * 0.58,
      ),
      ringRoad,
    );

    // Workshop pin markers
    final pinPaint = Paint()..color = AppPalette.midnightSlate;
    final pinCenter = Paint()..color = Colors.white;
    final pins = [
      Offset(size.width * 0.28, size.height * 0.48),
      Offset(size.width * 0.68, size.height * 0.36),
      Offset(size.width * 0.58, size.height * 0.72),
      Offset(size.width * 0.38, size.height * 0.25),
    ];
    for (final pt in pins) {
      canvas.drawCircle(pt, 5.5, pinPaint);
      canvas.drawCircle(pt, 2.2, pinCenter);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
