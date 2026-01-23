// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const String googleApiKey = 'AIzaSyBOtWKSFWzkVaGOM0QfmG_fBneJIXCLyZA';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;

  LatLng _center = const LatLng(25.2048, 55.2708);
  LatLng? selectedLatLng;

  String locationName = 'Tap or search a place';
  String? detectedEmirate;

  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];

  // ================= SEARCH =================
  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => searchResults.clear());
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$input'
        '&location=25.2048,55.2708'
        '&radius=50000'
        '&key=$googleApiKey';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    setState(() {
      searchResults = data['predictions'] ?? [];
    });
  }

  // ================= PLACE DETAILS =================
  Future<void> _selectPlace(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,geometry'
        '&key=$googleApiKey';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    final loc = data['result']['geometry']['location'];
    final name = data['result']['name'];

    final LatLng pos = LatLng(loc['lat'], loc['lng']);

    await _onMapTap(pos, customName: name);
    setState(() => searchResults.clear());

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(pos, 16),
    );
  }

  // ================= MAP TAP =================
  Future<void> _onMapTap(
    LatLng pos, {
    String? customName,
  }) async {
    _moveMarker(pos, 'Loading location...');

    final resolved = await _resolveLocation(pos.latitude, pos.longitude);

    setState(() {
      locationName = customName ?? resolved['name'] ?? 'Unknown location';

      detectedEmirate = resolved['emirate'];
    });
  }

  void _moveMarker(LatLng pos, String name) {
    setState(() {
      selectedLatLng = pos;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: pos,
          infoWindow: InfoWindow(title: name),
        ),
      );
    });
  }

  // ================= LOCATION + EMIRATE RESOLVER =================
  Future<Map<String, String?>> _resolveLocation(
      double lat, double lng) async {
    final geoUrl =
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$googleApiKey';

    final res = await http.get(Uri.parse(geoUrl));
    final data = json.decode(res.body);

    if (data['results'] == null || data['results'].isEmpty) {
      return {
        'name': '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        'emirate': null,
      };
    }

    final result = data['results'][0];
    final components = result['address_components'] as List;

    String? emirate;

    for (final c in components) {
      final types = List<String>.from(c['types']);
      if (types.contains('administrative_area_level_1')) {
        emirate = _normalizeEmirate(c['long_name']);
        break;
      }
    }

    return {
      'name': result['formatted_address'],
      'emirate': emirate,
    };
  }

  // ================= EMIRATE NORMALIZER =================
  String? _normalizeEmirate(String raw) {
    if (raw.contains('Dubai')) return 'Dubai';
    if (raw.contains('Abu Dhabi')) return 'Abu Dhabi';
    if (raw.contains('Sharjah')) return 'Sharjah';
    if (raw.contains('Ajman')) return 'Ajman';
    if (raw.contains('Umm')) return 'Umm Al Quwain';
    if (raw.contains('Ras')) return 'Ras Al Khaimah';
    if (raw.contains('Fujairah')) return 'Fujairah';
    return null;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _center, zoom: 12),
            markers: _markers,
            onTap: (pos) => _onMapTap(pos),

            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (c) => _mapController = c,
          ),

          // 🔍 SEARCH BAR
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchPlaces,
                    decoration: const InputDecoration(
                      hintText: 'Search places',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),

                if (searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (_, i) {
                        final p = searchResults[i];
                        return ListTile(
                          title: Text(p['description']),
                          onTap: () => _selectPlace(p['place_id']),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ✅ CONFIRM
          Positioned(
            left: 16,
            right: 16,
            bottom: 64,
            child: ElevatedButton(
              onPressed: selectedLatLng == null
                  ? null
                  : () {
                      Navigator.pop(context, {
                        'name': locationName,
                        'lat': selectedLatLng!.latitude,
                        'lng': selectedLatLng!.longitude,
                        'emirate': detectedEmirate,
                      });
                    },
              child: const Text('Confirm location'),
            ),
          ),
        ],
      ),
    );
  }
}
