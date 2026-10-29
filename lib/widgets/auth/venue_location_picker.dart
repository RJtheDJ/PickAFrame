import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/app_theme.dart';

/// A venue location chosen on the map, with its street address.
class PickedLocation {
  const PickedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
}

/// Sign-up section 02C: search an address, use the phone's location, or tap
/// the Google Map to drop the venue pin. Reports every change (null when
/// cleared) through [onChanged].
///
/// Search and street addresses use the phone's built-in geocoder (Google's
/// on Android), so only the Maps SDK needs an API key.
class VenueLocationPicker extends StatefulWidget {
  const VenueLocationPicker({super.key, required this.onChanged});

  final ValueChanged<PickedLocation?> onChanged;

  @override
  State<VenueLocationPicker> createState() => _VenueLocationPickerState();
}

class _VenueLocationPickerState extends State<VenueLocationPicker> {
  static const _klCentre = LatLng(3.1390, 101.6869);

  final _searchController = TextEditingController();
  final _geocoding = Geocoding();
  GoogleMapController? _map;
  PickedLocation? _picked;
  bool _busy = false;

  /// google_maps_flutter only supports Android and iOS here (web needs its
  /// own key setup), so other platforms show a notice instead of crashing.
  bool get _mapSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _searchController.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _locate(
      () async {
        final results = await _geocoding.locationFromAddress(query);
        return LatLng(results.first.latitude, results.first.longitude);
      },
      failureMessage: 'Could not find that place. Try a fuller address.',
    );
  }

  Future<void> _useCurrentLocation() async {
    await _locate(
      () async {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw const _LocationError('Turn on location services first.');
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw const _LocationError('Location permission was denied.');
        }
        final position = await Geolocator.getCurrentPosition();
        return LatLng(position.latitude, position.longitude);
      },
      failureMessage: 'Could not get your current location.',
    );
  }

  Future<void> _pinAt(LatLng point) =>
      _locate(() async => point, failureMessage: 'Could not place the pin.');

  /// Finds a point, moves the pin and camera there, and looks up its address.
  Future<void> _locate(
    Future<LatLng> Function() find, {
    required String failureMessage,
  }) async {
    setState(() => _busy = true);
    try {
      final point = await find();
      final picked = PickedLocation(
        address: await _addressAt(point),
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      setState(() => _picked = picked);
      widget.onChanged(picked);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    } on _LocationError catch (e) {
      _showError(e.message);
    } on Exception {
      _showError(failureMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Street address for [point]; falls back to the coordinates.
  Future<String> _addressAt(LatLng point) async {
    final coordinates =
        '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    try {
      final places = await _geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (places.isEmpty) return coordinates;
      final place = places.first;
      final parts = <String>{
        for (final part in [
          place.street,
          place.subLocality,
          place.postalCode,
          place.locality,
          place.administrativeArea,
        ])
          if (part != null && part.isNotEmpty) part,
      };
      return parts.isEmpty ? coordinates : parts.join(', ');
    } on Exception {
      return coordinates;
    }
  }

  void _clear() {
    _searchController.clear();
    setState(() => _picked = null);
    widget.onChanged(null);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Search your venue address',
            filled: true,
            fillColor: AppPalette.slateTintSurface,
            prefixIcon: IconButton(
              onPressed: _busy ? null : _search,
              icon: const Icon(Icons.search_rounded),
            ),
            suffixIcon: TextButton(
              onPressed: _clear,
              child: Text(
                'CLEAR',
                style: AppTheme.monoStyle(color: AppPalette.coolSlate),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 220,
            child: _mapSupported ? _buildMap(picked) : const _MapUnavailable(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Search, use your location, or tap the map to move the pin.',
          style: AppTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
        if (picked != null) ...[
          const SizedBox(height: 12),
          _AddressVerified(address: picked.address),
        ],
      ],
    );
  }

  Widget _buildMap(PickedLocation? picked) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              const CameraPosition(target: _klCentre, zoom: 11),
          onMapCreated: (controller) => _map = controller,
          onTap: _busy ? null : _pinAt,
          markers: {
            if (picked != null)
              Marker(
                markerId: const MarkerId('venue'),
                position: LatLng(picked.latitude, picked.longitude),
              ),
          },
          // Lets the map pan inside the scrolling sign-up page.
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Material(
            color: AppPalette.background,
            borderRadius: BorderRadius.circular(6),
            elevation: 2,
            child: InkWell(
              onTap: _busy ? null : _useCurrentLocation,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Use my current location',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        color: AppPalette.obsidianBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _LocationError implements Exception {
  const _LocationError(this.message);

  final String message;
}

class _AddressVerified extends StatelessWidget {
  const _AddressVerified({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.slateTintSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppPalette.obsidianBlack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Address Verified',
                      style: TextStyle(
                        color: AppPalette.obsidianBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GEO-LOCATED',
                      style: AppTheme.monoStyle(fontSize: 9.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    color: AppPalette.coolSlate,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppPalette.slateTintSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'The map needs an Android phone or emulator.',
            textAlign: TextAlign.center,
            style: AppTheme.monoStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }
}
