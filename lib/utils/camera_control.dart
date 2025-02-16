import 'package:camera/camera.dart';
import 'package:flutter/material.dart'; // 追加
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CameraControl {
  CameraController? _controller;
  bool _isInitialized = false;
  double _previewSize = 0;
  String? _videoPath;
  bool _isRecording = false;

  // プレビューサイズのゲッター
  double get previewSize => _previewSize;

  // プレビューサイズを設定するメソッド
  void setPreviewSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _previewSize = size.shortestSide * 1.0;  // 画面の短い方のサイズに設定
  }

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
      ResolutionPreset.medium,
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

  // 録画状態のゲッター
  bool get isRecording => _isRecording;

  // 古い動画ファイルを削除
  Future<void> _cleanupOldVideos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/camera/videos');
      
      if (await videoDir.exists()) {
        final files = await videoDir.list().toList();
        debugPrint('既存の動画ファイル数: ${files.length}');
        
        // 全ての動画ファイルを削除
        for (final file in files) {
          await file.delete();
          debugPrint('動画を削除: ${file.path}');
        }
        
        debugPrint('全ての動画ファイルを削除しました');
      }
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
      await _cleanupOldVideos();

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now();
      final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';
      
      _videoPath = '${directory.path}/camera/videos/video_$dateStr.mp4';
      
      // ディレクトリが存在しない場合は作成
      await Directory('${directory.path}/camera/videos').create(recursive: true);

      await _controller!.startVideoRecording();
      _isRecording = true;
      
      debugPrint('録画開始:');
      debugPrint('- パス: $_videoPath');
      debugPrint('- 日時: $timestamp');
      debugPrint('- サイズ: ${_previewSize}x${_previewSize}');
    } catch (e) {
      debugPrint('録画開始エラー: $e');
    }
  }

  // 録画停止
  Future<String?> stopRecording() async {
    if (!_isRecording || _controller == null) {
      debugPrint('録画が開始されていません');
      return null;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      debugPrint('録画停止: ${file.path}');
      return file.path;
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

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
}