import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/app_theme.dart';
import '../../models/vendor.dart';
import 'moulding_grid_card.dart';

/// Map (KL) tab: every listed workshop as a pin on Google Maps, with the
/// chosen workshop's details and mouldings beside (wide screens) or below.
class CatalogMapView extends StatefulWidget {
  const CatalogMapView({
    super.key,
    required this.vendors,
    required this.items,
    required this.onOpenMoulding,
    this.selectedMoulding,
  });

  final List<Vendor> vendors;

  /// Catalogue cards, to list each workshop's mouldings.
  final List<CatalogMouldingItem> items;

  /// Opens the editor with a moulding.
  final ValueChanged<CatalogMouldingItem> onOpenMoulding;

  /// Starts on this moulding's workshop.
  final CatalogMouldingItem? selectedMoulding;

  @override
  State<CatalogMapView> createState() => _CatalogMapViewState();
}

class _CatalogMapViewState extends State<CatalogMapView> {
  static const _klCentre = LatLng(3.1390, 101.6869);

  // Same platforms as the sign-up venue picker.
  static final _mapsSupported = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  GoogleMapController? _map;
  late String? _selectedId = widget.selectedMoulding?.moulding?.vendorId;

  Vendor? get _selected {
    for (final vendor in widget.vendors) {
      if (vendor.id == _selectedId) return vendor;
    }
    return null;
  }

  void _select(Vendor vendor) {
    setState(() => _selectedId = vendor.id);
    _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(vendor.latitude, vendor.longitude), 14));
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final map = _mapsSupported ? _buildMap() : const _MapUnavailable();
        final panel = _Panel(
          vendors: widget.vendors,
          selected: _selected,
          items: widget.items,
          onSelect: _select,
          onBack: () => setState(() => _selectedId = null),
          onOpenMoulding: widget.onOpenMoulding,
        );
        if (wide) {
          return Row(
            children: [
              Expanded(child: map),
              const VerticalDivider(width: 1, color: AppPalette.borderLight),
              SizedBox(width: 360, child: panel),
            ],
          );
        }
        return Column(
          children: [
            Expanded(flex: 5, child: map),
            const Divider(height: 1, color: AppPalette.borderLight),
            Expanded(flex: 4, child: panel),
          ],
        );
      },
    );
  }

  Widget _buildMap() {
    final selected = _selected;
    return GoogleMap(
      initialCameraPosition: selected == null
          ? const CameraPosition(target: _klCentre, zoom: 11)
          : CameraPosition(target: LatLng(selected.latitude, selected.longitude), zoom: 14),
      onMapCreated: (controller) => _map = controller,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      markers: {
        for (final vendor in widget.vendors)
          Marker(
            markerId: MarkerId(vendor.id),
            position: LatLng(vendor.latitude, vendor.longitude),
            infoWindow: InfoWindow(title: vendor.name, snippet: vendor.address),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              vendor.id == _selectedId ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
            ),
            onTap: () => _select(vendor),
          ),
      },
    );
  }
}

/// The workshop list, or one workshop's details and mouldings.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.vendors,
    required this.selected,
    required this.items,
    required this.onSelect,
    required this.onBack,
    required this.onOpenMoulding,
  });

  final List<Vendor> vendors;
  final Vendor? selected;
  final List<CatalogMouldingItem> items;
  final ValueChanged<Vendor> onSelect;
  final VoidCallback onBack;
  final ValueChanged<CatalogMouldingItem> onOpenMoulding;

  @override
  Widget build(BuildContext context) {
    final vendor = selected;
    if (vendor == null) {
      if (vendors.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No workshops listed yet. Frame shops appear here after they sign up.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.coolSlate),
            ),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vendors.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppPalette.borderLight),
        itemBuilder: (context, i) {
          final v = vendors[i];
          final count = items.where((item) => item.moulding?.vendorId == v.id).length;
          return ListTile(
            leading: const Icon(Icons.storefront_outlined, color: AppPalette.midnightSlate),
            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${v.address}\n$count ${count == 1 ? 'moulding' : 'mouldings'}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            onTap: () => onSelect(v),
          );
        },
      );
    }

    final own = items.where((item) => item.moulding?.vendorId == vendor.id).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'All workshops',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                vendor.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppPalette.obsidianBlack),
              ),
            ),
          ],
        ),
        Text(vendor.address, style: const TextStyle(color: AppPalette.coolSlate)),
        if (vendor.phone case final phone?) Text(phone, style: const TextStyle(color: AppPalette.coolSlate)),
        if (vendor.specialties.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final s in vendor.specialties) Chip(label: Text(s), visualDensity: VisualDensity.compact)],
          ),
        ],
        const SizedBox(height: 12),
        Text(
          own.isEmpty ? 'No mouldings listed yet.' : 'Mouldings',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppPalette.obsidianBlack),
        ),
        for (final item in own)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(border: Border.all(color: item.frameColor, width: 6)),
            ),
            title: Text(item.name),
            subtitle: Text('${item.materialClass} · RM ${item.pricePerMetreRm}/m'),
            trailing: IconButton(
              tooltip: 'Frame with this',
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () => onOpenMoulding(item),
            ),
          ),
      ],
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppPalette.slateTintSurface,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'The map is available in the Android and iOS apps. The workshop list still works here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppPalette.coolSlate),
          ),
        ),
      ),
    );
  }
}
