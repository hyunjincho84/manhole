import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manhole_detector/controller/scan_controller.dart';
import 'package:manhole_detector/map/map.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final ScanController controller = Get.find<ScanController>();

  ResultScreen({required this.imagePath});

  Future<ui.Image> _loadImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detection Result'),
      ),
      body: FutureBuilder<ui.Image>(
        future: _loadImage(imagePath),
        builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading image'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Image not available'));
          }

          final ui.Image image = snapshot.data!;
          final double imageWidth = image.width.toDouble();
          final double imageHeight = image.height.toDouble();

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;

              double factorX = screenWidth / (imageWidth);
              double imgRatio = imageWidth / imageHeight;
              double newWidth = imageWidth * factorX;
              double newHeight = newWidth / imgRatio;
              double factorY = newHeight / (imageHeight);
              double pady = (screenHeight - newHeight) / 2;

              return Stack(
                children: [
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Obx(() {
                    if (controller.isObjectDetected.value) {
                      return Stack(
                        children: [
                          Positioned(
                            left: controller.x.value * factorX,
                            top:
                                controller.y.value * factorY + pady,
                            width:
                                controller.w.value * factorX,
                            height:
                                controller.h.value * factorY,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.green,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.white,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  controller.label.value,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.white,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  controller.confidence.value,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (controller.label.value == '우수') // "woosu"일 경우에만 버튼 표시
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => MapScreen()),
                                  );
                                },
                                child: Text('지도로 이동'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // 버튼 색상
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  textStyle: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                        ],
                      );
                    } else {
                      return Container();
                    }
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}