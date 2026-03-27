import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../application/cubit/auth_cubit.dart';

class FaceScanPage extends StatefulWidget {
  final String email, password, name, phone, job, birthday;
  const FaceScanPage({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.job,
    required this.birthday,
  });

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  CameraController? _controller;
  late FaceDetector _faceDetector;
  Timer? _scanTimer;

  bool _isProcessing = false;
  int _stepIndex = 0;
  final Map<int, File> _capturedImages = {};

  final List<String> _guides = [
    "Nhìn THẲNG vào khung hình",
    "Quay mặt từ từ sang TRÁI",
    "Quay mặt từ từ sang PHẢI",
    "Hơi NGƯỚC mặt lên trên",
    "Hơi CÚI mặt xuống dưới",
  ];

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initCamera();
  }

  void _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() {});
      _scanTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        _detectFaceFromPicture();
      });
    } catch (e) {
      debugPrint("Lỗi Camera: $e");
    }
  }

  Future<void> _detectFaceFromPicture() async {
    if (_isProcessing || _stepIndex >= 5 || !mounted) return;
    _isProcessing = true;
    try {
      final XFile photo = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final double yaw = face.headEulerAngleY ?? 0;
        final double pitch = face.headEulerAngleX ?? 0;
        bool isMatched = false;

        switch (_stepIndex) {
          case 0:
            if (yaw.abs() < 8 && pitch.abs() < 8) isMatched = true;
            break;
          case 1:
            if (yaw > 18) isMatched = true;
            break;
          case 2:
            if (yaw < -18) isMatched = true;
            break;
          case 3:
            if (pitch > 12) isMatched = true;
            break;
          case 4:
            if (pitch < -12) isMatched = true;
            break;
        }

        if (isMatched) {
          _capturedImages[_stepIndex] = File(photo.path);
          setState(() => _stepIndex++);
          if (_stepIndex >= 5) {
            _scanTimer?.cancel();
            _onAllCaptured();
          }
        } else {
          await File(photo.path).delete();
        }
      } else {
        await File(photo.path).delete();
      }
    } catch (e) {
      debugPrint("Lỗi phân tích: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _onAllCaptured() {
    final List<File> imageFiles = [];
    for (int i = 0; i < 5; i++) {
      if (_capturedImages[i] != null) imageFiles.add(_capturedImages[i]!);
    }

    context.read<AuthCubit>().register(
      email: widget.email,
      password: widget.password,
      name: widget.name,
      num: widget.phone,
      job: widget.job,
      birthday: widget.birthday,
      imageFiles: imageFiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Xác thực khuôn mặt"), elevation: 0),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegisterSuccess) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đăng ký thành công! Chào mừng bạn."),
              ),
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _stepIndex = 0;
              _capturedImages.clear();
            });
          }
        },
        child: Stack(
          children: [
            // 1. Phần hướng dẫn phía trên
            Column(
              children: [
                const SizedBox(height: 30),
                Text(
                  "Bước ${_stepIndex + 1}/5",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 12,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_stepIndex + 1) / 5,
                      minHeight: 10,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _guides[_stepIndex < 5 ? _stepIndex : 4],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // 2. Camera Preview ở Trung tâm
            Center(
              child: Container(
                width: size.width * 0.72,
                height: size.width * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isProcessing ? Colors.orange : primaryColor,
                    width: 5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      (_controller != null && _controller!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),

            // 3. Hiệu ứng quét mặt (Tùy chọn trang trí)
            Center(
              child: Opacity(
                opacity: 0.2,
                child: Container(
                  width: size.width * 0.65,
                  height: 2,
                  color: primaryColor,
                ),
              ),
            ),

            // 4. Màn hình Loading
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: Colors.white.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            state.message ?? "Đang upload ảnh...",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}
