// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  LatLng? selectedLatLng;
  String? address;
  String? emirate;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(25.2048, 55.2708), // Dubai
    zoom: 11,
  );

  /* ================= SEARCH LOCATION ================= */

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 14),
        );

        await _onTap(latLng);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    }
  }

  /* ================= TAP ON MAP ================= */

  Future<void> _onTap(LatLng position) async {
    setState(() {
      selectedLatLng = position;
      address = null;
      emirate = null;
    });

    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final admin = place.administrativeArea?.toLowerCase() ?? '';

        String? detectedEmirate;
        if (admin.contains('dubai')) detectedEmirate = 'Dubai';
        else if (admin.contains('abu')) detectedEmirate = 'Abu Dhabi';
        else if (admin.contains('sharjah')) detectedEmirate = 'Sharjah';
        else if (admin.contains('ajman')) detectedEmirate = 'Ajman';
        else if (admin.contains('umm')) detectedEmirate = 'Umm Al Quwain';
        else if (admin.contains('ras')) detectedEmirate = 'Ras Al Khaimah';
        else if (admin.contains('fujairah')) detectedEmirate = 'Fujairah';

        setState(() {
          address =
              '${place.name ?? ''}, ${place.locality ?? place.subLocality ?? ''}'
                  .trim();
          emirate = detectedEmirate;
        });
      }
    } catch (_) {}
  }

  /* ================= CONFIRM ================= */

  void _confirm() {
    if (selectedLatLng == null) return;

    Navigator.pop(context, {
      'name': address ?? 'Selected location',
      'lat': selectedLatLng!.latitude,
      'lng': selectedLatLng!.longitude,
      'emirate': emirate,
    });
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: selectedLatLng == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: selectedLatLng!,
                    ),
                  },
          ),

          // 🔍 SEARCH BAR
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search location',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),

          // 📍 ADDRESS CARD
          if (address != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '$address\n${emirate ?? 'Unknown emirate'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

          // ✅ CONFIRM BUTTON
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: selectedLatLng == null ? null : _confirm,
                child: const Text('Confirm Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
