import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../services/video_processor.dart';
import 'storage_cleaner.dart';
import '../services/stt.dart';
import '../utils/message_manager.dart';
import '../services/chat.dart';
import '../services/tts.dart';
import '../services/speak.dart';
import '../utils/images2base64.dart';

class CameraControl {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;
  final VideoProcessor _videoProcessor = VideoProcessor();
  List<Map<String, String>> _messages = [];

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
      ResolutionPreset.veryHigh,
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
      await StorageCleaner.cleanup();

      // カメラの実際の解像度情報を取得
      final cameraResolution = _controller!.value.previewSize;
      const recordingResolution = ResolutionPreset.veryHigh;

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
        final framesFuture = _videoProcessor.extractFrames(videoPath);
        final audioFuture = _videoProcessor.extractAudio(videoPath);
        
        final results = await Future.wait([framesFuture, audioFuture]);
        final frames = results[0] as List<String>;
        debugPrint('フレームの再確認: $frames');
        final audioPath = results[1] as String;

        // フレームが空の場合はエラーを投げる
        if (frames.isEmpty) {
          throw Exception('stable_camera_required');
        }

        // 文字起こしと会話処理を追加
        final transcription = await STTService.transcribe(File(audioPath));
        if (transcription.isNotEmpty) {
          debugPrint('文字起こし完了: $transcription');
          
          // フレームをbase64に変換（メッセージ追加の前に実行）
          final base64Images = Images2Base64.imagesToBase64(frames);
          debugPrint('画像変換完了: ${base64Images.length}枚');
          
          // メッセージを追加
          _messages.add({'role': 'user', 'content': transcription});
          _messages = MessageManager.manageMessages(_messages);

          // AI応答を取得（画像付き）
          debugPrint('AI応答を取得中...');
          final aiResponse = await ChatService.getChatResponse(
            _messages,
            base64Images: base64Images,  // base64画像を追加
          );
          debugPrint('AI応答: $aiResponse');

          _messages.add({'role': 'assistant', 'content': aiResponse});
          debugPrint('Conversation History: $_messages');
          _messages = MessageManager.manageMessages(_messages);

          // 音声合成と再生を追加
          debugPrint('AI応答を音声合成中...');
          final speechPath = await TTSService.generateSpeech(aiResponse);
          debugPrint('音声合成完了: $speechPath');

          await SpeakService.playAudio(speechPath);
          debugPrint('音声再生中...');
        } else {
          debugPrint('文字起こし結果が空です');
        }
        
        debugPrint('処理完了:');
        debugPrint('- フレーム数: ${frames.length}');
        debugPrint('- 音声ファイル: $audioPath');
        
        return videoPath;
      } catch (processError) {
        debugPrint('ファイル処理エラー: $processError');
        rethrow;  // エラーを上位に伝播
      }
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      rethrow;  // エラーを上位に伝播
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