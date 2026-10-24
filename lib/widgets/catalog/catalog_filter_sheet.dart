import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Filter state for `CatalogScreen`.
///
/// Starts completely empty (`CatalogFilterState.empty`) so no filter chips are
/// shown until the user explicitly chooses filters in the `Filter` bottom sheet.
class CatalogFilterState {
  const CatalogFilterState({
    this.materialClass,
    this.maxProfileWidthMm,
    this.minRebateDepthMm,
    this.maxPricePerMetreRm,
  });

  static const CatalogFilterState empty = CatalogFilterState();

  /// Selected material class:
  /// - `'Wood (Hardwood)'`
  /// - `'Aluminium Metal'`
  /// - `'Composite Polymer'`
  /// - `'Gilded / Foil Leaf'`
  final String? materialClass;

  /// Maximum profile width in mm (10..120), or null if not filtering by width.
  final double? maxProfileWidthMm;

  /// Minimum rebate depth in mm (`10`, `14`, or `25`), or null if not filtering.
  final int? minRebateDepthMm;

  /// Maximum price per metre in RM (10..200), or null if not filtering by price.
  final int? maxPricePerMetreRm;

  int get activeCount {
    var count = 0;
    if (materialClass != null) count++;
    if (maxProfileWidthMm != null) count++;
    if (minRebateDepthMm != null) count++;
    if (maxPricePerMetreRm != null) count++;
    return count;
  }

  bool get hasAnyFilter => activeCount > 0;

  static String shortMaterialName(String materialClass) {
    if (materialClass.startsWith('Wood')) return 'Wood';
    if (materialClass.startsWith('Aluminium')) return 'Metal';
    if (materialClass.startsWith('Composite')) return 'Composite';
    if (materialClass.startsWith('Gilded')) return 'Gilded';
    return materialClass;
  }

  CatalogFilterState copyWith({
    String? materialClass,
    bool clearMaterial = false,
    double? maxProfileWidthMm,
    bool clearProfileWidth = false,
    int? minRebateDepthMm,
    bool clearRebateDepth = false,
    int? maxPricePerMetreRm,
    bool clearMaxPrice = false,
  }) {
    return CatalogFilterState(
      materialClass: clearMaterial ? null : (materialClass ?? this.materialClass),
      maxProfileWidthMm:
          clearProfileWidth ? null : (maxProfileWidthMm ?? this.maxProfileWidthMm),
      minRebateDepthMm:
          clearRebateDepth ? null : (minRebateDepthMm ?? this.minRebateDepthMm),
      maxPricePerMetreRm:
          clearMaxPrice ? null : (maxPricePerMetreRm ?? this.maxPricePerMetreRm),
    );
  }
}

/// Interactive Filter bottom sheet (`Filter` — replaces `Granular Spec Filters`
/// and removes `[SPEC-S3B]`).
class CatalogFilterSheet extends StatefulWidget {
  const CatalogFilterSheet({
    super.key,
    required this.initialState,
    required this.onChanged,
  });

  final CatalogFilterState initialState;
  final ValueChanged<CatalogFilterState> onChanged;

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  static const List<String> _materialClasses = [
    'Wood (Hardwood)',
    'Aluminium Metal',
    'Composite Polymer',
    'Gilded / Foil Leaf',
  ];

  static const List<(int, String)> _rebateOptions = [
    (10, '≥ 10 mm'),
    (14, '≥ 14 mm'),
    (25, '≥ 25 mm (Deep)'),
  ];

  late CatalogFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  void _update(CatalogFilterState next) {
    setState(() => _state = next);
    widget.onChanged(next);
  }

  void _resetAll() {
    _update(CatalogFilterState.empty);
  }

  @override
  Widget build(BuildContext context) {
    final widthSliderValue = (_state.maxProfileWidthMm ?? 120.0).clamp(10.0, 120.0);
    final priceSliderValue = (_state.maxPricePerMetreRm ?? 200).toDouble().clamp(10.0, 200.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header row: Filter ... Reset  ✕ (no [SPEC-S3B])
              Row(
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _resetAll,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Reset',
                        style: AppTheme.monoStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.mutedZinc,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppPalette.mutedZinc,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppPalette.coolSlate,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: AppPalette.borderLight),
              const SizedBox(height: 16),

              // 1. MATERIAL CLASS
              Text(
                'MATERIAL CLASS',
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.obsidianBlack,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.1,
                children: [
                  for (final mat in _materialClasses)
                    _MaterialClassTile(
                      label: mat,
                      selected: _state.materialClass == mat,
                      onTap: () {
                        if (_state.materialClass == mat) {
                          _update(_state.copyWith(clearMaterial: true));
                        } else {
                          _update(_state.copyWith(materialClass: mat));
                        }
                      },
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. PROFILE WIDTH
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROFILE WIDTH',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.obsidianBlack,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    _state.maxProfileWidthMm == null
                        ? '10 mm – 120 mm'
                        : '10 mm – ${_state.maxProfileWidthMm!.round()} mm',
                    style: AppTheme.monoStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.obsidianBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppPalette.obsidianBlack,
                  inactiveTrackColor: AppPalette.borderLight,
                  thumbColor: AppPalette.obsidianBlack,
                  overlayColor: AppPalette.obsidianBlack.withValues(alpha: 0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(
                  value: widthSliderValue,
                  min: 10,
                  max: 120,
                  divisions: 22,
                  onChanged: (val) {
                    if (val >= 120) {
                      _update(_state.copyWith(clearProfileWidth: true));
                    } else {
                      _update(_state.copyWith(maxProfileWidthMm: val.roundToDouble()));
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min: 10mm (Slim)',
                    style: AppTheme.monoStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.mutedZinc,
                    ),
                  ),
                  Text(
                    'Max: 120mm (Ornate)',
                    style: AppTheme.monoStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.mutedZinc,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. REBATE DEPTH
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'REBATE DEPTH',
                        style: AppTheme.monoStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.obsidianBlack,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppPalette.mutedZinc,
                      ),
                    ],
                  ),
                  Text(
                    _state.minRebateDepthMm == null
                        ? 'Any depth'
                        : '≥ ${_state.minRebateDepthMm} mm required',
                    style: AppTheme.monoStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.obsidianBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < _rebateOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _RebateOptionButton(
                        label: _rebateOptions[i].$2,
                        selected: _state.minRebateDepthMm == _rebateOptions[i].$1,
                        onTap: () {
                          final value = _rebateOptions[i].$1;
                          if (_state.minRebateDepthMm == value) {
                            _update(_state.copyWith(clearRebateDepth: true));
                          } else {
                            _update(_state.copyWith(minRebateDepthMm: value));
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // 4. MAX PRICE / METRE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MAX PRICE / METRE',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.obsidianBlack,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    _state.maxPricePerMetreRm == null
                        ? 'RM 200+ / metre'
                        : 'RM ${_state.maxPricePerMetreRm} / metre',
                    style: AppTheme.monoStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.obsidianBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppPalette.obsidianBlack,
                  inactiveTrackColor: AppPalette.borderLight,
                  thumbColor: AppPalette.obsidianBlack,
                  overlayColor: AppPalette.obsidianBlack.withValues(alpha: 0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(
                  value: priceSliderValue,
                  min: 10,
                  max: 200,
                  divisions: 38,
                  onChanged: (val) {
                    if (val >= 200) {
                      _update(_state.copyWith(clearMaxPrice: true));
                    } else {
                      _update(_state.copyWith(maxPricePerMetreRm: val.round()));
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RM 10',
                    style: AppTheme.monoStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.mutedZinc,
                    ),
                  ),
                  Text(
                    'RM 200+',
                    style: AppTheme.monoStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.mutedZinc,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialClassTile extends StatelessWidget {
  const _MaterialClassTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppPalette.obsidianBlack : AppPalette.slateTintSurface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? AppPalette.obsidianBlack : AppPalette.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.monoStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : AppPalette.darkCharcoal,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _RebateOptionButton extends StatelessWidget {
  const _RebateOptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppPalette.obsidianBlack : AppPalette.slateTintSurface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? AppPalette.obsidianBlack : AppPalette.borderLight,
            width: 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.monoStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : AppPalette.coolSlate,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
