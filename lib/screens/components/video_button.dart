import 'package:flutter/material.dart';

class VideoButton extends StatelessWidget {
  final VoidCallback onTap;

  const VideoButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.blue, // 録画ボタン用の色（任意で変更してください）
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
        child: const Icon(
          Icons.videocam,
          size: 100,
          color: Colors.white,
        ),
      ),
    );
  }
}