import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
  // 1. Lấy hướng xoay của ảnh dựa trên cảm biến camera và hướng thiết bị
  final sensorOrientation = camera.sensorOrientation;
  InputImageRotation? rotation;

  // Ánh xạ hướng xoay
  var orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Tính toán góc xoay chuẩn cho ML Kit
  if (Platform.isAndroid) {
    var rotationDegree =
        orientations[DeviceOrientation.portraitUp]; // Giả định dùng dọc
    if (rotationDegree == null) return null;

    // Với Android camera trước, cần tính toán bù trừ
    final angle = (sensorOrientation + rotationDegree) % 360;
    rotation = InputImageRotationValue.fromRawValue(angle);
  } else {
    // Với iOS
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  }

  if (rotation == null) return null;

  // 2. Lấy định dạng ảnh (YUV420 cho Android, BGRA8888 cho iOS)
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;

  // 3. Gom tất cả các mặt phẳng (planes) của ảnh thành một mảng byte duy nhất
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  // 4. Tạo metadata cho InputImage
  final metadata = InputImageMetadata(
    size: Size(image.width.toDouble(), image.height.toDouble()),
    rotation: rotation,
    format: format,
    bytesPerRow: image.planes[0].bytesPerRow,
  );

  // 5. Trả về InputImage hoàn chỉnh
  return InputImage.fromBytes(bytes: bytes, metadata: metadata);
}
