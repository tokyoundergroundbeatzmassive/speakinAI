import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AppPaths {
  /// ビデオ関連のパス
  static Future<String> get videosPath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/camera/videos';
  }

  /// フレーム画像のパス
  static Future<String> get framesPath async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  /// 音声ファイルのパス
  static Future<String> get audioPath async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  /// 一時ディレクトリの存在確認
  static Future<void> ensureDirectoriesExist() async {
    final tempDir = Directory(await videosPath);
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
  }
}