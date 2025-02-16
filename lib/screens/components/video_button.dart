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
    final size = MediaQuery.of(context).size;
    
    return GestureDetector(
      onTapDown: (_) async {
        onPressedChanged(true);
        await cameraControl.startRecording();
      },
      onTapUp: (_) async {
        onPressedChanged(false);
        final videoPath = await cameraControl.stopRecording();
        debugPrint('録画完了: $videoPath');
      },
      onTapCancel: () async {
        onPressedChanged(false);
        await cameraControl.stopRecording();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isPressed && cameraController != null && cameraController!.value.isInitialized)
            Container(
              width: size.width,
              height: size.height,
              color: Colors.black,
              child: CameraPreview(cameraController!),
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