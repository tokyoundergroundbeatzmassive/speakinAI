import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TTSService {
  static String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in .env file');
    }
    return key;
  }

  static const String _url = 'https://api.openai.com/v1/audio/speech';

  static Future<String> generateSpeech(String text,
      {String voice = 'alloy'}) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'tts-1',
          'input': text,
          'voice': voice,
        }),
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/speech.mp3');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        print('Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception(
            'Failed to generate speech. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Failed to generate speech: $e');
    }
  }
}
