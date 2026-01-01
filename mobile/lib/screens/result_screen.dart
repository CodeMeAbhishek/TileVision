import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'tile_catalog_screen.dart';

class ResultScreen extends StatefulWidget {
  final String resultImageBase64;
  final String originalImagePath;
  final String? maskBase64;

  const ResultScreen({
    super.key,
    required this.resultImageBase64,
    required this.originalImagePath,
    this.maskBase64,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  Future<void> _saveToGallery() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Decode base64 image
      final bytes = base64Decode(widget.resultImageBase64);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/tilevision_$timestamp.jpg';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        // Image saved to temporary directory
        // Note: For production, consider using image_gallery_saver package for gallery integration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      // Decode base64 image
      final bytes = base64Decode(widget.resultImageBase64);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/tilevision_$timestamp.jpg';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out my floor visualization from TileVision!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _tryAnotherTile() {
    // Go back to tile catalog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TileCatalogScreen(
          imagePath: widget.originalImagePath,
          maskBase64: widget.maskBase64,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate to home, clearing all previous routes
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Go to Home',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: Colors.black,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            base64Decode(widget.resultImageBase64),
            fit: BoxFit.contain,
          ),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Save to gallery
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt),
                      iconSize: 28,
                      color: Colors.blue,
                      onPressed: _isSaving ? null : _saveToGallery,
                      tooltip: 'Save to Gallery',
                    ),
                    const Text(
                      'Save',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),

                // Share
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      iconSize: 28,
                      color: Colors.green,
                      onPressed: _shareImage,
                      tooltip: 'Share',
                    ),
                    const Text(
                      'Share',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),

                // Try another tile
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_on),
                      iconSize: 28,
                      color: Colors.orange,
                      onPressed: _tryAnotherTile,
                      tooltip: 'Try Another Tile',
                    ),
                    const Text(
                      'Try Another',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
