import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/theme/app_theme.dart';
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthRegisterSuccess) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Đăng ký thành công! Chào mừng bạn."),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.errorRed,
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
                // Header
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Progress Info
                Column(
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      "Bước ${_stepIndex + 1}/5",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_stepIndex + 1) / 5,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _guides[_stepIndex < 5 ? _stepIndex : 4],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Camera Preview
                Center(
                  child: Container(
                    width: size.width * 0.72,
                    height: size.width * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isProcessing
                            ? Colors.orange.withOpacity(0.8)
                            : Colors.white.withOpacity(0.8),
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: (_controller != null && _controller!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    ),
                  ),
                ),

                // Scan Effect
                Center(
                  child: SizedBox(
                    width: size.width * 0.65,
                    height: size.width * 0.65,
                    child: CustomPaint(
                      painter: _ScanEffectPainter(
                        progress: _stepIndex / 5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Loading Overlay
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return Container(
                        color: Colors.black.withOpacity(0.8),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                state.message ?? "Đang upload ảnh...",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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

class _ScanEffectPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanEffectPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw corner markers
    final cornerLength = size.width * 0.1;
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];

    for (int i = 0; i < 4; i++) {
      final corner = corners[i];
      final isLeft = i % 2 == 0;
      final isTop = i < 2;

      // Top-left
      if (i == 0) {
        canvas.drawLine(corner, Offset(corner.dx + cornerLength, corner.dy), paint);
        canvas.drawLine(corner, Offset(corner.dx, corner.dy + cornerLength), paint);
      }
      // Top-right
      if (i == 1) {
        canvas.drawLine(corner, Offset(corner.dx - cornerLength, corner.dy), paint);
        canvas.drawLine(corner, Offset(corner.dx, corner.dy + cornerLength), paint);
      }
      // Bottom-right
      if (i == 2) {
        canvas.drawLine(corner, Offset(corner.dx - cornerLength, corner.dy), paint);
        canvas.drawLine(corner, Offset(corner.dx, corner.dy - cornerLength), paint);
      }
      // Bottom-left
      if (i == 3) {
        canvas.drawLine(corner, Offset(corner.dx + cornerLength, corner.dy), paint);
        canvas.drawLine(corner, Offset(corner.dx, corner.dy - cornerLength), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}