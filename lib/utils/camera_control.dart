import 'package:camera/camera.dart';
import 'package:flutter/material.dart'; // 追加
import 'dart:async';
import '../services/video_processor.dart';

class CameraControl {
  CameraController? _controller;
  bool _isInitialized = false;
  double _previewSize = 0;
  final VideoProcessor _videoProcessor = VideoProcessor();
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
      ResolutionPreset.max,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      // まず初期化
      await _controller!.initialize();
      _isInitialized = true;

      // 追加設定の前にカメラ情報を出力
      final size = _controller!.value.previewSize;
      debugPrint('カメラ設定情報:'
          '\n  解像度: ${size?.width.toInt()} x ${size?.height.toInt()} pixels'
          '\n  プリセット: ${_controller!.resolutionPreset}'
          '\n  アスペクト比: ${(size?.width ?? 0) / (size?.height ?? 1)}'
      );

      // その後で追加設定
      await _controller?.setFocusMode(FocusMode.auto);
      await _controller?.setExposureMode(ExposureMode.auto);
      
      debugPrint('カメラ初期化完了');
    } catch (e) {
      debugPrint('カメラ初期化エラー: $e');
    }
  }

  Future<void> startVideoRecording() async {
    debugPrint('CameraControl: 録画開始処理開始');  // 追加
    if (_controller == null || !_isInitialized || _isRecording) {
      debugPrint('CameraControl: 録画開始条件未満 - controller: ${_controller != null}, initialized: $_isInitialized, recording: $_isRecording');  // 追加
      return;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      debugPrint('CameraControl: 録画開始成功');
    } catch (e) {
      debugPrint('CameraControl: 録画開始エラー: $e');
    }
  }

  Future<List<String>> stopVideoRecording() async {
    debugPrint('CameraControl: 録画停止処理開始');  // 追加
    if (!_isRecording) {
      debugPrint('CameraControl: 録画停止 - 録画中ではありません');  // 追加
      return [];
    }

    try {
      final videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;
      debugPrint('録画停止: ${videoFile.path}');

      // VideoProcessorを使用してフレームを抽出
      return await _videoProcessor.extractFrames(videoFile.path);
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      return [];
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