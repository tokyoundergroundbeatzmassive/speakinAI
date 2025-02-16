import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/video_processor.dart';

class CameraControl {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;
  final VideoProcessor _videoProcessor = VideoProcessor();

  Future<void> initializeCamera() async {
    if (_controller != null) return;

    debugPrint('カメラ初期化開始');
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('カメラが見つかりません');
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.veryHigh,  // 高解像度で録画
      enableAudio: true,
    );

    try {
      await _controller?.initialize();
      _isInitialized = true;
      debugPrint('カメラ初期化完了');
    } catch (e) {
      debugPrint('カメラ初期化エラー: $e');
    }
  }

  bool get isRecording => _isRecording;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  // 古い動画ファイルを削除（TODO: これは処理後に削除するように各機能をのちに移動する事）
  Future<void> _cleanupAllFiles() async {
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final tempDirectory = await getTemporaryDirectory();
      
      // 削除対象のディレクトリパス
      final paths = [
        '${appDirectory.path}/camera/videos',  // 動画ファイル
        '${tempDirectory.path}/frame_*.jpg',   // 画像ファイル - Cachesディレクトリに変更
        '${tempDirectory.path}/audio.m4a',      // 音声ファイル
      ];

      for (final path in paths) {
        if (path.contains('*')) {
          // 画像ファイルの削除（Cachesディレクトリ内）
          final dir = Directory(path.substring(0, path.lastIndexOf('/')));
          debugPrint('画像検索ディレクトリ: ${dir.path}');
          
          if (await dir.exists()) {
            final files = await dir
                .list()
                .where((entity) => 
                  entity.path.contains('frame_') || 
                  entity.path.contains('thumb_'))
                .toList();
            debugPrint('既存の画像ファイル数: ${files.length}');
            
            for (final file in files) {
              await file.delete();
              debugPrint('画像を削除: ${file.path}');
            }
          }
        } else if (path.endsWith('.m4a')) {
          // 音声ファイル
          final audioFile = File(path);
          if (await audioFile.exists()) {
            await audioFile.delete();
            debugPrint('音声ファイルを削除: ${audioFile.path}');
          }
        } else {
          // 動画ファイル用ディレクトリ
          final dir = Directory(path);
          if (await dir.exists()) {
            final files = await dir.list().toList();
            debugPrint('既存の動画ファイル数: ${files.length}');
            for (final file in files) {
              await file.delete();
              debugPrint('動画を削除: ${file.path}');
            }
          }
        }
      }
      
      debugPrint('全てのメディアファイルを削除しました');
    } catch (e) {
      debugPrint('ファイルクリーンアップエラー: $e');
    }
  }

  // 録画開始
  Future<void> startRecording() async {
    if (!_isInitialized || _controller == null) {
      debugPrint('カメラが初期化されていません');
      return;
    }

    if (_isRecording) {
      debugPrint('既に録画中です');
      return;
    }

    try {
      // 古いファイルのクリーンアップ
      await _cleanupAllFiles();

      final directory = await getApplicationDocumentsDirectory();

      // カメラの実際の解像度情報を取得
      final cameraResolution = _controller!.value.previewSize;
      const recordingResolution = ResolutionPreset.veryHigh; 

      // ディレクトリが存在しない場合は作成
      await Directory('${directory.path}/camera/videos').create(recursive: true);

      await _controller!.startVideoRecording();
      _isRecording = true;
      
      debugPrint('録画開始:');
      debugPrint('- カメラプレビュー解像度: ${cameraResolution?.width}x${cameraResolution?.height}');
      debugPrint('- 録画設定解像度: $recordingResolution');
      debugPrint('- カメラ詳細: ${_controller!.value.description}');
    } catch (e) {
      debugPrint('録画開始エラー: $e');
    }
  }

  // 録画停止とフレーム処理
  Future<String?> stopRecording() async {
    if (!_isRecording || _controller == null) {
      debugPrint('録画が開始されていません');
      return null;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      final videoPath = file.path;
      
      // ファイル情報を取得
      final videoFile = File(videoPath);
      final fileSize = await videoFile.length();
      final fileSizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      final fileStats = await videoFile.stat();
      
      debugPrint('録画完了:');
      debugPrint('- パス: $videoPath');
      debugPrint('- サイズ: ${fileSizeInMB}MB');
      debugPrint('- 作成日時: ${fileStats.modified}');

      // VideoProcessorで処理を開始
      debugPrint('録画ファイルの処理開始');
      try {
        final framesFuture = _videoProcessor.extractFrames(videoPath);  // パスを渡す
        final audioFuture = _videoProcessor.extractAudio(videoPath);    // パスを渡す
        
        final results = await Future.wait([framesFuture, audioFuture]);
        final frames = results[0] as List<String>;
        final audioPath = results[1] as String;
        
        debugPrint('処理完了:');
        debugPrint('- フレーム数: ${frames.length}');
        debugPrint('- 音声ファイル: $audioPath');
        
        return videoPath;
      } catch (processError) {
        debugPrint('ファイル処理エラー: $processError');
        return null;
      }
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      return null;
    }
  }

  void stopCamera() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    debugPrint('カメラ停止');
  }

  void dispose() {
    stopRecording();
    stopCamera();
  }
}