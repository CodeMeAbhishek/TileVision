import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tile_catalog_screen.dart';
import 'comparison_screen.dart';
import '../helpers/error_helper.dart';
import '../models/project.dart';
import '../models/tile.dart';
import '../services/project_service.dart';

class ResultScreen extends StatefulWidget {
  final String resultImageBase64;
  final String originalImagePath;
  final String? maskBase64;
  final Tile? tile; // Tile info for saving project

  const ResultScreen({
    super.key,
    required this.resultImageBase64,
    required this.originalImagePath,
    this.maskBase64,
    this.tile,
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
      // Request permission first
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission denied. Please enable photo access in settings.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Decode base64 image
      final bytes = base64Decode(widget.resultImageBase64);

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: "TileVision_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to gallery successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception('Failed to save image to gallery');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHelper.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
            content: Text(ErrorHelper.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  Future<void> _saveProject() async {
    if (widget.tile == null) return;

    try {
      final project = Project(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalImagePath: widget.originalImagePath,
        resultImageBase64: widget.resultImageBase64,
        maskBase64: widget.maskBase64,
        tileName: widget.tile!.name,
        tileId: widget.tile!.id,
        tileSize: widget.tile!.size,
        tilePrice: widget.tile!.price,
        createdAt: DateTime.now(),
      );

      await ProjectService.saveProject(project);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project saved to history!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save project: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          // Side-by-side comparison
          IconButton(
            icon: const Icon(Icons.view_column),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComparisonScreen(
                    originalImagePath: widget.originalImagePath,
                    resultImageBase64: widget.resultImageBase64,
                  ),
                ),
              );
            },
            tooltip: 'Side-by-Side Compare',
          ),
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

                // Save to history
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.bookmark),
                      iconSize: 28,
                      color: Colors.purple,
                      onPressed: widget.tile != null ? _saveProject : null,
                      tooltip: 'Save to History',
                    ),
                    const Text(
                      'Save',
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
