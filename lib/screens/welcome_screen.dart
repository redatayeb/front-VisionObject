import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();

    // On attend que l'UI soit affichée avant de parler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakIntro();
    });
  }

  Future<void> _speakIntro() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.40);       // 👈 plus lent
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true); // 👈 attend la fin

    await _tts.speak(
      "Welcome. I am your object detection assistant. "
      "I am here to help you understand what is around you using your camera. "
      "When you are ready, tap the Start button at the bottom of the screen and I will guide you.",
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CircleAvatar(
                backgroundColor: Colors.yellow[700],
                radius: 56,
                child: const Icon(
                  Icons.visibility,
                  size: 56,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Hey, I'm your object detection assistant.\n"
                "I'm here to help you understand what’s around you using your camera.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "When you’re ready, tap Start and I’ll begin detecting objects for you.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/start'),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
