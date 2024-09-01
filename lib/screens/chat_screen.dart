import 'package:flutter/material.dart';

import '../utils/recording_control.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RecordingControl _recordingControl = RecordingControl();
  bool _isRecording = false;
  bool _isProcessing = false;

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
      ),
      body: Center(
        child: GestureDetector(
          onTapDown: (_) => _handleTap(),
          onTapUp: (_) => _handleTap(),
          onTapCancel: () => _handleTap(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.green
                  : (_isProcessing ? Colors.yellow : Colors.red),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    size: 100,
                    color: Colors.white,
                  ),
          ),
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
