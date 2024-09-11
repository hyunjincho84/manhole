import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as pathLib;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _center;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
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
    final path = pathLib.join(databasePath, dbName);
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

  Future<void> _fetchPipelinesAndDrawPolylines(List<String> nearbyManholeIds) async {
    log('$nearbyManholeIds');
    final db = await openDatabaseConnection('manhole.db');
    final List<Map<String, dynamic>> pipelineRows = await db.query('prior_info',
        columns: [
          'pipeline_id',
          'start_manhole_id',
          'end_manhole_id',
          'installation_year',
          'material',
          'diameter',
          'length'
        ]);

    final Set<Polyline> newPolylines = {};
    final Set<Marker> newMarkers = {};

    for (var pipeline in pipelineRows) {
      final startManholeId = pipeline['start_manhole_id'] as String;
      final endManholeId = pipeline['end_manhole_id'] as String;

      // Check if both start and end manholes are nearby
      if (nearbyManholeIds.contains(startManholeId) &&
          nearbyManholeIds.contains(endManholeId)) {
        // Find positions of both start and end manholes
        final Marker? startManhole = _markers.firstWhere(
          (marker) => marker.markerId.value == startManholeId,
        );
        final Marker? endManhole = _markers.firstWhere(
          (marker) => marker.markerId.value == endManholeId,
        );

        if (startManhole != null && endManhole != null) {
          // 중점 계산
          final LatLng midpoint = LatLng(
            (startManhole.position.latitude + endManhole.position.latitude) / 2,
            (startManhole.position.longitude + endManhole.position.longitude) / 2,
          );

          // Add a polyline connecting the start and end manholes
          final polyline = Polyline(
            polylineId: PolylineId(pipeline['pipeline_id'].toString()),
            points: [startManhole.position, endManhole.position],
            color: Colors.green,
            width: 5,
            onTap: () {
              log("Polyline tapped: Pipeline ${pipeline['pipeline_id']}");
            },
          );
          newPolylines.add(polyline);

          // Add a marker at the midpoint (초록색 마커)
          final marker = Marker(
            markerId: MarkerId('midpoint_${pipeline['pipeline_id']}'),
            position: midpoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Pipeline ${pipeline['pipeline_id']}',
              snippet: 'Tap to see details',
            ),
            onTap: () {
              _showPipelineInfo(pipeline);
              log("Midpoint marker tapped: Pipeline ${pipeline['pipeline_id']}");
            },
          );
          newMarkers.add(marker);
        }
      }
    }

    setState(() {
      _polylines = newPolylines;
      _markers.addAll(newMarkers); // Add new midpoint markers
    });

    await db.close();
  }

  void _showPipelineInfo(Map<String, dynamic> pipeline) {
    log('showp');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pipeline Info'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pipeline ID: ${pipeline['pipeline_id']}'),
              Text('Start manhole ID: ${pipeline['start_manhole_id']}'),
              Text('end manhole ID: ${pipeline['end_manhole_id']}'),
              Text('Installation Year: ${pipeline['installation_year']}'),
              Text('Material: ${pipeline['material']}'),
              Text('Diameter: ${pipeline['diameter']}'),
              Text('Length: ${pipeline['length']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
    _center = LatLng(37.51552, 127.04705);

    //실제 현재 위치
    _fetchNearbyManholes();
  }

  _fetchNearbyManholes() async {
    if (_center == null) return;

    final nearbyManholes = await findNearbyManholes(
      _center!.latitude,
      _center!.longitude,
      threshold: 100.0, // 필요에 따라 범위를 조정하세요.
    );
    log('adsfafa ${nearbyManholes}');
    final nearbyManholeIds = nearbyManholes
        .map((m) => m['manhole_id'].toString())
        .toList(); // String으로 변환

    setState(() {
      _markers = nearbyManholes.map((manhole) {
        return Marker(
          markerId: MarkerId(manhole['manhole_id']),
          position: LatLng(manhole['latitude'], manhole['longitude']),
          infoWindow: InfoWindow(
            title: 'Manhole ${manhole['manhole_id']}',
            snippet:
                'Latitude: ${manhole['latitude']}, Longitude: ${manhole['longitude']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue),
          onTap: () {
            mapController?.showMarkerInfoWindow(
                MarkerId(manhole['manhole_id']));
          },
        );
      }).toSet();
    });

    // Fetch and display pipelines and midpoint markers
    await _fetchPipelinesAndDrawPolylines(nearbyManholeIds);
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
                polylines: _polylines,
              ),
            ),
    );
  }
}