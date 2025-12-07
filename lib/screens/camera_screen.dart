import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/yolo_tflite_service.dart'; // 👈 IMPORTANT

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final YoloApiService _yoloApi = YoloApiService();
  final FlutterTts _tts = FlutterTts();

  bool _isCameraReady = false;
  bool _isProcessing = false;

  String _status = "Initializing camera...";
  String _lastLabel = "No objects detected yet.";
  String _lastSpoken = "";

  Timer? _loopTimer;

  static const double _MIN_CONFIDENCE = 0.65;

  List<DetectionResult> _lastDetections = [];
  int _imageWidth = 0;
  int _imageHeight = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.40); // 👈 plus lent pour accessibilité
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  // === CAMERA ===
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _isCameraReady = false;
        _status = "Camera permission denied.";
      });
      await _speak("Camera permission is denied.");
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _status = "No camera found.";
        });
        await _speak("No camera was found on this device.");
        return;
      }

      final camera = cameras.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
        _status = "Automatic detection is running...";
      });

      await _speak(
        "Camera is ready. I am now detecting objects in front of you.",
      );

      // 🔁 auto detection loop
      _startAutoDetectionLoop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = "Camera error.";
      });
      await _speak("There was a camera error.");
    }
  }

  void _startAutoDetectionLoop() {
    _loopTimer?.cancel();

    _loopTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _detectOnce();
    });
  }

  // === ONE DETECTION ITERATION ===
  Future<void> _detectOnce() async {
    if (!_isCameraReady || _isProcessing || _controller == null) return;
    if (!_controller!.value.isInitialized) return;

    _isProcessing = true;

    try {
      final picture = await _controller!.takePicture();
      final file = File(picture.path);

      final resp = await _yoloApi.detectObjects(file);

      final detections = resp.detections;
      final imgW = resp.imageWidth;
      final imgH = resp.imageHeight;

      // keep only confident results
      final strongDetections =
          detections.where((d) => d.confidence >= _MIN_CONFIDENCE).toList();

      String uiLabel;
      String voiceText;

      if (strongDetections.isEmpty) {
        uiLabel = "No object detected.";
        voiceText = "No object detected.";
      } else {
        final count = strongDetections.length;
        final names = strongDetections.map((d) => d.className).toSet().toList();

        uiLabel = "$count object(s) detected: ${names.join(', ')}";

        // Pour l'audio, phrase simple :
        if (count == 1) {
          voiceText = "I see one ${names.first}.";
        } else {
          voiceText = "I see $count objects: ${names.join(', ')}.";
        }
      }

      if (!mounted) return;

      setState(() {
        _imageWidth = imgW;
        _imageHeight = imgH;
        _lastDetections = strongDetections;
        _lastLabel = uiLabel;
      });

      // speak only if message changed
      if (voiceText != _lastSpoken) {
        _lastSpoken = voiceText;
        await _speak(voiceText);
      }
    } catch (e) {
      debugPrint("Error during detection: $e");
      if (mounted) {
        setState(() {
          _status = "Detection error.";
        });
      }
      await _speak("There was an error during detection.");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _loopTimer?.cancel();

    try {
      _controller?.dispose();
    } catch (e) {
      debugPrint("Error disposing camera: $e");
    }

    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _isCameraReady &&
        _controller != null &&
        _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Preview + rectangles, or status message
          Positioned.fill(
            child: ready
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      if (_lastDetections.isNotEmpty &&
                          _imageWidth > 0 &&
                          _imageHeight > 0)
                        CustomPaint(
                          painter: DetectionPainter(
                            detections: _lastDetections,
                            imageWidth: _imageWidth,
                            imageHeight: _imageHeight,
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Text(
                      _status,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),

          // Back button
          Positioned(
            left: 16,
            top: 16,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          // Bottom banner: status + last label
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastLabel,
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Automatic object detection with YOLO11",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === CustomPainter to draw bounding boxes + class names ===

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final int imageWidth;
  final int imageHeight;

  DetectionPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.yellow;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final det in detections) {
      final b = det.bbox;

      final left = b.x1 * scaleX;
      final top = b.y1 * scaleY;
      final right = b.x2 * scaleX;
      final bottom = b.y2 * scaleY;

      final rect = Rect.fromLTRB(left, top, right, bottom);

      canvas.drawRect(rect, boxPaint);

      final textSpan = TextSpan(
        text: det.className,
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.text = textSpan;
      textPainter.layout();

      final textOffset = Offset(left, top - textPainter.height - 4);

      // background for label
      canvas.drawRect(
        Rect.fromLTWH(
          textOffset.dx,
          textOffset.dy,
          textPainter.width + 6,
          textPainter.height + 4,
        ),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black54,
      );

      textPainter.paint(canvas, textOffset + const Offset(3, 2));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}
