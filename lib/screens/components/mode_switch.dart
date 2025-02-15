import 'package:flutter/material.dart';

class ModeSwitch extends StatelessWidget {
  final bool isVideoMode;
  final ValueChanged<bool> onChanged;

  const ModeSwitch({
    Key? key,
    required this.isVideoMode,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text("音声"),
        Switch(
          value: isVideoMode,
          onChanged: onChanged,
        ),
        const Text("動画"),
        const SizedBox(width: 8),
      ],
    );
  }
}