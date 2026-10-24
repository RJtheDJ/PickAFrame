import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Dashed banner for "Active Exhibition: KL Spring Show" + `[ Inspect Draft ]`.
///
/// Per user confirmation (#3): the subtitle line (`8 pieces queued · 10% workshop
/// bulk tier activated`) is omitted for a cleaner layout.
class ActiveExhibitionBanner extends StatelessWidget {
  const ActiveExhibitionBanner({
    super.key,
    required this.onInspectDraftTap,
  });

  final VoidCallback onInspectDraftTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BannerDashedBorderPainter(
        color: AppPalette.borderMedium,
        radius: 6,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppPalette.slateTintSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.layers_outlined,
              size: 20,
              color: AppPalette.obsidianBlack,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Active Exhibition: KL Spring Show',
                style: TextStyle(
                  color: AppPalette.obsidianBlack,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onInspectDraftTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppPalette.background,
                foregroundColor: AppPalette.obsidianBlack,
                side: const BorderSide(color: AppPalette.borderLight, width: 1.1),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Inspect\nDraft',
                textAlign: TextAlign.center,
                style: AppTheme.monoStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.obsidianBlack,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerDashedBorderPainter extends CustomPainter {
  const _BannerDashedBorderPainter({
    required this.color,
    this.radius = 6.0,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 4.5;
    const dashSpace = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BannerDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
