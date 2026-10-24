import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../models/vendor.dart';

/// Featured KL framing workshops horizontal carousel on the Landing Page.
///
/// Streams live data from `AppScope.of(context).vendors.watchVendors()`.
/// When the repository is empty (default in-memory startup), it displays
/// curated Kuala Lumpur showcase cards matching the wireframe (`Atelier Bangsar
/// Woodcraft`, `Cheras Fine Moulding`, `Publika Conservation Studio`) without
/// modifying any repository or model files.
class WorkshopCarousel extends StatelessWidget {
  const WorkshopCarousel({
    super.key,
    required this.onViewAllTap,
    required this.onWorkshopTap,
  });

  final VoidCallback onViewAllTap;
  final void Function(WorkshopPreviewData workshop) onWorkshopTap;

  static const List<WorkshopPreviewData> _fallbackWorkshops = [
    WorkshopPreviewData(
      id: 'atelier_bangsar',
      name: 'Atelier Bangsar Woodcraft',
      districtAndDistance: 'Bangsar · 4.2 km',
      specialties: ['Museum Glass', 'Bulk Tiers'],
      textureAsset: 'assets/textures/wood/oak_veneer_01.jpg',
      accentColor: AppPalette.midnightSlate,
    ),
    WorkshopPreviewData(
      id: 'cheras_fine_moulding',
      name: 'Cheras Fine Moulding',
      districtAndDistance: 'Cheras · 9.1 km',
      specialties: ['Archival Core', 'Fast Turnaround'],
      textureAsset: 'assets/textures/wood/teak_veneer.jpg',
      accentColor: AppPalette.darkCharcoal,
    ),
    WorkshopPreviewData(
      id: 'publika_gilding_house',
      name: 'Publika Gilding & Frame',
      districtAndDistance: 'Solaris Dutamas · 6.4 km',
      specialties: ['Ornate Leaf', 'Shadow Boxes'],
      textureAsset: 'assets/mouldings/ornate_gold_scroll.jpg',
      accentColor: AppPalette.coolSlate,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vendorRepo = AppScope.of(context).vendors;

    return StreamBuilder<List<Vendor>>(
      stream: vendorRepo.watchVendors(),
      builder: (context, snapshot) {
        final liveVendors = snapshot.data ?? const <Vendor>[];
        final items = liveVendors.isNotEmpty
            ? liveVendors.map(WorkshopPreviewData.fromVendor).toList()
            : _fallbackWorkshops;
        final totalCount = liveVendors.isNotEmpty ? liveVendors.length : 14;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row: Featured KL framing workshops | All (14) ->
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Featured KL framing workshops',
                    style: TextStyle(
                      color: AppPalette.obsidianBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onViewAllTap,
                  borderRadius: BorderRadius.circular(3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'All ($totalCount)',
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.obsidianBlack,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppPalette.obsidianBlack,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Horizontal scrolling workshop cards
            SizedBox(
              height: 222,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final workshop = items[index];
                  return _WorkshopCard(
                    workshop: workshop,
                    onViewTap: () => onWorkshopTap(workshop),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class WorkshopPreviewData {
  const WorkshopPreviewData({
    required this.id,
    required this.name,
    required this.districtAndDistance,
    required this.specialties,
    required this.textureAsset,
    required this.accentColor,
  });

  final String id;
  final String name;
  final String districtAndDistance;
  final List<String> specialties;
  final String textureAsset;
  final Color accentColor;

  factory WorkshopPreviewData.fromVendor(Vendor vendor) {
    return WorkshopPreviewData(
      id: vendor.id,
      name: vendor.name,
      districtAndDistance: vendor.address,
      specialties: vendor.specialties.isNotEmpty
          ? vendor.specialties
          : const ['Custom Framing', 'KL Directory'],
      textureAsset: 'assets/textures/wood/oak_veneer_01.jpg',
      accentColor: AppPalette.midnightSlate,
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  const _WorkshopCard({
    required this.workshop,
    required this.onViewTap,
  });

  final WorkshopPreviewData workshop;
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.background,
        border: Border.all(color: AppPalette.borderLight, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workshop Banner Image
          SizedBox(
            height: 82,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Rich wood/moulding texture backdrop from bundled assets
                ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: Image.asset(
                    workshop.textureAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: workshop.accentColor),
                  ),
                ),
                // Architectural workshop studio overlay gradient + craft illustration
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppPalette.obsidianBlack.withValues(alpha: 0.25),
                        AppPalette.darkCharcoal.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
                // Subtle workshop bench / moulding rack graphic icon in bottom-right
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.carpenter_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.straighten_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          // Workshop Name
          Text(
            workshop.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.obsidianBlack,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 2),

          // District & Distance
          Text(
            workshop.districtAndDistance,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.mutedZinc,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 7),

          // Specialty Tags (e.g., Museum Glass, Bulk Tiers)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < workshop.specialties.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppPalette.slateTintSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      workshop.specialties[i],
                      style: AppTheme.monoStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.midnightSlate,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          const Divider(height: 10, thickness: 0.8, color: AppPalette.borderLight),

          // Bottom row: [ View ] aligned to right
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 26,
              child: OutlinedButton(
                onPressed: onViewTap,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppPalette.background,
                  foregroundColor: AppPalette.obsidianBlack,
                  side: const BorderSide(color: AppPalette.obsidianBlack, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                child: Text(
                  '[ View ]',
                  style: AppTheme.monoStyle(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.obsidianBlack,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
