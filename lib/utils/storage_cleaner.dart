import 'dart:io';
import 'package:flutter/material.dart';
import 'app_paths.dart';

class StorageCleaner {
  /// ファイル削除関連
  static Future<void> deleteVideos() async {
    final videoDir = Directory(await AppPaths.videosPath);
    if (await videoDir.exists()) {
      await for (final file in videoDir.list()) {
        // システムディレクトリはスキップ
        if (file.path.contains('com.apple') || file is Directory) {
          continue;
        }
        
        await file.delete();
        debugPrint('動画を削除: ${file.path}');
      }
    }
  }

  static Future<void> deleteFrames() async {
    final frameDir = Directory(await AppPaths.framesPath);
    if (await frameDir.exists()) {
      await for (final file in frameDir.list()) {
        if (file.path.toLowerCase().endsWith('.jpg') || 
            file.path.toLowerCase().endsWith('.jpeg')) {
          await file.delete();
          debugPrint('フレームを削除: ${file.path}');
        }
      }
    }
  }

  static Future<void> deleteAudio() async {
    final audioDir = Directory(await AppPaths.audioPath);
    if (await audioDir.exists()) {
      await for (final file in audioDir.list()) {
        if (file.path.endsWith('.m4a') || file.path.endsWith('.mp3')) {
          await file.delete();
          debugPrint('音声を削除: ${file.path}');
        }
      }
    }
  }

  /// 全ファイルのクリーンアップ
  static Future<void> cleanup() async {
    try {
      await deleteVideos();
      await deleteFrames();
      await deleteAudio();
      debugPrint('クリーンアップ完了');
    } catch (e, stackTrace) {
      debugPrint('クリーンアップエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }
}