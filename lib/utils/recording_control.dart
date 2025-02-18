import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/chat.dart';
import '../services/speak.dart';
import '../services/stt.dart';
import '../services/tts.dart';
import '../utils/message_manager.dart';
import '../utils/app_paths.dart';
import '../utils/storage_cleaner.dart';

class RecordingControl {
  final Record record = Record();
  bool _isRecording = false;
  List<Map<String, String>> _messages = [];

  Future<void> initializeRecorder() async {
    try {
      if (await record.hasPermission()) {
        debugPrint('Microphone permission granted');
      } else {
        debugPrint('Microphone permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  Future<void> startRecording() async {
    try {
      // 実行前にファイルのクリーンアップ
      await StorageCleaner.cleanup();

      debugPrint('Starting recording...');
      if (await record.hasPermission()) {
        // AppPathsを使用して音声ファイルのパスを取得
        final path = '${await AppPaths.audioPath}/audio.m4a';
        debugPrint('Recording to path: $path');
        await record.start(path: path);
        _isRecording = true;
        debugPrint('Recording started successfully');
      } else {
        debugPrint('No permission to record audio');
      }
    } catch (e, stackTrace) {
      debugPrint('Error starting recording: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> stopRecording() async {
    try {
      debugPrint('Stopping recording...');
      final path = await record.stop();
      _isRecording = false;
      debugPrint('Recording stopped. File path: $path');
      
      if (path != null) {
        debugPrint('Transcribing audio...');
        final transcription = await STTService.transcribe(File(path));
        debugPrint('Transcription: $transcription');

        _messages.add({'role': 'user', 'content': transcription});
        _messages = MessageManager.manageMessages(_messages);

        debugPrint('Getting AI response...');
        final aiResponse = await ChatService.getChatResponse(_messages);
        debugPrint('AI Response: $aiResponse');

        _messages.add({'role': 'assistant', 'content': aiResponse});
        debugPrint('Conversation History: $_messages');

        _messages = MessageManager.manageMessages(_messages);

        debugPrint('Generating speech from AI response...');
        final speechPath = await TTSService.generateSpeech(aiResponse);
        debugPrint('Speech generated. File path: $speechPath');

        await SpeakService.playAudio(speechPath);
        debugPrint('Playing audio...');

        // StorageCleanerを使用してファイル削除
        await StorageCleaner.deleteAudio();
        debugPrint('Temporary audio files cleaned up');
      } else {
        debugPrint('No audio file was recorded');
      }
    } catch (e, stackTrace) {
      debugPrint('Error stopping recording: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> stopAudioPlayback() async {
    await SpeakService.stopAudio();
  }

  bool get isRecording => _isRecording;
}
