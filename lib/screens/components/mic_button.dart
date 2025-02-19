import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const MicButton({
    Key? key,
    required this.isRecording,
    required this.isProcessing,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => onTapCancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: isRecording
              ? Colors.green
              : (isProcessing ? Colors.yellow : Colors.red),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(76),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Icon(
                isRecording ? Icons.mic : Icons.mic_none,
                size: 100,
                color: Colors.white,
              ),
      ),
    );
  }
}