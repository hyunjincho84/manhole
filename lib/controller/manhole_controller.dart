import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:latlong2/latlong.dart';

Future<Database> openDatabaseConnection(String dbName) async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, dbName);

  return openDatabase(path);
}

Future<List<String>> findNearbyManholeIds(double lat, double lon, {double threshold = 50.0, String dbName = 'manhole.db'}) async {
  final db = await openDatabaseConnection(dbName);
  final List<Map<String, dynamic>> rows = await db.query('structured_info', columns: ['manhole_id', 'latitude', 'longitude']);

  final List<String> nearbyManholeIds = [];

  for (var row in rows) {
    final manholeId = row['manhole_id'] as String;
    final dbLat = row['latitude'] as double;
    final dbLon = row['longitude'] as double;

    final distance = calculateUTMDistance(lat, lon, dbLat, dbLon);

    if (distance <= threshold) {
      nearbyManholeIds.add(manholeId);
    }
  }

  await db.close();
  return nearbyManholeIds;
}

double calculateUTMDistance(double lat1, double lon1, double lat2, double lon2) {
  final point1 = LatLng(lat1, lon1);
  final point2 = LatLng(lat2, lon2);

  final distance = const Distance().as(LengthUnit.Meter, point1, point2);
  return distance;
}

Future<List<Map<String, dynamic>>> findRelatedManholeInfo(String manholeId, {String dbName = 'manhole.db'}) async {
  final db = await openDatabaseConnection(dbName);

  final List<Map<String, dynamic>> rows = await db.query(
    'prior_info',
    where: 'start_manhole_id = ? OR end_manhole_id = ?',
    whereArgs: [manholeId, manholeId],
  );

  await db.close();
  return rows;
}