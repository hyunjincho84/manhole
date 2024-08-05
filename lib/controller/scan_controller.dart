import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ScanController extends GetxController {
  late BuildContext context;

  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
    max = 0.0;
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  late XFile picture;

  var x = 0.0.obs, y = 0.0.obs, w = 0.0.obs, h = 0.0.obs;
  var label = "".obs;
  var isObjectDetected = false.obs;
  var max = 0.0;
  var confidence = "".obs;
  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
        enableAudio: false, // Disable audio if not needed
      );

      await cameraController.initialize();
      await cameraController.setFlashMode(FlashMode.off); // Turn off flash
      isCameraInitialized(true);
      update();
    } else {
      log("Permission denied");
    }
  }

  initTFLite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  takePicture() async {
    max = 0.0;
    if (!cameraController.value.isInitialized) {
      log("Camera is not initialized");
      return;
    }

    if (cameraController.value.isTakingPicture) {
      log("A picture is already being taken");
      return;
    }

    try {
      picture = await cameraController.takePicture();

      File imageFile = File(picture.path);
      log("Picture taken: ${picture.path}");

      // Perform object detection on the captured image
      detectObjectOnImage(imageFile);
    } catch (e) {
      log('Error taking picture: $e');
    }
  }

  detectObjectOnImage(File imageFile) async {
    try {
      // log('inside detectObj');
      var recognitions = await Tflite.detectObjectOnImage(
        path: imageFile.path,
        // model: "YOLO",
        threshold: 0.3,
        imageMean: 127.5,
        imageStd: 127.5,
        asynch: true,
      );

      // log("ouput");
      // log('Detector result: $recognitions');

      if (recognitions != null && recognitions.isNotEmpty) {
        for (var recognition in recognitions) {
          if (recognition['confidence'] > 0.45) {
            if(max < recognition['confidence'])
            {
              max = recognition['confidence'];
              confidence.value = recognition['confidence'].toString();
              label.value = recognition['label'].toString();
            }
            // x.value = recognition['rect']['x'];
            // y.value = recognition['rect']['y'];
            // h.value = recognition['rect']['h'];
            // w.value = recognition['rect']['w'];
            isObjectDetected.value = true;
            log('$recognition');
          }
        }
        update();
      } else {
        log('No objects detected');
        isObjectDetected.value = false;
        update();
      }
    } catch (e) {
      log('Error running model on image: $e');
    }
  }
}