import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class STTService {
  static String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in .env file');
    }
    return key;
  }

  static const String _url = 'https://api.openai.com/v1/audio/transcriptions';

  static Future<String> transcribe(File audioFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(_url));
    request.headers.addAll({
      'Authorization': 'Bearer $_apiKey',
    });

    request.files
        .add(await http.MultipartFile.fromPath('file', audioFile.path));
    request.fields['model'] = 'whisper-1';

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);
      return jsonResponse['text'];
    } else {
      throw Exception('Failed to transcribe audio');
    }
  }
}
