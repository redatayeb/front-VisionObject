import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isReady = false;
  String _status = 'Initializing camera...';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // If running on desktop where plugin implementation is missing,
      // avoid calling the plugin and show a clear message instead.
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        setState(() {
          _status =
              'Camera not supported on this desktop build. Run on Android or iOS, or add desktop camera support.';
        });
        return;
      }

      final cameras = await availableCameras();
      final camera = cameras.isNotEmpty ? cameras.first : null;
      if (camera == null) {
        setState(() {
          _status = 'No camera found';
        });
        return;
      }
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      if (e is MissingPluginException) {
        setState(() {
          _status = 'Camera plugin not available on this platform.';
        });
      } else {
        setState(() {
          _status = 'Camera error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (!(_controller?.value.isInitialized ?? false)) return;
    try {
      await _controller!.takePicture();
      // Simulate detection result: in a real app, send picture path to model/service
      final detected = _simulateDetection();
      if (!mounted) return;
      Navigator.pushNamed(context, '/result', arguments: {'label': detected});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  String _simulateDetection() {
    // For demo purposes return a static label or random selection.
    const examples = ['Bottle', 'Chair', 'Phone', 'Book', 'Cup'];
    return (examples..shuffle()).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isReady && _controller != null
                  ? CameraPreview(_controller!)
                  : Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Text(
                        _status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Point your camera at an object',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.large(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                    onPressed: _capture,
                    child: const Icon(Icons.camera_alt, size: 36),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
