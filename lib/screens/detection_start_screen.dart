import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DetectionStartScreen extends StatefulWidget {
  const DetectionStartScreen({super.key});

  @override
  State<DetectionStartScreen> createState() => _DetectionStartScreenState();
}

class _DetectionStartScreenState extends State<DetectionStartScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speakDetectionIntro();
  }

  Future<void> _speakDetectionIntro() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.40);
    await _tts.setVolume(1.0);

    await _tts.speak(
      "Hey! I'm your object detection assistant. "
      "I'm here to help you. When you're ready, tap the Start Detection button."
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Object Detection',
          style: TextStyle(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Hey, I'm your object detection assistant.\n"
                  "I'm here to help you. When you’re ready, tap the button below to start detection.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/camera'),
                    child: const Text(
                      'Start Detection',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
