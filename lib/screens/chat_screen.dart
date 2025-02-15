import 'package:flutter/material.dart';

import '../utils/recording_control.dart';
import 'components/mode_switch.dart';
import 'components/video_button.dart';
import 'components/mic_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RecordingControl _recordingControl = RecordingControl();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isVideoMode = true;

  @override
  void initState() {
    super.initState();
    _recordingControl.initializeRecorder();
  }

  Future<void> _startRecording() async {
    if (!_isProcessing && !_isRecording) {
      setState(() {
        _isRecording = true;
      });
      await _recordingControl.startRecording();
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      await _recordingControl.stopRecording();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleTap() async {
    if (_isProcessing) {
      await _recordingControl.stopAudioPlayback();
      setState(() {
        _isProcessing = false;
      });
    } else if (_isRecording) {
      await _stopRecording();
    } else {
      await _recordingControl.stopAudioPlayback();
      await _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpeakinAI'),
        actions: [
          ModeSwitch(
            isVideoMode: _isVideoMode,
            onChanged: (value) {
              setState(() {
                _isVideoMode = value;
              });
              debugPrint('モード切り替え: ${_isVideoMode ? "動画" : "音声"}');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isVideoMode
                ? VideoButton(
                    onTap: () {
                      debugPrint('録画ボタンが押されました');
                    },
                  )
                : MicButton(
                    isRecording: _isRecording,
                    isProcessing: _isProcessing,
                    onTapDown: _handleTap,
                    onTapUp: _handleTap,
                    onTapCancel: _handleTap,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recordingControl.record.dispose();
    super.dispose();
  }
}
