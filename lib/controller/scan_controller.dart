import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:path_provider/path_provider.dart';

class ScanController extends GetxController {
  late BuildContext context;

  @override
  void onInit() {
    super.onInit();
    initCamera();
    initVisionModel();
    max = 0.0;
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;
  FlutterVision vision = FlutterVision();

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
        enableAudio: false,
      );

      await cameraController.initialize();
      await cameraController.setFlashMode(FlashMode.off);
      isCameraInitialized(true);
      update();
    } else {
      log("Permission denied");
    }
  }

  initVisionModel() async {
    try {
      await vision.loadYoloModel(
        modelPath: "assets/detect_tflite/detect_s_float32.tflite",
        labels: "assets/labels.txt",
        modelVersion: "yolov8",
        numThreads: 1,
        useGpu: false,
      );
      log("Model loaded successfully");
    } catch (e) {
      log("Error loading model: $e");
    }
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
      Uint8List byte = await imageFile.readAsBytes();
      ui.Image image = await decodeImageFromList(byte);
      log("Image width: ${image.width}, height: ${image.height}");

      final recognitions = await vision.yoloOnImage(
        bytesList: byte,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.1,
        confThreshold: 0.1,
        classThreshold: 0.1,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        for (var recognition in recognitions) {
          List<dynamic> box = recognition['box'];
          double confidenceInClass = box[4];
          String detectedClass = recognition['tag'];

          if (confidenceInClass > 0.1) {
            if (max < confidenceInClass) {
              max = confidenceInClass;
              confidence.value = confidenceInClass.toString();
              label.value = detectedClass;

              x.value = box[0];
              y.value = box[1];
              w.value = box[2] - box[0];
              h.value = box[3] - box[1];
              log("values: ${x.value}, ${y.value}, ${w.value}, ${h.value}, ");
              update();
            }
            isObjectDetected.value = true;
            log('$recognition');
          }
        }
      } else {
        log('No objects detected');
        label.value = "no obj detected";
        isObjectDetected.value = false;
        update();
      }
    } catch (e) {
      log('Error running model on image: $e');
    }
  }

  // 새롭게 추가된 메서드
  detectObjectOnGalleryImage(File imageFile) async {
    await detectObjectOnImage(imageFile);
  }
}
