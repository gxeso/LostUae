// © 2026 Project LostUAE

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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

  bool _locationPermissionGranted = false;
  List<dynamic> _predictions = [];

  // 🔐 PUT YOUR NEW API KEY HERE
  static const String _apiKey = "AIzaSyBiHnK6bXnryTQDvlSnU9awh8R6jSBMJeE";

  final String _sessionToken = const Uuid().v4();

  final LatLngBounds _uaeBounds =  LatLngBounds(
    southwest: LatLng(22.5, 51.5),
    northeast: LatLng(26.5, 56.5),
  );

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(25.2048, 55.2708),
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => _locationPermissionGranted = true);
    }
  }

  /* ================= AUTOCOMPLETE ================= */

  Future<void> _searchAutocomplete(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    final encodedInput = Uri.encodeComponent(input);

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$encodedInput"
        "&components=country:ae"
        "&sessiontoken=$_sessionToken"
        "&key=$_apiKey";

    final response = await http.get(Uri.parse(url));

    final data = json.decode(response.body);

    print(data); // 🔍 keep this for debugging

    if (data['status'] == "OK") {
      setState(() {
        _predictions = data['predictions'];
      });
    } else {
      setState(() => _predictions = []);
    }
  }

  /* ================= SELECT PLACE ================= */

  Future<void> _selectPlace(String placeId, String description) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeId"
        "&sessiontoken=$_sessionToken"
        "&key=$_apiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    final location = data['result']['geometry']['location'];
    final latLng = LatLng(location['lat'], location['lng']);

    if (!_uaeBounds.contains(latLng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only UAE locations allowed')),
      );
      return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15),
    );

    await _reverseGeocode(latLng);

    setState(() {
      _searchController.text = description;
      _predictions = [];
    });
  }

  /* ================= MAP TAP ================= */

  Future<void> _onTap(LatLng position) async {
    if (!_uaeBounds.contains(position)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only UAE locations allowed')),
      );
      return;
    }

    await _reverseGeocode(position);
  }

  /* ================= REVERSE GEOCODE ================= */

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      selectedLatLng = position;
      address = null;
    });

    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      final oneLineAddress = [
        place.street,
        place.locality,
      ]
          .where((e) => e != null && e!.isNotEmpty)
          .join(', ');

      setState(() {
        address = oneLineAddress;
        emirate = place.administrativeArea;
      });
    }
  }

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
      appBar: AppBar(title: const Text('Pick Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            cameraTargetBounds: CameraTargetBounds(_uaeBounds),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onTap,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: _locationPermissionGranted,
            markers: selectedLatLng == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: selectedLatLng!,
                    ),
                  },
          ),

          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchAutocomplete,
                    decoration: const InputDecoration(
                      hintText: 'Search location (UAE only)',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),

                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final place = _predictions[index];
                        return ListTile(
                          title: Text(
                            place['description'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectPlace(
                            place['place_id'],
                            place['description'],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          if (address != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: selectedLatLng == null ? null : _confirm,
              child: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}