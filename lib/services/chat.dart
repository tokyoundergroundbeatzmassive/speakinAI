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

  // OpenAI Chat Completions API endpoint
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  static Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    List<String>? base64Images,
    int maxTokens = 1000,
  }) async {
    try {
      final systemMessage = {
        'role': 'system',
        'content': 'You are a conversation AI bot. Your output should be as short as possible.'
      };

      final url = Uri.parse(_apiUrl);

      // メッセージの準備
      if (messages.isEmpty || messages.first['role'] != 'system') {
        messages.insert(0, systemMessage);
      }

      // 最後のユーザーメッセージを取得
      final lastUserMessage = messages.lastWhere((msg) => msg['role'] == 'user');
      
      // リクエストボディの準備
      final Map<String, dynamic> requestBody = {
        'model': _model,
        'max_tokens': maxTokens,
      };

      if (base64Images != null && base64Images.isNotEmpty) {
        // 画像付きメッセージの場合
        requestBody['messages'] = [
          systemMessage,
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': lastUserMessage['content'],
              },
              ...base64Images.map((base64) => {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64'
                }
              }),
            ],
          }
        ];
      } else {
        // テキストのみの場合
        requestBody['messages'] = messages;
      }

      final response = await http.post(
        url,  // Uri.parse(url) から url に修正
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Response: ${utf8.decode(response.bodyBytes)}');
        return 'Error Occurred. Status code: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Exception occurred: $e');
      return 'Error Occurred: $e';
    }
  }
}
