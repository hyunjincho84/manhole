import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manhole_detector/controller/scan_controller.dart';
import 'package:manhole_detector/map/map.dart';
import 'package:manhole_detector/result_screen.dart';


class CameraView extends StatelessWidget {
  final ScanController controller = Get.put(ScanController());

  @override
  Widget build(BuildContext context) {
    controller.context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Object Detection'),
        actions: [
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: () async {
              await _pickImageFromGallery(context);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            CameraPreview(controller.cameraController),
            Align(
              alignment: Alignment(0,-0.3),
              child: Container(
                width: 300, // Width of the guideline box
                height: 300, // Height of the guideline box
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red, // Color of the guideline box
                    width: 4, // Thickness of the border
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    '맨홀을 네모칸 안에 위치해 주세요',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      backgroundColor: Colors.white.withOpacity(0.7), // Background for better readability
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () async {
                    await controller.takePicture();
                    if (controller.picture.path.isNotEmpty) {
                      _showResult(context, controller.picture.path);
                    }
                  },
                  child: Icon(Icons.camera),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await controller.detectObjectOnGalleryImage(File(pickedFile.path));
      _showResult(context, pickedFile.path);
    }
  }

  void _showResult(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(imagePath: imagePath),
      ),
    );
  }
}

