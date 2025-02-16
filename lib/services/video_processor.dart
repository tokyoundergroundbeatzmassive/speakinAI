import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class VideoProcessor {
  String? _currentVideoPath;
  
  // 録画開始時のパス設定
  Future<String> initializeVideoPath() async {
    final directory = await getTemporaryDirectory();
    _currentVideoPath = '${directory.path}/temp_video.mp4';
    return _currentVideoPath!;
  }

  // フレーム抽出処理
  Future<List<String>> extractFrames() async {
    if (_currentVideoPath == null) throw Exception('ビデオパスが設定されていません');
    
    final directory = await getTemporaryDirectory();
    final baseOutputPath = directory.path;
    
    debugPrint('フレーム抽出開始');
    final imageCommand = '-i $_currentVideoPath -vf fps=2 $baseOutputPath/frame_%d.jpg';
    
    try {
      final imageSession = await FFmpegKit.execute(imageCommand);
      final imageReturnCode = await imageSession.getReturnCode();
      
      if (ReturnCode.isSuccess(imageReturnCode)) {
        final frames = await getExtractedFrames();
        debugPrint('フレーム抽出完了: ${frames.length}枚');
        return frames;
      } else {
        throw Exception('フレーム抽出に失敗しました');
      }
    } catch (e) {
      debugPrint('フレーム抽出エラー: $e');
      rethrow;
    }
  }

  // 音声抽出処理
  Future<String> extractAudio() async {
    if (_currentVideoPath == null) throw Exception('ビデオパスが設定されていません');
    
    final directory = await getTemporaryDirectory();
    final audioPath = '${directory.path}/audio.m4a';
    
    debugPrint('音声抽出開始');
    final audioCommand = '-i $_currentVideoPath -vn -acodec copy $audioPath';
    
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
    final directory = await getTemporaryDirectory();
    final files = directory.listSync()
        .where((file) => file.path.contains('frame_'))
        .map((file) => file.path)
        .toList();
    return files;
  }

  // 音声ファイルのパスを取得
  Future<String?> getExtractedAudio() async {
    final directory = await getTemporaryDirectory();
    final audioPath = '${directory.path}/audio.m4a';
    if (await File(audioPath).exists()) {
      return audioPath;
    }
    return null;
  }
}