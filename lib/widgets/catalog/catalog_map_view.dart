import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import 'moulding_grid_card.dart';

/// Full `Map (KL)` directory view (`Catalog - Map`, matching Image 2),
/// displayed when the user taps the `Map (KL)` top tab or clicks the
/// `KL Workshop Map Directory` card at the bottom of `CatalogScreen`.
class CatalogMapView extends StatefulWidget {
  const CatalogMapView({
    super.key,
    this.selectedMoulding,
    required this.onRouteToOrderTap,
  });

  final CatalogMouldingItem? selectedMoulding;
  final VoidCallback onRouteToOrderTap;

  @override
  State<CatalogMapView> createState() => _CatalogMapViewState();
}

class _CatalogMapViewState extends State<CatalogMapView> {
  final Set<String> _activeFilters = {'< 10 km'};

  void _toggleFilter(String label) {
    setState(() {
      if (!_activeFilters.remove(label)) {
        _activeFilters.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final moulding = widget.selectedMoulding;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Horizontal Map Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    _MapFilterPill(
                      icon: Icons.access_time_rounded,
                      label: 'Open now',
                      selected: _activeFilters.contains('Open now'),
                      onTap: () => _toggleFilter('Open now'),
                    ),
                    const SizedBox(width: 8),
                    _MapFilterPill(
                      icon: Icons.layers_outlined,
                      label: 'Bulk orders',
                      selected: _activeFilters.contains('Bulk orders'),
                      onTap: () => _toggleFilter('Bulk orders'),
                    ),
                    const SizedBox(width: 8),
                    _MapFilterPill(
                      icon: Icons.track_changes_rounded,
                      label: '< 10 km',
                      selected: _activeFilters.contains('< 10 km'),
                      onTap: () => _toggleFilter('< 10 km'),
                    ),
                    const SizedBox(width: 8),
                    _MapFilterPill(
                      icon: Icons.verified_outlined,
                      label: 'Museum glass',
                      selected: _activeFilters.contains('Museum glass'),
                      onTap: () => _toggleFilter('Museum glass'),
                    ),
                  ],
                ),
              ),

              // 2. Interactive Stylized KL Map Canvas (Image 2 top half)
              SizedBox(
                height: 310,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(
                      painter: _FullKlDirectoryMapPainter(),
                    ),

                    // Top-center technical coordinate badge
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.background.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PROJECTION EPSG:3857 // WGS84',
                            style: AppTheme.monoStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.coolSlate,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // District Labels
                    Positioned(
                      top: 52,
                      left: 34,
                      child: Text(
                        'DAMANSARA HEIGHTS',
                        style: AppTheme.monoStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.coolSlate.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 46,
                      right: 54,
                      child: Text(
                        'AMPANG DIPLOMATIC',
                        style: AppTheme.monoStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.coolSlate.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 184,
                      left: 56,
                      child: Text(
                        'LEBUHRAYA PANTAI BARU (NPE)',
                        style: AppTheme.monoStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.coolSlate.withValues(alpha: 0.75),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),

                    // Secondary Callout Card: Ampang Artisan (top-right)
                    Positioned(
                      top: 52,
                      right: 56,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.obsidianBlack.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.handyman_outlined,
                              size: 14,
                              color: AppPalette.darkCharcoal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ampang\nArtisan\n(12.4 km)',
                              style: AppTheme.monoStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.obsidianBlack,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Active Dark Callout Pin: Atelier Bangsar (4.2 km)
                    Positioned(
                      top: 94,
                      left: 112,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.obsidianBlack,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.obsidianBlack.withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.palette_outlined,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  moulding != null
                                      ? '${moulding.workshopName}\n(${moulding.name})'
                                      : 'Atelier Bangsar (4.2\nkm)',
                                  style: AppTheme.monoStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // GPS Bullseye + "GPS: You are here (Bangsar)"
                    Positioned(
                      top: 140,
                      left: 68,
                      child: Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppPalette.obsidianBlack.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppPalette.obsidianBlack,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.background.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GPS: You are here (Bangsar)',
                              style: AppTheme.monoStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.obsidianBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom-left [4] PJ Cluster pill
                    Positioned(
                      bottom: 62,
                      left: 28,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE4F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppPalette.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppPalette.obsidianBlack,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '4',
                                style: AppTheme.monoStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PJ Cluster',
                              style: AppTheme.monoStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.obsidianBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom-right Callout Card: Cheras Framing Hub (9.0 km)
                    Positioned(
                      bottom: 44,
                      right: 54,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.obsidianBlack.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.work_outline_rounded,
                              size: 14,
                              color: AppPalette.darkCharcoal,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Cheras\nFraming\nHub (9.0\nkm)',
                              style: AppTheme.monoStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.obsidianBlack,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Floating Map Controls: [ ◎ ] [ + ] [ - ]
                    Positioned(
                      top: 20,
                      right: 14,
                      child: Column(
                        children: [
                          _MapControlIconBtn(
                            icon: Icons.my_location_rounded,
                            onTap: () {},
                          ),
                          const SizedBox(height: 6),
                          _MapControlIconBtn(
                            icon: Icons.add_rounded,
                            onTap: () {},
                          ),
                          const SizedBox(height: 1),
                          _MapControlIconBtn(
                            icon: Icons.remove_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    // Bottom-left Scale Bar: 1:2500 ─── 500m
                    Positioned(
                      bottom: 12,
                      left: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.background.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '1:2500',
                              style: AppTheme.monoStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.coolSlate,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 28,
                              height: 3,
                              color: AppPalette.mutedZinc,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '500m',
                              style: AppTheme.monoStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.coolSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Bottom Verified Workshops Sheet / Directory Panel
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: const BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle pill
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppPalette.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header: ● 3 Verified Workshops near Bangsar | Distance: Nearest ⇅
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppPalette.obsidianBlack,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '3 Verified Workshops near\nBangsar',
                            style: TextStyle(
                              color: AppPalette.obsidianBlack,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Text(
                          'Distance:\nNearest',
                          style: AppTheme.monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.coolSlate,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.swap_vert_rounded,
                          size: 18,
                          color: AppPalette.obsidianBlack,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Card 1: ATELIER 01 — Atelier Bangsar Woodcraft
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.slateTintSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppPalette.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.obsidianBlack,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'ATELIER 01',
                                  style: AppTheme.monoStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '4.2 km',
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppPalette.darkCharcoal,
                                    ),
                                  ),
                                  Text(
                                    'Est. 2011',
                                    style: AppTheme.monoStyle(
                                      fontSize: 9.5,
                                      color: AppPalette.mutedZinc,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Atelier Bangsar Woodcraft',
                            style: TextStyle(
                              color: AppPalette.obsidianBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Lot 14, Jalan Telawi 2, Bangsar,\n59100 Kuala Lumpur',
                            style: TextStyle(
                              color: AppPalette.coolSlate,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: const [
                              _WorkshopTagChip(
                                label: '● Open till 18:00',
                                backgroundColor: AppPalette.background,
                              ),
                              _WorkshopTagChip(
                                label: '🕒 Lead time: ~10 days',
                                backgroundColor: AppPalette.background,
                              ),
                              _WorkshopTagChip(
                                label: 'Grade A Workshop',
                                backgroundColor: Color(0xFFDCE4F2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: const [
                              _WorkshopTagChip(
                                label: '🛡 Museum Glass Certified',
                                backgroundColor: AppPalette.background,
                              ),
                              _WorkshopTagChip(
                                label: '% Bulk Discount Tiers',
                                backgroundColor: AppPalette.background,
                              ),
                              _WorkshopTagChip(
                                label: '⚄ 3D Float Mount',
                                backgroundColor: AppPalette.background,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // PRICING SPECS inner box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.background,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRICING SPECS',
                                      style: AppTheme.monoStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.mutedZinc,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Mouldings from RM 24/m',
                                      style: TextStyle(
                                        color: AppPalette.obsidianBlack,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_offer_outlined,
                                      size: 13,
                                      color: AppPalette.obsidianBlack,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bulk up to -20%',
                                      style: AppTheme.monoStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppPalette.obsidianBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Action Buttons Row: [ ⓘ View Workshop Detail ] [ Route to Order → ]
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Atelier Bangsar Woodcraft — Workshop Details',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 15,
                                      color: AppPalette.obsidianBlack,
                                    ),
                                    label: const Text(
                                      'View Workshop Detail',
                                      style: TextStyle(
                                        color: AppPalette.obsidianBlack,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppPalette.background,
                                      side: const BorderSide(
                                        color: AppPalette.borderLight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: widget.onRouteToOrderTap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppPalette.obsidianBlack,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Route to Order',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card 2: ATELIER 02 — Cheras Fine Mouldings & Gilded Arts
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppPalette.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCE4F2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'ATELIER 02',
                                  style: AppTheme.monoStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppPalette.obsidianBlack,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '9.0 km',
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppPalette.darkCharcoal,
                                    ),
                                  ),
                                  Text(
                                    'Lead ~7d',
                                    style: AppTheme.monoStyle(
                                      fontSize: 9.5,
                                      color: AppPalette.mutedZinc,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Cheras Fine Mouldings & Gilded Arts',
                            style: TextStyle(
                              color: AppPalette.obsidianBlack,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Jalan Cheras Hartamas, 56100 Kuala Lumpur',
                            style: TextStyle(
                              color: AppPalette.coolSlate,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: const [
                              _WorkshopTagChip(
                                label: 'Open till 19:30',
                                backgroundColor: AppPalette.background,
                              ),
                              _WorkshopTagChip(
                                label: 'Standard Glazing',
                                backgroundColor: AppPalette.background,
                              ),
                              _WorkshopTagChip(
                                label: 'Archival Core',
                                backgroundColor: AppPalette.background,
                              ),
                              _WorkshopTagChip(
                                label: 'Custom Mitre',
                                backgroundColor: AppPalette.background,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Direct specs dispatch active',
                                style: AppTheme.monoStyle(
                                  fontSize: 10,
                                  color: AppPalette.mutedZinc,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.background,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppPalette.borderLight,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'View',
                                        style: TextStyle(
                                          color: AppPalette.obsidianBlack,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 15,
                                        color: AppPalette.obsidianBlack,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFilterPill extends StatelessWidget {
  const _MapFilterPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : fallbackIcon = null;

  final IconData icon;
  final IconData? fallbackIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppPalette.obsidianBlack : AppPalette.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppPalette.obsidianBlack : AppPalette.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fallbackIcon ?? icon,
              size: 14,
              color: selected ? Colors.white : AppPalette.coolSlate,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.monoStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppPalette.obsidianBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlIconBtn extends StatelessWidget {
  const _MapControlIconBtn({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.background,
      borderRadius: BorderRadius.circular(4),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 17,
            color: AppPalette.obsidianBlack,
          ),
        ),
      ),
    );
  }
}

class _WorkshopTagChip extends StatelessWidget {
  const _WorkshopTagChip({
    required this.label,
    required this.backgroundColor,
  });

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTheme.monoStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppPalette.obsidianBlack,
        ),
      ),
    );
  }
}

class _FullKlDirectoryMapPainter extends CustomPainter {
  const _FullKlDirectoryMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Light blue-slate map canvas background matching Image 2
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF1F5FA),
    );

    // Subtle arterial highway curves
    final highway = Paint()
      ..color = const Color(0xFFD6E0EE)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final p1 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.44, size.height);
    canvas.drawPath(p1, highway);

    final p2 = Path()
      ..moveTo(0, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.58,
        size.width,
        size.height * 0.65,
      );
    canvas.drawPath(p2, highway);

    // Dashed route triangle connecting Bangsar -> Ampang -> Cheras
    final routePaint = Paint()
      ..color = AppPalette.mutedZinc.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(size.width * 0.35, size.height * 0.48),
      Offset(size.width * 0.62, size.height * 0.16),
      routePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(size.width * 0.62, size.height * 0.16),
      Offset(size.width * 0.85, size.height * 0.25),
      routePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(size.width * 0.35, size.height * 0.48),
      Offset(size.width * 0.82, size.height * 0.86),
      routePaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dx = (b.dx - a.dx) / total;
    final dy = (b.dy - a.dy) / total;
    var cur = 0.0;
    while (cur < total) {
      final next = (cur + dash).clamp(0.0, total);
      canvas.drawLine(
        Offset(a.dx + dx * cur, a.dy + dy * cur),
        Offset(a.dx + dx * next, a.dy + dy * next),
        paint,
      );
      cur += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
