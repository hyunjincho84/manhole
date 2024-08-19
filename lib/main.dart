import 'package:flutter/material.dart';
import 'package:manhole_detector/views/camera_view.dart';

void main() => runApp(MainApp());

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