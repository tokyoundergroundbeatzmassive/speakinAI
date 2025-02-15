import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

class VideoProcessor {
  VideoPlayerController? _videoPlayerController;
  final List<String> _tempFilePaths = [];  // 一時ファイルのパスを保持

  /// 動画ファイルからフレームを抽出する
  /// @param videoPath 動画ファイルのパス
  /// @return 抽出されたフレーム画像のパスリスト
  Future<List<String>> extractFrames(String videoPath) async {
    try {
      debugPrint('動画読み込み開始: $videoPath');
      _videoPlayerController = VideoPlayerController.file(File(videoPath));
      await _videoPlayerController!.initialize();
      
      final directory = await getTemporaryDirectory();
      final duration = _videoPlayerController!.value.duration;
      final frames = <String>[];
      
      debugPrint('動画の長さ: ${duration.inSeconds}秒');
      debugPrint('フレーム抽出開始');
      
      // 0.5秒間隔でフレームを抽出
      for (var i = 0; i < duration.inMilliseconds; i += 500) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await _videoPlayerController!.seekTo(Duration(milliseconds: i));
        final frameFile = File('${directory.path}/frame_${timestamp}_$i.jpg');
        
        // フレームのパスを保存
        _tempFilePaths.add(frameFile.path);
        frames.add(frameFile.path);
        debugPrint('フレーム保存 (${i/1000}秒): ${frameFile.path}');
      }

      debugPrint('フレーム抽出完了: ${frames.length}枚のフレームを保存');
      return frames;

    } catch (e) {
      debugPrint('フレーム抽出エラー: $e');
      return [];
    } finally {
      debugPrint('一時ファイルのクリーンアップ開始');
      await dispose();
      debugPrint('処理完了');
    }
  }

  Future<void> dispose() async {
    // VideoPlayerController の破棄
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

    // 一時ファイルの削除
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