import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';

class ApiService {
  // Base URL for the API - configurable
  // Use 10.0.2.2 for Android emulator to reach host machine's localhost
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';
  final String baseUrl;
  
  // Request timeout duration (increased for AI segmentation which can take 60-90s)
  static const Duration _timeout = Duration(seconds: 300);

  ApiService({this.baseUrl = _defaultBaseUrl});

  /// Segment floor from image using point coordinate
  /// 
  /// Returns a map containing:
  /// - mask: Base64 encoded PNG of the segmentation mask
  /// - confidence: Float confidence score (0-1)
  /// - processing_time: Float processing duration in seconds
  Future<Map<String, dynamic>> segmentFloor(File image, Offset point) async {
    try {
      final uri = Uri.parse('$baseUrl/api/segment-floor');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Add image file with explicit content type
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      // Add point coordinates
      request.fields['point_x'] = point.dx.round().toString();
      request.fields['point_y'] = point.dy.round().toString();

      // Send request with timeout
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'mask': data['mask'],
          'confidence': data['confidence'],
          'processing_time': data['processing_time'],
        };
      } else {
        throw ApiException(
          'Floor segmentation failed: ${response.statusCode}',
          response.body,
        );
      }
    } on TimeoutException {
      throw ApiException(
        'Request timeout',
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw ApiException(
        'Network error',
        'Could not connect to server at $baseUrl. Please check your connection and ensure the backend is running.',
      );
    } catch (e) {
      throw ApiException(
        'Segmentation error',
        e.toString(),
      );
    }
  }

  /// Apply tile pattern to floor with optional AI enhancement
  /// 
  /// Parameters:
  /// - useAIEnhancement: Enable ControlNet realistic lighting (default: false)
  /// - aiStrength: AI modification strength, 0.2-0.4 (default: 0.3)
  /// - aiBlend: Blend ratio, 0.0-1.0 (default: 0.5)
  /// 
  /// Returns base64 encoded JPEG of result image, or null on error
  Future<String?> applyTile(
    File originalImage,
    String maskBase64,
    File tileImage,
    String tileSize, {
    bool useAIEnhancement = false,
    double aiStrength = 0.3,
    double aiBlend = 0.5,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/apply-tile'),
      );
      
      // Add files
      request.files.add(await http.MultipartFile.fromPath(
        'original_image',
        originalImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      // Decode and add mask
      final maskBytes = base64Decode(maskBase64);
      request.files.add(http.MultipartFile.fromBytes(
        'floor_mask',
        maskBytes,
        filename: 'mask.png',
        contentType: MediaType('image', 'png'),
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'tile_image',
        tileImage.path,
        contentType: MediaType('image', 'png'),
      ));
      
      // Add parameters
      request.fields['tile_size'] = tileSize;
      request.fields['use_ai_enhancement'] = useAIEnhancement.toString();
      request.fields['ai_strength'] = aiStrength.toString();
      request.fields['ai_blend'] = aiBlend.toString();
      
      // Send with longer timeout for AI processing (5 minutes)
      final streamedResponse = await request.send().timeout(
        Duration(seconds: useAIEnhancement ? 300 : 60),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result_image'];
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error applying tile: $e');
      rethrow;
    }
  }


  /// Replace material using IP-Adapter for hyper-realistic results
  Future<String> replaceMaterial(
    File originalImage,
    File tileImage, {
    String? maskBase64,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/replace-material');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        originalImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      if (maskBase64 != null && maskBase64.isNotEmpty) {
        final maskBytes = base64Decode(maskBase64);
        request.files.add(http.MultipartFile.fromBytes(
          'mask',
          maskBytes,
          filename: 'mask.png',
          contentType: MediaType('image', 'png'),
        ));
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'tile',
        tileImage.path,
        contentType: MediaType('image', 'png'),
      ));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result_image'];
      } else {
        throw ApiException('Material replacement failed: ${response.statusCode}', response.body);
      }
    } catch (e) {
      throw ApiException('AI Material error', e.toString());
    }
  }

  /// Get available tiles catalog
  /// 
  /// Returns a list of tile objects
  Future<List<dynamic>> getTiles() async {
    try {
      final uri = Uri.parse('$baseUrl/api/tiles');
      
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw ApiException(
          'Failed to load tiles: ${response.statusCode}',
          response.body,
        );
      }
    } on TimeoutException {
      throw ApiException(
        'Request timeout',
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw ApiException(
        'Network error',
        'Could not connect to server at $baseUrl. Please check your connection and ensure the backend is running.',
      );
    } catch (e) {
      throw ApiException(
        'Failed to load tiles',
        e.toString(),
      );
    }
  }

  /// Check if server is healthy
  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String title;
  final String message;

  ApiException(this.title, this.message);

  @override
  String toString() => '$title: $message';
}
