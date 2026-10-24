import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Top header, brand bar, 3-segment view switcher (`Catalog` / `Map (KL)` / `Drafts (12)`),
/// and search bar for Screen c (`CatalogScreen`).
///
/// Red-circled wireframe clutter (`SPEC 01 // RAW`, top-right filter icon,
/// `/ CATALOG ENGINE`, `KL WORKSHOPS`, `@curator`) has been removed per requirements.
class CatalogHeaderSection extends StatelessWidget {
  const CatalogHeaderSection({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBackTap,
    required this.onProfileTap,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBackTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top App Bar: <- Catalog ... [Profile Circle]
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppPalette.surfaceLight,
            border: Border(
              bottom: BorderSide(color: AppPalette.borderLight, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBackTap,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppPalette.obsidianBlack,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 8),
              const Text(
                'Catalog',
                style: TextStyle(
                  color: AppPalette.obsidianBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // Profile circle button
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppPalette.obsidianBlack,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Clean Brand Row: [A] Pick A-Frame PRECISION FRAMING
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppPalette.background,
            border: Border(
              bottom: BorderSide(color: AppPalette.borderLight, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  border: Border.all(color: AppPalette.obsidianBlack, width: 2),
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: AppPalette.obsidianBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pick A-Frame',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'PRECISION FRAMING',
                    style: AppTheme.monoStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.mutedZinc,
                      letterSpacing: 1.0,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Segmented Switcher + Search Bar inside padded body header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3-Tab Segmented Switcher: [ Catalog ] | Map (KL) | Drafts (12)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppPalette.slateTintSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentedTabButton(
                        icon: Icons.grid_view_rounded,
                        label: 'Catalog',
                        selected: selectedTabIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                    ),
                    Expanded(
                      child: _SegmentedTabButton(
                        icon: Icons.map_outlined,
                        label: 'Map (KL)',
                        selected: selectedTabIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                    ),
                    Expanded(
                      child: _SegmentedTabButton(
                        icon: Icons.folder_special_outlined,
                        label: 'Drafts (12)',
                        selected: selectedTabIndex == 2,
                        onTap: () => onTabSelected(2),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Input Box
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  border: Border.all(color: AppPalette.borderLight, width: 1.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppPalette.mutedZinc,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: const TextStyle(
                          color: AppPalette.obsidianBlack,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: AppPalette.mutedZinc,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentedTabButton extends StatelessWidget {
  const _SegmentedTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppPalette.background : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppPalette.obsidianBlack.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppPalette.obsidianBlack : AppPalette.coolSlate,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.monoStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppPalette.obsidianBlack : AppPalette.coolSlate,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
