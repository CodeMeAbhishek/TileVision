import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../helpers/connectivity_helper.dart';

class ApiService {
  // Base URL for the API - configurable
  // Production: Render.com backend
  // Development: 
  //   - Android Emulator: 'http://10.0.2.2:8000'
  //   - Physical Device: 'http://YOUR_COMPUTER_IP:8000' (e.g., 'http://192.168.1.100:8000')
  //   - iOS Simulator: 'http://localhost:8000'
  static String get _defaultBaseUrl {
    // Always use production URL for APK builds
    // For local development, manually change this or pass baseUrl parameter
    return 'https://tilevision.onrender.com';
  }
  
  final String baseUrl;
  
  // Request timeout duration (increased for AI processing which can take 1-2 minutes)
  static const Duration _timeout = Duration(seconds: 300);

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl {
    if (kDebugMode) {
      print('🔗 ApiService initialized with baseUrl: $baseUrl');
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
    // Check connectivity first
    if (!await ConnectivityHelper.isConnected()) {
      throw ApiException(
        'No Internet Connection',
        'Please check your network connection and try again.',
      );
    }
    
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
      // Log error and rethrow for UI to handle
      rethrow;
    }
  }


  /// Replace floor material using Gemini 2.5 Flash - Direct AI (no segmentation needed)
  /// Gemini automatically detects and replaces the floor area
  Future<String> replaceMaterial(
    File originalImage,
    File tileImage, {
    String? maskBase64, // Not used - kept for API compatibility but ignored
  }) async {
    // Check connectivity first
    if (!await ConnectivityHelper.isConnected()) {
      throw ApiException(
        'No Internet Connection',
        'Please check your network connection and try again.',
      );
    }
    
    try {
      final uri = Uri.parse('$baseUrl/api/replace-material');
      var request = http.MultipartRequest('POST', uri);
      
      // Add room image
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        originalImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      // Add tile image (mask not needed - Gemini auto-detects floor)
      request.files.add(await http.MultipartFile.fromPath(
        'tile',
        tileImage.path,
        contentType: MediaType('image', 'png'),
      ));
      
      // Note: maskBase64 is ignored - Gemini automatically detects floor area
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result_image'];
      } else {
        // Try to extract error message from response
        String errorMessage = 'Material replacement failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        }
        throw ApiException('Material replacement failed (${response.statusCode})', errorMessage);
      }
    } catch (e) {
      throw ApiException('AI Material error', e.toString());
    }
  }

  /// Get available tiles catalog
  /// 
  /// Returns a list of tile objects
  /// Includes retry logic for cold starts
  Future<List<dynamic>> getTiles() async {
    // Check connectivity first
    if (!await ConnectivityHelper.isConnected()) {
      throw ApiException(
        'No Internet Connection',
        'Please check your network connection and try again.',
      );
    }
    
    int maxRetries = 3;
    int retryDelay = 2; // seconds
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$baseUrl/api/tiles');
        
        // Increase timeout for first attempt (cold start might take 30-60s)
        final timeout = attempt == 0 
            ? const Duration(seconds: 90) 
            : _timeout;
        
        final response = await http.get(uri).timeout(timeout);

        if (response.statusCode == 200) {
          return json.decode(response.body) as List<dynamic>;
        } else {
          throw ApiException(
            'Failed to load tiles: ${response.statusCode}',
            response.body,
          );
        }
      } on TimeoutException {
        if (attempt < maxRetries - 1) {
          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(seconds: retryDelay * (attempt + 1)));
          continue;
        }
        throw ApiException(
          'Request timeout',
          'The server is taking too long to respond. This might be a cold start. Please wait 30 seconds and try again.',
        );
      } on SocketException {
        if (attempt < maxRetries - 1) {
          // Wait before retry
          await Future.delayed(Duration(seconds: retryDelay * (attempt + 1)));
          continue;
        }
        throw ApiException(
          'Network error',
          'Could not connect to server. Please check your internet connection and try again.',
        );
      } catch (e) {
        if (attempt < maxRetries - 1 && e is ApiException) {
          // Wait before retry for API exceptions
          await Future.delayed(Duration(seconds: retryDelay * (attempt + 1)));
          continue;
        }
        throw ApiException(
          'Failed to load tiles',
          e.toString(),
        );
      }
    }
    
    throw ApiException(
      'Failed to load tiles',
      'Unable to connect after multiple attempts. Please check your connection.',
    );
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
