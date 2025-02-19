import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import '../utils/app_paths.dart';
import '../utils/blur_detector.dart';

class VideoProcessor {
  String? _currentVideoPath;

  Future<String> initializeVideoPath() async {
    _currentVideoPath = '${await AppPaths.videosPath}/temp_video.mp4';
    return _currentVideoPath!;
  }

  Future<List<String>> extractFrames(String videoPath) async {
    final baseOutputPath = await AppPaths.framesPath;
    debugPrint('フレーム抽出開始...');
    
    try {
      List<String> frames = [];
      // 1秒あたり4フレームを抽出
      for (int i = 0; i < 6; i++) {
        final thumbnail = await VideoCompress.getFileThumbnail(
          videoPath,
          quality: 50,
          position: i * 250, // 250ミリ秒ごとにフレームを取得
        );
        
        final framePath = '$baseOutputPath/frame_$i.jpg';
        await File(thumbnail.path).copy(framePath);
        frames.add(framePath);
      }
      
      debugPrint('フレーム抽出完了: ${frames.length}枚');
      final filteredFrames = await filterBlurryFrames(frames);
      return filteredFrames;
      
    } catch (e) {
      debugPrint('フレーム抽出エラー: $e');
      rethrow;
    }
  }

  Future<String> extractAudio(String videoPath) async {
    final audioPath = '${await AppPaths.audioPath}/audio.m4a';
    debugPrint('音声抽出開始...');
    
    try {
      final mediaInfo = await VideoCompress.compressVideo(
        videoPath,
        includeAudio: true,
        quality: VideoQuality.MediumQuality,
      );
      
      if (mediaInfo?.path != null) {
        // 圧縮された動画から音声を取り出す
        final file = File(mediaInfo!.path!);
        await file.copy(audioPath);
        debugPrint('音声抽出完了');
        // debugPrint(audioPath);
        return audioPath;
      } else {
        throw Exception('音声抽出に失敗しました');
      }
    } catch (e) {
      debugPrint('音声抽出エラー: $e');
      rethrow;
    }
  }

  Future<List<String>> filterBlurryFrames(List<String> framePaths, {double threshold = 80.0}) async {
    debugPrint('ブレ検出開始: ${framePaths.length}枚のフレームを分析');
    final filteredFrames = <String>[];
    
    for (final path in framePaths) {
      final blurScore = BlurDetector.detectBlur(path);
      if (blurScore >= threshold) {
        filteredFrames.add(path);
      } else {
        await File(path).delete();
      }
    }
    
    debugPrint('ブレ検出完了:');
    debugPrint('- 元のフレーム数: ${framePaths.length}');
    debugPrint('- 採用フレーム数: ${filteredFrames.length}');
    debugPrint('- 削除フレーム数: ${framePaths.length - filteredFrames.length}');
    
    return filteredFrames;
  }

  Future<String?> getExtractedAudio() async {
    final audioPath = '${await AppPaths.audioPath}/audio.m4a';
    if (await File(audioPath).exists()) {
      return audioPath;
    }
    return null;
  }
}