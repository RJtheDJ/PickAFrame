import 'package:flutter/material.dart';

/// A preview with its control panel: stacked on portrait phones, side by side
/// when the screen is landscape or wide (tablets), so the controls never
/// squeeze the preview off a short screen.
class WorkspaceLayout extends StatelessWidget {
  const WorkspaceLayout({
    super.key,
    required this.preview,
    required this.controls,
    this.controlsHeight = 340,
    this.controlsWidth = 380,
  });

  final Widget preview;

  /// Fills the box it is given: [controlsHeight] tall when stacked,
  /// [controlsWidth] wide and full height when side by side.
  final Widget controls;
  final double controlsHeight;
  final double controlsWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 600 && constraints.maxWidth > constraints.maxHeight;
        if (sideBySide) {
          return Row(
            children: [
              Expanded(child: preview),
              SizedBox(width: controlsWidth, child: controls),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: preview),
            SizedBox(height: controlsHeight, child: controls),
          ],
        );
      },
    );
  }
}
