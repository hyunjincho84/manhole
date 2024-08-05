import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:manhole_detector/controller/scan_controller.dart';

class CameraView extends StatelessWidget {
  final ScanController controller = Get.put(ScanController());

  @override
  Widget build(BuildContext context) {
    controller.context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Object Detection'),
      ),
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            CameraPreview(controller.cameraController),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () async {
                    await controller.takePicture();
                    if (controller.picture.path.isNotEmpty) {
                      // _showCapturedImage(context, controller.picture.path);
                      _showresult(context, controller.picture.path);
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


 void _showresult(BuildContext context, String imagePath) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Container(
              child: Stack(
                children: [
                  Image.file(File(imagePath)),
                  Obx(() {
                    if (controller.isObjectDetected.value) {
                      return Stack(
                        children: [
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
                        ],
                      );
                    } else {
                      return Container(); // 객체가 감지되지 않으면 빈 컨테이너 반환
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  void _showCapturedImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Image.file(File(imagePath)),
                Obx(() {
                  if (controller.isObjectDetected.value) {
                    return Positioned(
                      left: controller.x.value *
                          MediaQuery.of(context).size.width,
                      top: controller.y.value *
                          MediaQuery.of(context).size.height,
                      width: controller.w.value *
                          MediaQuery.of(context).size.width,
                      height: controller.h.value *
                          MediaQuery.of(context).size.height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 3,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
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
                    );
                  } else {
                    return Container(); // 객체가 감지되지 않으면 빈 컨테이너 반환
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
