import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/chat.dart';
import '../services/speak.dart';
import '../services/stt.dart';
import '../services/tts.dart';
import '../utils/message_manager.dart';

class RecordingControl {
  final Record record = Record();
  bool _isRecording = false;
  List<Map<String, String>> _messages = [];

  Future<void> initializeRecorder() async {
    try {
      if (await record.hasPermission()) {
        print('Microphone permission granted');
      } else {
        print('Microphone permission denied');
      }
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<void> startRecording() async {
    try {
      print('Starting recording...');
      if (await record.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/audio.m4a';
        print('Recording to path: $path');
        await record.start(path: path);
        _isRecording = true;
        print('Recording started successfully');
      } else {
        print('No permission to record audio');
      }
    } catch (e, stackTrace) {
      print('Error starting recording: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> stopRecording() async {
    try {
      print('Stopping recording...');
      final path = await record.stop();
      _isRecording = false;
      print('Recording stopped. File path: $path');
      if (path != null) {
        print('Transcribing audio...');
        final transcription = await STTService.transcribe(File(path));
        print('Transcription: $transcription');

        _messages.add({'role': 'user', 'content': transcription});

        _messages = MessageManager.manageMessages(_messages);

        print('Getting AI response...');
        final aiResponse = await ChatService.getChatResponse(_messages);
        print('AI Response: $aiResponse');

        _messages.add({'role': 'assistant', 'content': aiResponse});
        print('Conversation History: $_messages');

        _messages = MessageManager.manageMessages(_messages);

        print('Generating speech from AI response...');
        final speechPath = await TTSService.generateSpeech(aiResponse);
        print('Speech generated. File path: $speechPath');

        await SpeakService.playAudio(speechPath);
        print('Playing audio...');

        await _deleteFile(speechPath);
        print('Speech file deleted');

        await _deleteFile(path);
      } else {
        print('No audio file was recorded');
      }
    } catch (e, stackTrace) {
      print('Error stopping recording: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> stopAudioPlayback() async {
    await SpeakService.stopAudio();
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Deleted file: $filePath');
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  bool get isRecording => _isRecording;
}
