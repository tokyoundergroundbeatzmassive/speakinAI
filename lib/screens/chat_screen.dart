import 'package:flutter/material.dart';

import '../utils/recording_control.dart';
import '../utils/camera_control.dart';
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
  final CameraControl _cameraControl = CameraControl();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isVideoMode = true;

  @override
  void initState() {
    super.initState();
    _recordingControl.initializeRecorder();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraControl.initializeCamera();
    setState(() {});
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
            Expanded( // カメラプレビューを利用可能なスペースに合わせる
              child: _isVideoMode
                  ? VideoButton(
                      cameraControl: _cameraControl,
                      cameraController: _cameraControl.controller,
                    )
                  : MicButton(
                      isRecording: _isRecording,
                      isProcessing: _isProcessing,
                      onTapDown: _handleTap,
                      onTapUp: _handleTap,
                      onTapCancel: _handleTap,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recordingControl.record.dispose();
    _cameraControl.dispose();
    super.dispose();
  }
}
