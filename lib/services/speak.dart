import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SpeakService {
  static AudioPlayer? _audioPlayer;

  static Future<void> playAudio(String filePath) async {
    try {
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();

      await _audioPlayer!.play(DeviceFileSource(filePath));

      _audioPlayer!.onPlayerComplete.listen((event) {
        _audioPlayer!.dispose();
        _audioPlayer = null;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      rethrow;
    }
  }

  static Future<void> stopAudio() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
    } catch (e) {
      debugPrint('Error stopping audio: $e');
      rethrow;
    }
  }
}
