import 'package:camera/camera.dart';
import 'package:flutter/material.dart'; // 追加
import 'dart:async';

class CameraControl {
  CameraController? _controller;
  bool _isInitialized = false;
  double _previewSize = 0;

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

  void stopCamera() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    debugPrint('カメラ停止');
  }

  void dispose() {
    stopCamera();
  }

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
}