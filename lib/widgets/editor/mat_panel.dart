import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/mat_catalog.dart';
import '../../models/mat_spec.dart';
import '../../view_models/editor_viewmodel.dart';
import 'color_swatch_row.dart';
import 'labeled_slider.dart';

/// Precision Matting Engine controls styled after the Light Architectural
/// Studio wireframe (Image 1) while preserving 100% of [EditorViewModel]
/// functions.
class MatPanel extends StatelessWidget {
  const MatPanel({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  static const _maxBorderMm = 300.0;

  @override
  Widget build(BuildContext context) {
    final mat = viewModel.design.mat;

    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      children: [
        // 1. HEADER: Precision Matting Engine + Reset
        Row(
          children: [
            const Icon(Icons.straighten_outlined, size: 18, color: Color(0xFF090A0C)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Precision Matting Engine',
                style: TextStyle(
                  color: Color(0xFF090A0C),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                viewModel.setMatLinked(true);
                viewModel.setMatSideMm(MatSide.top, 50);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: Color(0xFF4B5563)),
                    SizedBox(width: 4),
                    Text(
                      'Reset',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. MOUNT STYLE (Flat / Double / 3D Float)
        const Text(
          'MOUNT STYLE',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              for (final style in MountStyle.values)
                Expanded(
                  child: GestureDetector(
                    onTap: () => viewModel.setMountStyle(style),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: mat.style == style ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: mat.style == style
                            ? const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _mountLabel(style),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mat.style == style
                              ? const Color(0xFF090A0C)
                              : const Color(0xFF4B5563),
                          fontSize: 12,
                          fontWeight: mat.style == style ? FontWeight.w800 : FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. GALLERY PRESETS
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GALLERY PRESETS',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'P1 Proportions',
              style: TextStyle(
                color: Color(0xFF71717A),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetPill(
                label: 'Golden Ratio',
                onTap: viewModel.applyGoldenRatioMat,
              ),
              const SizedBox(width: 6),
              _PresetPill(
                label: '3:1 Weighted',
                onTap: viewModel.applyThreeToOneMat,
              ),
              const SizedBox(width: 6),
              _PresetPill(
                label: 'Bottom-weighted',
                onTap: viewModel.applyBottomWeightedMat,
              ),
              const SizedBox(width: 6),
              _PresetPill(
                label: 'Equal 50mm',
                onTap: () {
                  viewModel.setMatLinked(true);
                  viewModel.setMatSideMm(MatSide.top, 50);
                },
              ),
              const SizedBox(width: 6),
              _PresetPill(
                label: 'Clear',
                onTap: () {
                  viewModel.setMatLinked(true);
                  viewModel.setMatSideMm(MatSide.top, 0);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. MARGINS CALIBRATION CARD (Image 1 steppers + sliders)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Margins Calibration',
                      style: TextStyle(
                        color: Color(0xFF090A0C),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => viewModel.setMatLinked(!viewModel.matLinked),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: viewModel.matLinked
                                ? const Color(0xFF090A0C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: viewModel.matLinked
                                  ? const Color(0xFF090A0C)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          child: viewModel.matLinked
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '[${viewModel.matLinked ? 'x' : ' '}] Link all sides',
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (viewModel.matLinked)
                _MarginStepperRow(
                  label: 'All Sides Margin',
                  valueMm: mat.topMm,
                  minMm: 0,
                  maxMm: _maxBorderMm,
                  onChanged: (mm) => viewModel.setMatSideMm(MatSide.top, mm),
                )
              else
                for (final side in MatSide.values) ...[
                  _MarginStepperRow(
                    label: _sideLabel(side),
                    valueMm: mat.side(side),
                    minMm: 0,
                    maxMm: _maxBorderMm,
                    onChanged: (mm) => viewModel.setMatSideMm(side, mm),
                  ),
                  const SizedBox(height: 4),
                ],
              if (mat.style == MountStyle.doubleMat) ...[
                const SizedBox(height: 4),
                _MarginStepperRow(
                  label: 'Inner Reveal',
                  valueMm: mat.revealMm,
                  minMm: 2,
                  maxMm: 20,
                  onChanged: viewModel.setRevealMm,
                ),
              ],
              const SizedBox(height: 4),
              const Text(
                '* Steppers adjust in 1 mm increments. Long-press steps by 5 mm.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. DUAL-CORE SWATCHES (Image 1 style)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dual-Core Swatches',
              style: TextStyle(
                color: Color(0xFF090A0C),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Face: Archival Rag',
                style: TextStyle(
                  color: Color(0xFF090A0C),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ColorSwatchRow(
          label: mat.style == MountStyle.float ? 'Backing' : 'Board',
          colors: matBoardColors,
          selected: mat.color,
          onSelected: viewModel.setMatColor,
        ),
        if (mat.style == MountStyle.doubleMat) ...[
          const SizedBox(height: 4),
          ColorSwatchRow(
            label: 'Inner mat',
            colors: matBoardColors,
            selected: mat.innerColor,
            onSelected: viewModel.setInnerMatColor,
          ),
        ],
        if (mat.style != MountStyle.float) ...[
          const SizedBox(height: 4),
          ColorSwatchRow(
            label: 'Core',
            colors: matCoreColors,
            selected: mat.coreColor,
            onSelected: viewModel.setMatCoreColor,
          ),
        ],
        const SizedBox(height: 10),

        // 6. BEVEL CUT DEPTH CALLOUT CARD (Image 1 style)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bevel Cut Depth: 4 mm',
                      style: TextStyle(
                        color: Color(0xFF090A0C),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Precision 45° diamond cut • Archival rag',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE4EE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${mat.topMm.round()} mm\nBorder',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF090A0C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _mountLabel(MountStyle style) => switch (style) {
        MountStyle.flat => 'Flat',
        MountStyle.doubleMat => 'Double',
        MountStyle.float => '3D Float',
      };

  static String _sideLabel(MatSide side) => switch (side) {
        MatSide.top => 'Top Margin',
        MatSide.bottom => 'Bottom Margin (Weighted)',
        MatSide.left => 'Left Margin',
        MatSide.right => 'Right Margin',
      };
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFDCE4EE),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF090A0C),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _MarginStepperRow extends StatefulWidget {
  const _MarginStepperRow({
    required this.label,
    required this.valueMm,
    required this.minMm,
    required this.maxMm,
    required this.onChanged,
  });

  final String label;
  final double valueMm;
  final double minMm;
  final double maxMm;
  final ValueChanged<double> onChanged;

  @override
  State<_MarginStepperRow> createState() => _MarginStepperRowState();
}

class _MarginStepperRowState extends State<_MarginStepperRow> {
  Timer? _holdTimer;

  void _step(double delta) {
    final next = (widget.valueMm + delta).clamp(widget.minMm, widget.maxMm);
    widget.onChanged(next.roundToDouble());
  }

  void _startHold(double delta) {
    _holdTimer?.cancel();
    _step(delta);
    _holdTimer = Timer.periodic(const Duration(milliseconds: 120), (_) => _step(delta));
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            _StepBtn(
              symbol: '-',
              onTap: () => _step(-1),
              onLongPressStart: () => _startHold(-5),
              onLongPressEnd: _stopHold,
            ),
            Container(
              width: 64,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                '${widget.valueMm.round()} mm',
                style: const TextStyle(
                  color: Color(0xFF090A0C),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            _StepBtn(
              symbol: '+',
              onTap: () => _step(1),
              onLongPressStart: () => _startHold(5),
              onLongPressEnd: _stopHold,
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF090A0C),
            inactiveTrackColor: const Color(0xFFCBD5E1),
            thumbColor: const Color(0xFF090A0C),
            overlayColor: const Color(0x14090A0C),
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: widget.valueMm.clamp(widget.minMm, widget.maxMm),
            min: widget.minMm,
            max: widget.maxMm,
            onChanged: (v) => widget.onChanged(v.roundToDouble()),
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.symbol,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final String symbol;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      onLongPressCancel: onLongPressEnd,
      child: Container(
        width: 28,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFDCE4EE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            color: Color(0xFF090A0C),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
