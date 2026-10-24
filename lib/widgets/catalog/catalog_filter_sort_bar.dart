import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Filter & Sort controls on `CatalogScreen`:
/// - Balanced 50 / 50 row: `[ Filters ]` (left 50%) and `[ Sort: ... v ]` (right 50%)
/// - When the user selects filters, active filter chips (`Mat: Wood ✕`, etc.)
///   appear cleanly below the 50 / 50 row.
class CatalogFilterSortBar extends StatelessWidget {
  const CatalogFilterSortBar({
    super.key,
    required this.activeFilterChips,
    required this.sortLabel,
    required this.onFiltersTap,
    required this.onRemoveChip,
    required this.onSortTap,
  });

  final List<CatalogFilterChipData> activeFilterChips;
  final String sortLabel;
  final VoidCallback onFiltersTap;
  final ValueChanged<String> onRemoveChip;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 50 / 50 Row: [ Filters ] (50%) | [ Sort: ... v ] (50%)
        Row(
          children: [
            // Left 50%: Primary dark Filters button
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onFiltersTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.obsidianBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.tune_rounded, size: 15, color: Colors.white),
                      const SizedBox(width: 7),
                      Text(
                        'Filters',
                        style: AppTheme.monoStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (activeFilterChips.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${activeFilterChips.length}',
                            style: AppTheme.monoStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.obsidianBlack,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Right 50%: [ Sort: Newest v ] button
            Expanded(
              child: InkWell(
                onTap: onSortTap,
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    border: Border.all(color: AppPalette.borderLight, width: 1.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Sort: ',
                        style: AppTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppPalette.mutedZinc,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          sortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.monoStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.obsidianBlack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: AppPalette.coolSlate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Optional row of active filter chips when user applies filters
        if (activeFilterChips.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < activeFilterChips.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppPalette.background,
                      border: Border.all(color: AppPalette.borderLight, width: 1.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${activeFilterChips[i].prefix}: ',
                          style: AppTheme.monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppPalette.mutedZinc,
                          ),
                        ),
                        Text(
                          activeFilterChips[i].value,
                          style: AppTheme.monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.obsidianBlack,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => onRemoveChip(activeFilterChips[i].id),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppPalette.coolSlate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class CatalogFilterChipData {
  const CatalogFilterChipData({
    required this.id,
    required this.prefix,
    required this.value,
  });

  final String id;
  final String prefix;
  final String value;
}
