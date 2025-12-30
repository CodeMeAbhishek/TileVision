import 'dart:typed_data';

class FloorMask {
  final Uint8List maskData;
  final String base64Encoded;
  final double confidence;
  final int width;
  final int height;

  FloorMask({
    required this.maskData,
    required this.base64Encoded,
    required this.confidence,
    required this.width,
    required this.height,
  });

  /// Create a FloorMask from base64 string
  factory FloorMask.fromBase64(
    String base64String,
    double confidence, {
    int? width,
    int? height,
  }) {
    final bytes = Uint8List.fromList(base64String.codeUnits);
    
    return FloorMask(
      maskData: bytes,
      base64Encoded: base64String,
      confidence: confidence,
      width: width ?? 0,
      height: height ?? 0,
    );
  }

  /// Create a FloorMask from JSON
  factory FloorMask.fromJson(Map<String, dynamic> json) {
    return FloorMask(
      maskData: Uint8List.fromList(json['mask'].codeUnits),
      base64Encoded: json['mask'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
    );
  }

  /// Convert FloorMask to JSON
  Map<String, dynamic> toJson() {
    return {
      'mask': base64Encoded,
      'confidence': confidence,
      'width': width,
      'height': height,
    };
  }

  @override
  String toString() {
    return 'FloorMask(confidence: ${(confidence * 100).toStringAsFixed(1)}%, size: ${width}x$height)';
  }
}
