import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

class VideoProcessor {
  final List<String> _tempFilePaths = [];

  Future<List<String>> extractFrames(String videoPath) async {
    try {
      debugPrint('動画読み込み開始: $videoPath');
      final directory = await getTemporaryDirectory();
      final frames = <String>[];
      
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        debugPrint('動画ファイルが存在しません: $videoPath');
        return [];
      }

      // 一時ディレクトリの存在確認と作成
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      for (var i = 0; i < 3000; i += 500) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'thumb_${timestamp}_$i.jpg';
          final fullPath = '${directory.path}/$fileName';
          
          debugPrint('サムネイル生成開始:'
              '\n  時間: ${i/1000}秒'
              '\n  パス: $fullPath'
          );

          final thumbnail = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: fullPath,
            imageFormat: ImageFormat.JPEG,
            timeMs: i,
            quality: 100,
            maxHeight: 1080,
            maxWidth: 1920,
          );
        
          if (thumbnail != null) {
            final file = File(thumbnail);
            if (await file.exists()) {
              final fileSize = await file.length();
              debugPrint('サムネイル生成成功:'
                  '\n  時間: ${i/1000}秒'
                  '\n  サイズ: ${(fileSize / 1024).toStringAsFixed(2)} KB'
              );
              _tempFilePaths.add(thumbnail);
              frames.add(thumbnail);
            } else {
              debugPrint('警告: ファイルが生成されませんでした: $thumbnail');
            }
          }
        } catch (e) {
          debugPrint('個別のサムネイル生成エラー: $e');
          continue;
        }
      }

      debugPrint('フレーム抽出完了: ${frames.length}枚のフレームを保存');
      return frames;
    } catch (e) {
      debugPrint('フレーム抽出エラー: $e');
      return [];
    }
  }

  Future<void> dispose() async {
    for (final path in _tempFilePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('一時ファイル削除: $path');
        }
      } catch (e) {
        debugPrint('一時ファイル削除エラー: $e');
      }
    }
    _tempFilePaths.clear();
  }
}