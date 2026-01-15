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

    _moveMarker(pos, name);
    setState(() => searchResults.clear());

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(pos, 16),
    );
  }

  // ================= MAP TAP =================
  Future<void> _onMapTap(LatLng pos) async {
    _moveMarker(pos, 'Loading location...');
    final name = await _resolveLocationName(pos.latitude, pos.longitude);

    setState(() {
      locationName = name;
    });
  }

  void _moveMarker(LatLng pos, String name) {
    setState(() {
      selectedLatLng = pos;
      locationName = name;
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

  // ================= LOCATION NAME RESOLVER =================
  Future<String> _resolveLocationName(double lat, double lng) async {
    // 1️⃣ Try nearby POI
    final poiUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=50'
        '&type=point_of_interest'
        '&key=$googleApiKey';

    final poiRes = await http.get(Uri.parse(poiUrl));
    final poiData = json.decode(poiRes.body);

    if (poiData['results'] != null && poiData['results'].isNotEmpty) {
      return poiData['results'][0]['name'];
    }

    // 2️⃣ Try address
    final geoUrl =
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$googleApiKey';

    final geoRes = await http.get(Uri.parse(geoUrl));
    final geoData = json.decode(geoRes.body);

    if (geoData['results'] != null && geoData['results'].isNotEmpty) {
      return geoData['results'][0]['formatted_address'];
    }

    // 3️⃣ Fallback
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
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
            initialCameraPosition: CameraPosition(target: _center, zoom: 12),
            markers: _markers,
            onTap: _onMapTap,
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

                // 🔽 SEARCH RESULTS
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

          // ✅ CONFIRM BUTTON
          Positioned(
            left: 16,
            right: 16,
            bottom: 64, // ABOVE ANDROID NAV
            child: ElevatedButton(
              onPressed: selectedLatLng == null
                  ? null
                  : () {
                      Navigator.pop(context, {
                        'name': locationName,
                        'lat': selectedLatLng!.latitude,
                        'lng': selectedLatLng!.longitude,
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
