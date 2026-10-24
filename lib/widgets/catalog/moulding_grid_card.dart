import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Data model representing a frame moulding card in the Unified Frame Catalogue.
class CatalogMouldingItem {
  const CatalogMouldingItem({
    required this.id,
    required this.name,
    required this.widthMm,
    required this.rebateDepthMm,
    required this.pricePerMetreRm,
    required this.frameColor,
    required this.materialClass,
  });

  final String id;
  final String name;
  final double widthMm;
  final int rebateDepthMm;
  final int pricePerMetreRm;
  final Color frameColor;
  final String materialClass;

  String get widthLabel => '${widthMm.round()}mm';
}

/// Simplified, clean 2×2 Moulding Catalogue Grid Card (`Screen c`).
///
/// Per user instructions (Image 3):
/// - Removed top-left badges (`KL READY`, `POPULAR`, `MUSEUM`)
/// - Removed `MLD-xxxx` codes and `rebate XXmm`
/// - Removed material subtitle lines (`Natural grain · Hardwood`, etc.)
/// - Removed inner thumbnail black tag (`MITRE 45°`, `MATTE`, `LEAF`, `RAW`) and bottom-right circle icon
class MouldingGridCard extends StatelessWidget {
  const MouldingGridCard({
    super.key,
    required this.item,
    required this.isFavorited,
    required this.onFavoriteToggle,
    required this.onAddTap,
    required this.onCardTap,
  });

  final CatalogMouldingItem item;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddTap;
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPalette.background,
          border: Border.all(color: AppPalette.borderLight, width: 1.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Clean Square Moulding Preview Box
            AspectRatio(
              aspectRatio: 1.05,
              child: Container(
                decoration: BoxDecoration(
                  color: AppPalette.slateTintSurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppPalette.borderLight.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                child: CustomPaint(
                  painter: _DiagonalGuidePainter(
                    color: AppPalette.borderLight.withValues(alpha: 0.85),
                  ),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.54,
                      heightFactor: 0.54,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          border: Border.all(
                            color: item.frameColor,
                            width: _borderWidthForLabel(item.widthLabel),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.obsidianBlack.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.widthLabel,
                          style: AppTheme.monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.coolSlate,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 2. Bold Moulding Name (e.g. Walnut 35mm)
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppPalette.obsidianBlack,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),

            const Spacer(),

            const Divider(height: 12, thickness: 0.8, color: AppPalette.borderLight),

            // 3. Bottom Price & Action Row: per metre RM 38/m | Heart | [+]
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'per metre',
                        style: AppTheme.monoStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          color: AppPalette.mutedZinc,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'RM ${item.pricePerMetreRm}/m',
                        style: AppTheme.monoStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.obsidianBlack,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Favorite Heart Button
                InkWell(
                  onTap: onFavoriteToggle,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: isFavorited ? AppPalette.midnightSlate : AppPalette.coolSlate,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Dark Square [ + ] Button
                SizedBox(
                  width: 34,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: onAddTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.obsidianBlack,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, size: 19, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static double _borderWidthForLabel(String widthLabel) {
    if (widthLabel.contains('50')) return 9.5;
    if (widthLabel.contains('35')) return 7.5;
    if (widthLabel.contains('25')) return 6.0;
    return 5.0;
  }
}

/// Paints subtle 45° diagonal mitre guide lines from the corners of the preview box.
class _DiagonalGuidePainter extends CustomPainter {
  const _DiagonalGuidePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    _drawDashed(canvas, Offset.zero, Offset(size.width, size.height), paint);
    _drawDashed(canvas, Offset(size.width, 0), Offset(0, size.height), paint);
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dx = (b.dx - a.dx) / total;
    final dy = (b.dy - a.dy) / total;
    var cur = 0.0;
    while (cur < total) {
      final next = (cur + dash).clamp(0.0, total);
      canvas.drawLine(
        Offset(a.dx + dx * cur, a.dy + dy * cur),
        Offset(a.dx + dx * next, a.dy + dy * next),
        paint,
      );
      cur += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalGuidePainter oldDelegate) =>
      oldDelegate.color != color;
}
