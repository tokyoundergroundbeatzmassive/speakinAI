import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../utils/camera_control.dart'; 

class VideoButton extends StatelessWidget {
  final bool isPressed;
  final Function(bool) onPressedChanged;
  final CameraController? cameraController;
  final VoidCallback? onTap;
  final CameraControl cameraControl;

  const VideoButton({
    Key? key,
    required this.isPressed,
    required this.onPressedChanged,
    required this.cameraControl,
    this.cameraController,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('VideoButton: build開始');
    cameraControl.setPreviewSize(context);

    return GestureDetector(
      onTapDown: (_) async {
        debugPrint('VideoButton: タップダウン');
        onPressedChanged(true);
        onTap?.call();
        // 録画開始処理を追加
        await cameraControl.startVideoRecording();
      },
      onTapUp: (_) async {
        debugPrint('VideoButton: タップアップ');
        onPressedChanged(false);
        // 録画停止処理を追加
        final frames = await cameraControl.stopVideoRecording();
        debugPrint('抽出されたフレーム数: ${frames.length}');
      },
      onTapCancel: () async {
        debugPrint('VideoButton: タップキャンセル');
        onPressedChanged(false);
        // キャンセル時も録画を停止
        await cameraControl.stopVideoRecording();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isPressed && cameraController != null && cameraController!.value.isInitialized)
            SizedBox(
              width: cameraControl.previewSize,
              height: cameraControl.previewSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CameraPreview(cameraController!),
              ),
            ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: isPressed 
                ? const Color.fromRGBO(244, 67, 54, 0.5)
                : Colors.blue,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isPressed ? Icons.camera : Icons.camera_alt,
              size: 100,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}