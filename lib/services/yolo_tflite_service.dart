import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class BBox {
  final double x1, y1, x2, y2;

  BBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
}

class DetectionResult {
  final String className;
  final double confidence;
  final BBox bbox;

  DetectionResult({
    required this.className,
    required this.confidence,
    required this.bbox,
  });
}

class DetectionResponse {
  final int imageWidth;
  final int imageHeight;
  final List<DetectionResult> detections;

  DetectionResponse({
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
  });
}

class YoloApiService {
  // ⚠️ ADAPTE CETTE URL :
  // - Téléphone physique : IP de ton PC (même WiFi) + port 8000
  //   Exemple : 'http://192.168.1.15:8000'
  final String baseUrl = 'http://192.168.1.23:8000'; // <--- change l'IP ici

  Future<DetectionResponse> detectObjects(File imageFile) async {
    final uri = Uri.parse('$baseUrl/detect');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur API ${response.statusCode}: ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    final imageWidth = data['image_width'] as int;
    final imageHeight = data['image_height'] as int;

    final detectionsJson = data['detections'] as List<dynamic>;

    final detections = detectionsJson.map((d) {
      final map = d as Map<String, dynamic>;
      final bbox = map['bbox'] as Map<String, dynamic>;

      return DetectionResult(
        className: map['class_name'] as String,
        confidence: (map['confidence'] as num).toDouble(),
        bbox: BBox(
          x1: (bbox['x1'] as num).toDouble(),
          y1: (bbox['y1'] as num).toDouble(),
          x2: (bbox['x2'] as num).toDouble(),
          y2: (bbox['y2'] as num).toDouble(),
        ),
      );
    }).toList();

    return DetectionResponse(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      detections: detections,
    );
  }
}
