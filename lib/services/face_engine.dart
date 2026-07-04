import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Kameradan okunan ham yuz metrikleri (goruntu tabanli duygu analizi girdisi).
class FaceReading {
  final bool faceVisible;
  final double smile; // 0..1
  final double eyesOpen; // 0..1 (iki gozun ortalamasi)
  final double headYaw; // derece, mutlak deger buyukse dikkat dagilmis
  final DateTime time;

  FaceReading({
    required this.faceVisible,
    required this.smile,
    required this.eyesOpen,
    required this.headYaw,
    required this.time,
  });
}

/// On kamera + Google ML Kit yuz tespiti (Edge AI — tum islem cihazda).
/// Web/masaustunde yalnizca kamera onizlemesi calisir, tespit similasyona birakilir.
class FaceEngine {
  CameraController? controller;
  FaceDetector? _detector;
  bool _busy = false;
  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);
  final ValueNotifier<FaceReading?> reading = ValueNotifier(null);

  bool get supportsDetection =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get previewReady => controller?.value.isInitialized ?? false;

  Future<bool> start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: kIsWeb
            ? ImageFormatGroup.jpeg
            : Platform.isAndroid
                ? ImageFormatGroup.nv21
                : ImageFormatGroup.bgra8888,
      );
      await controller!.initialize();

      if (supportsDetection) {
        _detector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            performanceMode: FaceDetectorMode.fast,
          ),
        );
        await controller!.startImageStream(_onFrame);
      }
      return true;
    } catch (_) {
      await stop();
      return false;
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final now = DateTime.now();
    if (_busy || now.difference(_lastProcess).inMilliseconds < 400) return;
    _busy = true;
    _lastProcess = now;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final faces = await _detector!.processImage(input);
      if (faces.isEmpty) {
        reading.value = FaceReading(
          faceVisible: false,
          smile: 0,
          eyesOpen: 1,
          headYaw: 0,
          time: now,
        );
      } else {
        final f = faces.first;
        final left = f.leftEyeOpenProbability ?? 0.9;
        final right = f.rightEyeOpenProbability ?? 0.9;
        reading.value = FaceReading(
          faceVisible: true,
          smile: f.smilingProbability ?? 0,
          eyesOpen: (left + right) / 2,
          headYaw: f.headEulerAngleY ?? 0,
          time: now,
        );
      }
    } catch (_) {
      // tek kare hatasi surusu bozmasin
    } finally {
      _busy = false;
    }
  }

  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _toInputImage(CameraImage image) {
    final cam = controller!.description;
    final sensorOrientation = cam.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var comp = _orientations[controller!.value.deviceOrientation];
      if (comp == null) return null;
      if (cam.lensDirection == CameraLensDirection.front) {
        comp = (sensorOrientation + comp) % 360;
      } else {
        comp = (sensorOrientation - comp + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(comp);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    final bytes = image.planes.length == 1
        ? image.planes.first.bytes
        : _concatPlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatPlanes(List<Plane> planes) {
    final buffer = WriteBuffer();
    for (final p in planes) {
      buffer.putUint8List(p.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  Future<void> stop() async {
    try {
      if (controller?.value.isStreamingImages ?? false) {
        await controller?.stopImageStream();
      }
    } catch (_) {}
    try {
      await controller?.dispose();
    } catch (_) {}
    controller = null;
    await _detector?.close();
    _detector = null;
    reading.value = null;
  }
}
