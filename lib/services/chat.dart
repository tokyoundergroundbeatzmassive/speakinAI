import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in .env file');
    }
    return key;
  }

  static const String _url = 'https://api.openai.com/v1/chat/completions';

  static Future<String> getChatResponse(List<Map<String, String>> messages,
      {int maxTokens = 100}) async {
    try {
      final systemMessage = {
        'role': 'system',
        'content':
            'You are a conversation AI bot. Your output should be as short as possible.'
      };

      if (messages.isEmpty || messages.first['role'] != 'system') {
        messages.insert(0, systemMessage);
      }

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Response: ${utf8.decode(response.bodyBytes)}');
        return 'Error Occured. Status code: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Exception occurred: $e');
      return 'Error Occured: $e';
    }
  }
}
