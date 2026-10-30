import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/catalog_moulding.dart';
import '../../models/vendor.dart';
import '../../view_models/exhibit_viewmodel.dart';
import '../../widgets/catalog/catalog_bottom_nav_bar.dart';
import '../../widgets/catalog/catalog_filter_sheet.dart';
import '../../widgets/catalog/catalog_filter_sort_bar.dart';
import '../../widgets/catalog/catalog_header_section.dart';
import '../../widgets/catalog/catalog_map_view.dart';
import '../../widgets/catalog/moulding_grid_card.dart';
import '../../widgets/catalog/workshop_map_placeholder.dart';
import '../../widgets/exhibit/draft_card.dart';
import '../auth/auth_navigation.dart';
import '../auth/login_screen.dart';
import '../editor_screen.dart';
import '../exhibit_room_screen.dart';
import '../exhibit_screen.dart';
import '../mouldings/my_mouldings_screen.dart';
import '../orders/my_orders_screen.dart';

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
/// KL Workshop Map Directory Placeholder, and `Catalog - Map (KL)` Directory View.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _catalogScrollController = ScrollController();

  int _selectedTopTab = 0; // 0: Catalog, 1: Map (KL), 2: Drafts (12)
  int _selectedBottomTab = 1; // 1: Catalog
  CatalogSortOption _sortOption = CatalogSortOption.newest;
  CatalogFilterState _filterState = CatalogFilterState.empty; // Starts empty
  bool _showMapDirectory = true;
  CatalogMouldingItem? _selectedMoulding;

  late final _deps = AppScope.of(context);
  late final Stream<List<CatalogMoulding>> _mouldings = _deps.mouldings.watchMouldings();
  late final Stream<List<Vendor>> _vendors = _deps.vendors.watchVendors();

  /// The user's drafts, for the Drafts tab.
  late final ExhibitViewModel _drafts = ExhibitViewModel(
    auth: _deps.auth,
    drafts: _deps.drafts,
    artworkStorage: _deps.artworkStorage,
  );

  @override
  void dispose() {
    _drafts.dispose();
    _searchController.dispose();
    _catalogScrollController.dispose();
    super.dispose();
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

  List<CatalogMouldingItem> _computeVisibleItems(List<CatalogMouldingItem> all) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = all.where((item) {
      if (query.isNotEmpty) {
        final matchesQuery = item.name.toLowerCase().contains(query) ||
            item.materialClass.toLowerCase().contains(query) ||
            item.workshopName.toLowerCase().contains(query);
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
        break; // The repository already lists newest first
      case CatalogSortOption.priceLowToHigh:
        filtered.sort((a, b) => a.pricePerMetreRm.compareTo(b.pricePerMetreRm));
      case CatalogSortOption.priceHighToLow:
        filtered.sort((a, b) => b.pricePerMetreRm.compareTo(a.pricePerMetreRm));
      case CatalogSortOption.profileWidth:
        filtered.sort((a, b) => a.widthMm.compareTo(b.widthMm));
    }

    return filtered;
  }

  void _onMouldingCardTap(CatalogMouldingItem item) {
    setState(() {
      _selectedMoulding = item;
      _showMapDirectory = true;
    });

    // Smoothly scroll down so the user immediately sees the frame's workshop on the map card
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_catalogScrollController.hasClients) {
        _catalogScrollController.animateTo(
          _catalogScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _openEditor([CatalogMouldingItem? item]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(catalogMoulding: item?.moulding)),
    );
  }

  /// Account menu: who is signed in, the shop's own mouldings, sign in/out.
  void _openProfileSheet() {
    final user = _deps.auth.currentUser;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppPalette.background,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user == null
                  ? 'Not signed in'
                  : (user.displayName.isNotEmpty ? user.displayName : user.email)),
              subtitle: user?.role == null ? null : Text(user!.role!.label),
            ),
            if (user?.vendorId != null)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('My mouldings'),
                subtitle: const Text('Add and edit what your shop sells'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyMouldingsScreen()));
                },
              ),
            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Log in'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await signOutAndReturnToWelcome(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Grid columns for the available width: 2 on phones, more on tablets.
  static int _columnsFor(double width) => (width / 220).floor().clamp(2, 6);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Vendor>>(
      stream: _vendors,
      builder: (context, vendorSnapshot) => StreamBuilder<List<CatalogMoulding>>(
        stream: _mouldings,
        builder: (context, mouldingSnapshot) => ListenableBuilder(
          listenable: _drafts,
          builder: (context, _) => _buildScaffold(vendorSnapshot, mouldingSnapshot),
        ),
      ),
    );
  }

  Widget _buildScaffold(
    AsyncSnapshot<List<Vendor>> vendorSnapshot,
    AsyncSnapshot<List<CatalogMoulding>> mouldingSnapshot,
  ) {
    final vendors = vendorSnapshot.data ?? const <Vendor>[];
    final vendorById = {for (final v in vendors) v.id: v};
    final allItems = [
      for (final m in mouldingSnapshot.data ?? const <CatalogMoulding>[])
        CatalogMouldingItem.fromMoulding(m, vendorById[m.vendorId]),
    ];
    final selected = switch (_selectedMoulding) {
      final s? => allItems.where((item) => item.id == s.id).firstOrNull,
      null => null,
    };

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Top Bar + Brand Row + Segmented Tabs + Search Input
            CatalogHeaderSection(
              selectedTabIndex: _selectedTopTab,
              draftCount: _drafts.user == null ? null : _drafts.drafts?.length,
              onTabSelected: (index) => setState(() => _selectedTopTab = index),
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              onBackTap: () {
                if (_selectedTopTab != 0) {
                  setState(() => _selectedTopTab = 0);
                  return;
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onProfileTap: _openProfileSheet,
            ),

            Expanded(
              child: switch (_selectedTopTab) {
                1 => CatalogMapView(
                    vendors: vendors,
                    items: allItems,
                    selectedMoulding: selected,
                    onOpenMoulding: _openEditor,
                  ),
                2 => _buildDraftsTab(),
                _ => _buildCatalogTab(
                    allItems,
                    selected,
                    vendors.length,
                    loading: !mouldingSnapshot.hasData && !mouldingSnapshot.hasError,
                    failed: mouldingSnapshot.hasError,
                  ),
              },
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
          if (index == 1 && _selectedTopTab != 0) {
            setState(() => _selectedTopTab = 0);
            return;
          }
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExhibitScreen()),
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            );
            return;
          }
          setState(() => _selectedBottomTab = index);
        },
        onCenterAddTap: _openEditor,
      ),
    );
  }

  Widget _buildCatalogTab(
    List<CatalogMouldingItem> allItems,
    CatalogMouldingItem? selected,
    int workshopCount, {
    required bool loading,
    required bool failed,
  }) {
    final visibleItems = _computeVisibleItems(allItems);
    return SingleChildScrollView(
      controller: _catalogScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
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

              if (loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (failed || visibleItems.isEmpty)
                _EmptyCatalog(
                  icon: failed
                      ? Icons.cloud_off_outlined
                      : (allItems.isEmpty ? Icons.inventory_2_outlined : Icons.filter_alt_off_outlined),
                  message: failed
                      ? "Couldn't load the catalogue. Check your connection."
                      : allItems.isEmpty
                          ? 'No mouldings listed yet. Frame shops add theirs from the profile menu.'
                          : 'No mouldings match your active filters',
                  onReset: allItems.isEmpty || failed
                      ? null
                      : () => setState(() => _filterState = CatalogFilterState.empty),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _columnsFor(constraints.maxWidth),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      return MouldingGridCard(
                        item: item,
                        isSelected: selected?.id == item.id,
                        onAddTap: () => _openEditor(item),
                        onCardTap: () => _onMouldingCardTap(item),
                      );
                    },
                  ),
                ),

              if (_showMapDirectory) ...[
                const SizedBox(height: 16),

                // KL Workshop Map Directory Card:
                // - Shows origin workshop when a moulding card is clicked
                // - Clicking the map opens the full Map (KL) view
                WorkshopMapPlaceholder(
                  selectedMoulding: selected,
                  workshopCount: workshopCount,
                  onCloseTap: () => setState(() {
                    _showMapDirectory = false;
                    _selectedMoulding = null;
                  }),
                  onMapTap: () {
                    setState(() => _selectedTopTab = 1);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The user's saved drafts; tapping one hangs it in the Exhibit room.
  Widget _buildDraftsTab() {
    final drafts = _drafts.drafts;
    if (_drafts.userKnown && _drafts.user == null) {
      return const _EmptyCatalog(icon: Icons.lock_outline, message: 'Sign in to see your saved drafts.');
    }
    if (_drafts.error != null) {
      return const _EmptyCatalog(icon: Icons.cloud_off_outlined, message: "Couldn't load your drafts.");
    }
    if (drafts == null) return const Center(child: CircularProgressIndicator());
    if (drafts.isEmpty) {
      return const _EmptyCatalog(
        icon: Icons.collections_outlined,
        message: 'No saved drafts yet. Frame an artwork with + and tap Save.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columnsFor(constraints.maxWidth),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: drafts.length,
        itemBuilder: (context, i) => DraftCard(
          viewModel: _drafts,
          draft: drafts[i],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ExhibitRoomScreen(exhibit: _drafts, drafts: [drafts[i]]),
          )),
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.icon, required this.message, this.onReset});

  final IconData icon;
  final String message;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppPalette.slateTintSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: AppPalette.coolSlate),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.obsidianBlack,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReset,
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
        ],
      ),
    );
  }
}
