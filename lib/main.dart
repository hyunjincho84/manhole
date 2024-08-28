import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:manhole_detector/views/camera_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 데이터베이스 파일을 assets에서 복사하는 작업
  await copyDatabaseFromAssets('manhole.db');
  await printTableNames();
  runApp(MainApp());
}

Future<void> printTableNames() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'manhole.db');  // 여기에 사용중인 데이터베이스 파일 이름을 입력하세요.

  final db = await openDatabase(path);

  // 테이블 이름을 가져오는 쿼리 실행
  List<Map<String, dynamic>> result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");

  // 테이블 이름 출력
  print('Tables in the database:');
  result.forEach((row) {
    print("adf");
    print(row['name']);
    print("adf");

  });

  await db.close();
}

Future<void> copyDatabaseFromAssets(String dbName) async {
  // 애플리케이션의 데이터베이스 경로를 가져옵니다.
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, dbName);
  print("path::::::::::::::::::::::,$path");

  // 데이터베이스가 이미 존재하는지 확인합니다.
  final exists = await databaseExists(path);
  print("before");
  if (!exists) {
    print("exitstsadjfklsdfjkalsf");
    // 데이터베이스가 존재하지 않으면 assets 폴더에서 복사합니다.
    ByteData data = await rootBundle.load('assets/$dbName');
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // 데이터를 쓰고 저장합니다.
    await File(path).writeAsBytes(bytes, flush: true);
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'manhole_detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraView(),
    );
  }
}