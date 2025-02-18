import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../utils/camera_control.dart';
import 'blury_dialog.dart';

class VideoButton extends StatefulWidget {
  final CameraController? cameraController;
  final CameraControl cameraControl;

  const VideoButton({
    Key? key,
    required this.cameraControl,
    this.cameraController,
  }) : super(key: key);

  @override
  State<VideoButton> createState() => _VideoButtonState();
}

class _VideoButtonState extends State<VideoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return GestureDetector(
      onTapDown: (_) async {
        setState(() => _isPressed = true);
        await widget.cameraControl.startRecording();
      },
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        try {
          final videoPath = await widget.cameraControl.stopRecording();
          if (videoPath == null) return;
        } catch (e) {
          if (!context.mounted) return; // contextの mounted チェックに変更
          
          if (e.toString().contains('stable_camera_required')) {
            await WarningDialog.showStableCameraWarning(context);
          } else {
            await WarningDialog.showGeneralError(context, e.toString());
          }
        }
      },
      onTapCancel: () async {
        setState(() => _isPressed = false);
        await widget.cameraControl.stopRecording();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isPressed && widget.cameraController != null && widget.cameraController!.value.isInitialized)
            Container(
              width: size.width,
              height: size.height,
              color: Colors.black,
              child: CameraPreview(widget.cameraController!),
            ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _isPressed 
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
              _isPressed ? Icons.camera : Icons.camera_alt,
              size: 100,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}