import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../utils/app_paths.dart';
import '../utils/blur_detector.dart';

class VideoProcessor {
  VideoProcessor() {
    _initializeFFmpeg();
  }

  Future<void> _initializeFFmpeg() async {
    await FFmpegKitConfig.setLogLevel(0);
  }

  String? _currentVideoPath;
  // 録画開始時のパス設定
  Future<String> initializeVideoPath() async {
    _currentVideoPath = '${await AppPaths.videosPath}/temp_video.mp4';
    return _currentVideoPath!;
  }

  Future<List<String>> extractFrames(String videoPath) async {
    final baseOutputPath = await AppPaths.framesPath;
    
    debugPrint('フレーム抽出開始: $videoPath');
    final imageCommand = '-i $videoPath -vf fps=4 $baseOutputPath/frame_%d.jpg';
    
    try {
      final imageSession = await FFmpegKit.execute(imageCommand);
      final imageReturnCode = await imageSession.getReturnCode();
      
      if (ReturnCode.isSuccess(imageReturnCode)) {
        final frames = await getExtractedFrames();
        debugPrint('フレーム抽出完了: ${frames.length}枚');
        
        // ブレ検出とフィルタリングを追加
        final filteredFrames = await filterBlurryFrames(frames);
        debugPrint('フィルタリング後のフレーム:');
        for (final frame in filteredFrames) {
          debugPrint('- $frame');
        }
        
        return filteredFrames;  // フィルタリング済みのフレームを返す
      } else {
        throw Exception('フレーム抽出に失敗しました');
      }
    } catch (e) {
      debugPrint('フレーム抽出エラー: $e');
      rethrow;
    }
  }

  Future<String> extractAudio(String videoPath) async {
    final audioPath = '${await AppPaths.audioPath}/audio.m4a';
    
    debugPrint('音声抽出開始: $videoPath');
    // -y オプションを追加して強制上書きを有効化
    final audioCommand = '-y -i $videoPath -vn -acodec copy $audioPath';
    
    try {
      final audioSession = await FFmpegKit.execute(audioCommand);
      final audioReturnCode = await audioSession.getReturnCode();
      
      if (ReturnCode.isSuccess(audioReturnCode)) {
        debugPrint('音声抽出完了: $audioPath');
        return audioPath;
      } else {
        throw Exception('音声抽出に失敗しました');
      }
    } catch (e) {
      debugPrint('音声抽出エラー: $e');
      rethrow;
    }
  }

  // 生成されたファイルを取得
  Future<List<String>> getExtractedFrames() async {
    final directory = Directory(await AppPaths.framesPath);
    final files = directory.listSync()
        .where((file) => file.path.contains('frame_'))
        .map((file) => file.path)
        .toList();
    return files;
  }

  // 音声ファイルのパスを取得
  Future<String?> getExtractedAudio() async {
    final audioPath = '${await AppPaths.audioPath}/audio.m4a';
    if (await File(audioPath).exists()) {
      return audioPath;
    }
    return null;
  }

  Future<List<String>> filterBlurryFrames(List<String> framePaths, {double threshold = 80.0}) async {
    debugPrint('ブレ検出開始: ${framePaths.length}枚のフレームを分析');
    final filteredFrames = <String>[];
    
    for (final path in framePaths) {
      final blurScore = BlurDetector.detectBlur(path);
      if (blurScore >= threshold) {
        filteredFrames.add(path);
        debugPrint('フレーム採用: $path (ブレスコア: ${blurScore.toStringAsFixed(2)})');
      } else {
        await File(path).delete();
        debugPrint('フレーム削除: $path (ブレスコア: ${blurScore.toStringAsFixed(2)})');
      }
    }
    
    // 6枚以上ある場合は、最新の6枚だけを残す
    if (filteredFrames.length > 6) {
      // フレーム番号でソート
      filteredFrames.sort((a, b) {
        final aNum = int.parse(a.split('frame_')[1].split('.')[0]);
        final bNum = int.parse(b.split('frame_')[1].split('.')[0]);
        return bNum.compareTo(aNum); // 降順（新しい順）でソート
      });
      
      // 7枚目以降を削除
      for (var i = 6; i < filteredFrames.length; i++) {
        await File(filteredFrames[i]).delete();
        debugPrint('超過フレーム削除: ${filteredFrames[i]}');
      }
      
      filteredFrames.removeRange(6, filteredFrames.length);
    }
    
    debugPrint('ブレ検出完了:');
    debugPrint('- 元のフレーム数: ${framePaths.length}');
    debugPrint('- 採用フレーム数: ${filteredFrames.length}');
    debugPrint('- 削除フレーム数: ${framePaths.length - filteredFrames.length}');
    
    return filteredFrames;
  }
}