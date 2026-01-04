import 'dart:convert';

class Project {
  final String id;
  final String originalImagePath;
  final String resultImageBase64;
  final String? maskBase64;
  final String tileName;
  final int tileId;
  final String tileSize;
  final double tilePrice;
  final DateTime createdAt;
  final String? notes;

  Project({
    required this.id,
    required this.originalImagePath,
    required this.resultImageBase64,
    this.maskBase64,
    required this.tileName,
    required this.tileId,
    required this.tileSize,
    required this.tilePrice,
    required this.createdAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalImagePath': originalImagePath,
      'resultImageBase64': resultImageBase64,
      'maskBase64': maskBase64,
      'tileName': tileName,
      'tileId': tileId,
      'tileSize': tileSize,
      'tilePrice': tilePrice,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      originalImagePath: json['originalImagePath'] as String,
      resultImageBase64: json['resultImageBase64'] as String,
      maskBase64: json['maskBase64'] as String?,
      tileName: json['tileName'] as String,
      tileId: json['tileId'] as int,
      tileSize: json['tileSize'] as String,
      tilePrice: (json['tilePrice'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Project.fromJsonString(String jsonString) =>
      Project.fromJson(jsonDecode(jsonString));
}

