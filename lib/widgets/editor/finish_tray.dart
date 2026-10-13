import 'package:flutter/material.dart';

import '../../data/finish_catalog.dart';
import '../../models/frame_finish.dart';
import '../../view_models/editor_viewmodel.dart';

/// Row of swatches for the current finish kind.
class FinishTray extends StatelessWidget {
  const FinishTray({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final current = viewModel.design.finish;

    final swatches = switch (current.kind) {
      FinishKind.paint => [
          for (final color in paintColors)
            _Swatch(
              selected: current is ColorFinish && current.color == color,
              decoration: BoxDecoration(color: color),
              tooltip: 'Paint',
              onTap: () => viewModel.setColor(color),
            ),
        ],
      FinishKind.wood => [
          for (final wood in woodFinishes)
            _Swatch(
              selected: current == wood,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: ResizeImage(AssetImage(wood.textures.albedo), width: 128),
                  fit: BoxFit.cover,
                ),
              ),
              tooltip: wood.name,
              onTap: () => viewModel.selectWood(wood),
            ),
        ],
      FinishKind.metal => [
          for (final metal in metalFinishes)
            _Swatch(
              selected: current == metal,
              // A quick sheen so the swatch reads as metal.
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(metal.color, Colors.white, 0.5)!,
                    metal.color,
                    Color.lerp(metal.color, Colors.black, 0.45)!,
                  ],
                ),
              ),
              tooltip: metal.name,
              onTap: () => viewModel.selectMetal(metal),
            ),
        ],
      FinishKind.ornate => [
          for (final moulding in photoMouldings)
            _Swatch(
              selected: current == moulding,
              width: 120,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(moulding.asset),
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerLeft,
                ),
              ),
              tooltip: moulding.name,
              onTap: () => viewModel.selectPhotoMoulding(moulding),
            ),
        ],
    };

    return ListView(scrollDirection: Axis.horizontal, children: swatches);
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.selected,
    required this.decoration,
    required this.tooltip,
    required this.onTap,
    this.width = 52,
  });

  final bool selected;
  final BoxDecoration decoration;
  final String tooltip;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
          decoration: decoration.copyWith(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.blueAccent : Colors.white38,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
