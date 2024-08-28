import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _center;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  BitmapDescriptor? customIcon;

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // 현재 위치를 가져옵니다.
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<Database> openDatabaseConnection(String dbName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);
    print('Database path: $path');

    try {
      final db = await openDatabase(path);
      print('Database opened successfully: $path');
      return db;
    } catch (e) {
      print('Failed to open database: $e');
      throw Exception('Failed to open database');
    }
  }

  Future<List<Map<String, dynamic>>> findNearbyManholes(double lat, double lon,
      {double threshold = 50.0, String dbName = 'manhole.db'}) async {
    final db = await openDatabaseConnection(dbName);
    final List<Map<String, dynamic>> rows = await db.query('structured_info',
        columns: ['manhole_id', 'latitude', 'longitude']);

    final List<Map<String, dynamic>> nearbyManholes = [];

    for (var row in rows) {
      final dbLat = row['latitude'] as double;
      final dbLon = row['longitude'] as double;

      final distance = Geolocator.distanceBetween(lat, lon, dbLat, dbLon);

      if (distance <= threshold) {
        nearbyManholes.add(row);
      }
    }

    await db.close();
    return nearbyManholes;
  }

  _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    //설정된 위도, 경도 입력
    // _center = LatLng(37.51552, 127.0471);

    //실제 현재 위치
    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    });

    _fetchNearbyManholes();
  }

  _fetchNearbyManholes() async {
    if (_center == null) return;

    final nearbyManholes = await findNearbyManholes(
      _center!.latitude,
      _center!.longitude,
      threshold: 100.0, // 필요에 따라 범위를 조정하세요.
    );

    setState(() {
      _markers = nearbyManholes.map((manhole) {
        return Marker(
          markerId: MarkerId(manhole['manhole_id']),
          position: LatLng(manhole['latitude'], manhole['longitude']),
          infoWindow: InfoWindow(
            title: 'Manhole ${manhole['manhole_id']}',
            snippet: 'Latitude: ${manhole['latitude']}, Longitude: ${manhole['longitude']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () {
            mapController?.showMarkerInfoWindow(MarkerId(manhole['manhole_id']));
          },
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Location Map'),
      ),
      body: _center == null
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              height: double.infinity,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center!,
                  zoom: 15.0,
                ),
                markers: _markers.union({
                  Marker(
                    markerId: const MarkerId('user_location'),
                    position: _center!,
                    infoWindow: const InfoWindow(title: 'Your Location'),
                  ),
                }),
              ),
            ),
    );
  }
}