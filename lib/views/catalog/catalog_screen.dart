import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../widgets/catalog/active_exhibition_banner.dart';
import '../../widgets/catalog/catalog_bottom_nav_bar.dart';
import '../../widgets/catalog/catalog_filter_sheet.dart';
import '../../widgets/catalog/catalog_filter_sort_bar.dart';
import '../../widgets/catalog/catalog_header_section.dart';
import '../../widgets/catalog/moulding_grid_card.dart';
import '../../widgets/catalog/workshop_map_placeholder.dart';

/// The 4 sort options for the Unified Frame Catalogue.
enum CatalogSortOption {
  newest('Newest'),
  priceLowToHigh('Price (Low -> High)'),
  priceHighToLow('Price (High -> Low)'),
  profileWidth('Profile Width (mm)');

  const CatalogSortOption(this.label);

  final String label;
}

/// Screen c (`Unified Frame Catalogue`): Search, Filters, Sort, 2×2 Moulding Grid,
/// Active Exhibition Banner, and KL Workshop Map Directory Placeholder.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedTopTab = 0; // 0: Catalog, 1: Map (KL), 2: Drafts (12)
  int _selectedBottomTab = 1; // 1: Catalog
  CatalogSortOption _sortOption = CatalogSortOption.newest;
  CatalogFilterState _filterState = CatalogFilterState.empty; // Starts empty (no filter chips initially)
  bool _showMapDirectory = true;
  final Set<String> _favoritedIds = <String>{};

  static const List<CatalogMouldingItem> _mouldingItems = [
    CatalogMouldingItem(
      id: 'walnut_35',
      name: 'Walnut 35mm',
      widthMm: 35,
      rebateDepthMm: 14,
      pricePerMetreRm: 38,
      frameColor: Color(0xFF422618),
      materialClass: 'Wood (Hardwood)',
    ),
    CatalogMouldingItem(
      id: 'black_20',
      name: 'Black 20mm',
      widthMm: 20,
      rebateDepthMm: 11,
      pricePerMetreRm: 24,
      frameColor: Color(0xFF141619),
      materialClass: 'Aluminium Metal',
    ),
    CatalogMouldingItem(
      id: 'gilded_50',
      name: 'Gilded 50mm',
      widthMm: 50,
      rebateDepthMm: 25,
      pricePerMetreRm: 96,
      frameColor: Color(0xFF8C6D23),
      materialClass: 'Gilded / Foil Leaf',
    ),
    CatalogMouldingItem(
      id: 'oak_25',
      name: 'Oak 25mm',
      widthMm: 25,
      rebateDepthMm: 14,
      pricePerMetreRm: 31,
      frameColor: Color(0xFFC59B6D),
      materialClass: 'Wood (Hardwood)',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (!_favoritedIds.remove(id)) {
        _favoritedIds.add(id);
      }
    });
  }

  /// Dynamically derives the active filter chips from [_filterState].
  /// Initially empty until the user applies filters in [CatalogFilterSheet].
  List<CatalogFilterChipData> get _activeFilterChips {
    final chips = <CatalogFilterChipData>[];
    if (_filterState.materialClass != null) {
      chips.add(
        CatalogFilterChipData(
          id: 'mat',
          prefix: 'Mat',
          value: CatalogFilterState.shortMaterialName(_filterState.materialClass!),
        ),
      );
    }
    if (_filterState.maxProfileWidthMm != null) {
      chips.add(
        CatalogFilterChipData(
          id: 'width',
          prefix: 'Width',
          value: '≤ ${_filterState.maxProfileWidthMm!.round()}mm',
        ),
      );
    }
    if (_filterState.minRebateDepthMm != null) {
      chips.add(
        CatalogFilterChipData(
          id: 'rebate',
          prefix: 'Rebate',
          value: '≥ ${_filterState.minRebateDepthMm}mm',
        ),
      );
    }
    if (_filterState.maxPricePerMetreRm != null) {
      chips.add(
        CatalogFilterChipData(
          id: 'max_price',
          prefix: 'Max',
          value: '< RM${_filterState.maxPricePerMetreRm}/m',
        ),
      );
    }
    return chips;
  }

  void _removeFilterChip(String chipId) {
    setState(() {
      switch (chipId) {
        case 'mat':
          _filterState = _filterState.copyWith(clearMaterial: true);
        case 'width':
          _filterState = _filterState.copyWith(clearProfileWidth: true);
        case 'rebate':
          _filterState = _filterState.copyWith(clearRebateDepth: true);
        case 'max_price':
          _filterState = _filterState.copyWith(clearMaxPrice: true);
      }
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => CatalogFilterSheet(
        initialState: _filterState,
        onChanged: (nextState) {
          setState(() => _filterState = nextState);
        },
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                children: [
                  const Text(
                    'Sort',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
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
              const SizedBox(height: 6),
              for (final option in CatalogSortOption.values)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    option.label,
                    style: AppTheme.monoStyle(
                      fontSize: 12,
                      fontWeight:
                          _sortOption == option ? FontWeight.w800 : FontWeight.w500,
                      color: _sortOption == option
                          ? AppPalette.obsidianBlack
                          : AppPalette.coolSlate,
                    ),
                  ),
                  trailing: _sortOption == option
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppPalette.obsidianBlack,
                        )
                      : null,
                  onTap: () {
                    setState(() => _sortOption = option);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<CatalogMouldingItem> _computeVisibleItems() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _mouldingItems.where((item) {
      if (query.isNotEmpty) {
        final matchesQuery = item.name.toLowerCase().contains(query) ||
            item.materialClass.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }
      if (_filterState.materialClass != null &&
          item.materialClass != _filterState.materialClass) {
        return false;
      }
      if (_filterState.maxProfileWidthMm != null &&
          item.widthMm > _filterState.maxProfileWidthMm!) {
        return false;
      }
      if (_filterState.minRebateDepthMm != null &&
          item.rebateDepthMm < _filterState.minRebateDepthMm!) {
        return false;
      }
      if (_filterState.maxPricePerMetreRm != null &&
          item.pricePerMetreRm > _filterState.maxPricePerMetreRm!) {
        return false;
      }
      return true;
    }).toList();

    switch (_sortOption) {
      case CatalogSortOption.newest:
        break; // Keep default catalogue order
      case CatalogSortOption.priceLowToHigh:
        filtered.sort((a, b) => a.pricePerMetreRm.compareTo(b.pricePerMetreRm));
      case CatalogSortOption.priceHighToLow:
        filtered.sort((a, b) => b.pricePerMetreRm.compareTo(a.pricePerMetreRm));
      case CatalogSortOption.profileWidth:
        filtered.sort((a, b) => a.widthMm.compareTo(b.widthMm));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _computeVisibleItems();

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Top Bar + Brand Row + Segmented Tabs + Search Input
            CatalogHeaderSection(
              selectedTabIndex: _selectedTopTab,
              onTabSelected: (index) => setState(() => _selectedTopTab = index),
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              onBackTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onProfileTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile & Role settings')),
                );
              },
            ),

            // Scrollable Catalogue Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Filter & Sort Controls (starts with 0 filter chips)
                        CatalogFilterSortBar(
                          activeFilterChips: _activeFilterChips,
                          sortLabel: _sortOption.label,
                          onFiltersTap: _openFilterSheet,
                          onRemoveChip: _removeFilterChip,
                          onSortTap: _openSortSheet,
                        ),

                        const SizedBox(height: 14),

                        // 2×2 Moulding Catalogue Grid (or empty state when filtered out)
                        if (visibleItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 28,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.slateTintSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppPalette.borderLight),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.filter_alt_off_outlined,
                                  size: 26,
                                  color: AppPalette.coolSlate,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No mouldings match your active filters',
                                  style: TextStyle(
                                    color: AppPalette.obsidianBlack,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => setState(
                                    () => _filterState = CatalogFilterState.empty,
                                  ),
                                  child: Text(
                                    'Reset filters',
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppPalette.midnightSlate,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visibleItems.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];
                              return MouldingGridCard(
                                item: item,
                                isFavorited: _favoritedIds.contains(item.id),
                                onFavoriteToggle: () => _toggleFavorite(item.id),
                                onAddTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Selected ${item.name} (RM ${item.pricePerMetreRm}/m)',
                                      ),
                                    ),
                                  );
                                },
                                onCardTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${item.name} — RM ${item.pricePerMetreRm}/m',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 16),

                        // Active Exhibition: KL Spring Show (Dashed Banner)
                        ActiveExhibitionBanner(
                          onInspectDraftTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Inspect Draft — Active Exhibition: KL Spring Show',
                                ),
                              ),
                            );
                          },
                        ),

                        if (_showMapDirectory) ...[
                          const SizedBox(height: 16),

                          // KL Workshop Map Directory Placeholder Card
                          WorkshopMapPlaceholder(
                            onCloseTap: () =>
                                setState(() => _showMapDirectory = false),
                            onMapTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Map placeholder — ready for teammate\'s Google Maps widget',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CatalogBottomNavBar(
        currentIndex: _selectedBottomTab,
        onTabSelected: (index) {
          if (index == 0 && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          setState(() => _selectedBottomTab = index);
        },
        onCenterAddTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick Add Action (+)')),
          );
        },
      ),
    );
  }
}
