import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Section 2 // Workflow Architecture ("How it works" — 3 Steps to Precision).
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading row: How it works | 3 STEPS TO PRECISION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'How it works',
              style: TextStyle(
                color: AppPalette.obsidianBlack,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '3 STEPS TO PRECISION',
              style: AppTheme.monoStyle(
                fontSize: 9.5,
                color: AppPalette.mutedZinc,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3 Equal-width architectural step cards
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _WorkflowStepCard(
                  stepNumber: '1',
                  icon: Icons.upload_file_outlined,
                  title: 'Upload',
                  description: 'Add your artwork file or flat capture',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _WorkflowStepCard(
                  stepNumber: '2',
                  icon: Icons.crop_original_rounded,
                  title: 'Design',
                  description: 'Frame, mat + preview on real wall scale',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _WorkflowStepCard(
                  stepNumber: '3',
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Order',
                  description: 'Send locked millimeter spec to maker',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String stepNumber;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.background,
        border: Border.all(color: AppPalette.borderLight, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge [1], [2], [3]
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.slateTintSurface,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              stepNumber,
              style: AppTheme.monoStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppPalette.midnightSlate,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Dashed inner icon box
          CustomPaint(
            painter: const _StepDashedBoxPainter(color: AppPalette.borderLight),
            child: Container(
              width: double.infinity,
              height: 58,
              color: AppPalette.slateTintSurface.withValues(alpha: 0.65),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: AppPalette.midnightSlate,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: AppPalette.obsidianBlack,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            description,
            style: const TextStyle(
              color: AppPalette.coolSlate,
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDashedBoxPainter extends CustomPainter {
  const _StepDashedBoxPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dash = 3.5;
    const gap = 3.0;

    void drawLine(Offset a, Offset b) {
      final len = (b - a).distance;
      if (len == 0) return;
      final dx = (b.dx - a.dx) / len;
      final dy = (b.dy - a.dy) / len;
      var pos = 0.0;
      while (pos < len) {
        final end = (pos + dash).clamp(0.0, len);
        canvas.drawLine(
          Offset(a.dx + dx * pos, a.dy + dy * pos),
          Offset(a.dx + dx * end, a.dy + dy * end),
          paint,
        );
        pos += dash + gap;
      }
    }

    drawLine(Offset.zero, Offset(size.width, 0));
    drawLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawLine(Offset(size.width, size.height), Offset(0, size.height));
    drawLine(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _StepDashedBoxPainter oldDelegate) =>
      oldDelegate.color != color;
}
