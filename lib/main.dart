import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/detection_start_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/result_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VisionObjectApp());
}

class VisionObjectApp extends StatelessWidget {
  const VisionObjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.yellow[700],
      scaffoldBackgroundColor: Colors.black,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
    );

    return MaterialApp(
      title: 'Vision Object',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/start': (context) => const DetectionStartScreen(),
        '/camera': (context) => const CameraScreen(),
        '/result': (context) => const ResultScreen(),
      },
    );
  }
}
