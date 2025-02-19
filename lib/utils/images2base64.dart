import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class Images2Base64 {
  // 単一の画像をbase64に変換
  static String imageToBase64(String imagePath) {
    try {
      final bytes = File(imagePath).readAsBytesSync();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('画像のbase64変換エラー: $e');
      return '';
    }
  }

  // 複数の画像をbase64に変換
  static List<String> imagesToBase64(List<String> imagePaths) {
    try {
      debugPrint('画像をbase64に変換...');
      final base64Images = imagePaths.map((path) {
        return imageToBase64(path);
      }).where((base64) => base64.isNotEmpty).toList();

      debugPrint('変換完了: ${base64Images.length}枚の画像');
      return base64Images;
    } catch (e) {
      debugPrint('複数画像の変換エラー: $e');
      return [];
    }
  }
}