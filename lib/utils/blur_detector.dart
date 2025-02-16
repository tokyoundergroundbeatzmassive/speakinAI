import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class BlurDetector {
  // ROI（Region of Interest）を使用して中央部分のみを評価
  static double detectBlur(String imagePath) {
    try {
      final image = img.decodeImage(File(imagePath).readAsBytesSync());
      if (image == null) throw Exception('画像の読み込みに失敗しました');

      // 画像中央の領域のみを評価
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      const roiSize = 300; // ROIのサイズ

      final croppedImage = img.copyCrop(
        image,  // 位置引数として渡す
        x: centerX - roiSize ~/ 2,
        y: centerY - roiSize ~/ 2,
        width: roiSize,
        height: roiSize,
      );

      final grayscale = img.grayscale(croppedImage);
      final laplacian = _applyLaplacian(grayscale);
      final variance = _calculateVariance(laplacian);

      debugPrint('ブレ検出スコア ($imagePath): $variance');
      return variance;
    } catch (e) {
      debugPrint('ブレ検出エラー: $e');
      return 0.0;
    }
  }

  /// ラプラシアンフィルタを適用
  static List<List<double>> _applyLaplacian(img.Image image) {
    final kernel = [
      [0.0, 1.0, 0.0],
      [1.0, -4.0, 1.0],
      [0.0, 1.0, 0.0]
    ];
    
    final result = List.generate(
      image.height, 
      (y) => List.filled(image.width, 0.0)
    );

    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        var sum = 0.0;
        for (var ky = -1; ky <= 1; ky++) {
          for (var kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky).r;
            sum += pixel * kernel[ky + 1][kx + 1];
          }
        }
        result[y][x] = sum;
      }
    }
    return result;
  }

  /// 分散を計算
  static double _calculateVariance(List<List<double>> matrix) {
    var sum = 0.0;
    var count = 0;
    var sumSquared = 0.0;

    for (var row in matrix) {
      for (var value in row) {
        sum += value;
        sumSquared += value * value;
        count++;
      }
    }

    final mean = sum / count;
    final variance = (sumSquared / count) - (mean * mean);
    return variance;
  }
}