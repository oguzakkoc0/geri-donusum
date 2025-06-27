import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  final Location _location = Location();
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _generateMarkers();
    _initLocation();
  }

  void _generateMarkers() {
    final random = Random();
    for (int i = 0; i < 1000; i++) {
      final lat = 36.0 + random.nextDouble() * (42.1 - 36.0);
      final lng = 26.0 + random.nextDouble() * (45.0 - 26.0);
      final pos = LatLng(lat, lng);

      _markers.add(
        Marker(
          markerId: MarkerId("bin_$i"),
          position: pos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: "Çöp Kutusu"),
        ),
      );
    }
  }

  Future<void> _initLocation() async {
    final hasPermission = await _location.requestPermission();
    if (hasPermission == PermissionStatus.granted ||
        hasPermission == PermissionStatus.grantedLimited) {
      final loc = await _location.getLocation();
      final latLng = LatLng(loc.latitude!, loc.longitude!);
      setState(() {
        _userLocation = latLng;
      });
    }
  }

  void _recenterMap() {
    if (_userLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 15),
      );
    }
  }

  double calculateDistance(LatLng a, LatLng b) {
    const earthRadius = 6371000; // metre
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(a.latitude)) *
            cos(_degToRad(b.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  Marker? _findNearestMarker() {
    if (_userLocation == null || _markers.isEmpty) return null;

    Marker? nearest;
    double minDistance = double.infinity;

    for (var marker in _markers) {
      final dist = calculateDistance(_userLocation!, marker.position);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = marker;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Çöp Kutuları",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[200],
        elevation: 4,
        leading: const Icon(Icons.location_on, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.near_me, color: Colors.white),
            onPressed: () {
              final nearest = _findNearestMarker();
              if (nearest != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(nearest.position, 16),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('En yakın çöp kutusu ${nearest.markerId.value}'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation!,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: {
                    ..._markers,
                    Marker(
                      markerId: const MarkerId("me"),
                      position: _userLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    )
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId("me_circle"),
                      center: _userLocation!,
                      radius: 30,
                      fillColor: Colors.blue.withOpacity(0.3),
                      strokeColor: Colors.blue,
                      strokeWidth: 2,
                    )
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                ),
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: _recenterMap,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }
}
