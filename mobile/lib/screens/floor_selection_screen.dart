import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../services/api_service.dart';
import 'tile_catalog_screen.dart';

class FloorSelectionScreen extends StatefulWidget {
  final String imagePath;

  const FloorSelectionScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<FloorSelectionScreen> createState() => _FloorSelectionScreenState();
}

class _FloorSelectionScreenState extends State<FloorSelectionScreen> {
  Offset? _selectedPoint;
  bool _isLoading = false;
  String? _maskBase64;
  double? _confidence;
  final ApiService _apiService = ApiService();
  
  // Image sizing properties
  int? _imageWidth;
  int? _imageHeight;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final image = await decodeImageFromList(bytes);
    
    if (mounted) {
      setState(() {
        _imageWidth = image.width;
        _imageHeight = image.height;
      });

      // Auto-trigger detection after layout is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoDetectFloor();
      });
    }
  }

  void _autoDetectFloor() {
    // Heuristic: Floor is usually in the bottom-center 
    // We need to account for BoxFit.contain letterboxing
    
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _imageWidth == null || _imageHeight == null) return;
    
    final widgetSize = renderBox.size;
    
    // Calculate where the image is actually rendered (accounting for letterboxing)
    final imageDisplayRect = _getImageDisplayRect(widgetSize);
    if (imageDisplayRect == null) return;
    
    // Pick a point in the bottom-center of the ACTUAL IMAGE (not widget)
    // 50% horizontal, 75% vertical within the rendered image
    final autoPoint = Offset(
      imageDisplayRect.left + (imageDisplayRect.width * 0.5),
      imageDisplayRect.top + (imageDisplayRect.height * 0.75),
    );
    
    setState(() {
      _selectedPoint = autoPoint;
    });
    
    _detectFloor();
  }

  Offset? _transformCoordinates(Offset localPosition, Size widgetSize) {
    if (_imageWidth == null || _imageHeight == null) return null;

    // Calculate the scale to fit the image inside the widget (BoxFit.contain)
    double scaleW = widgetSize.width / _imageWidth!;
    double scaleH = widgetSize.height / _imageHeight!;
    double scale = scaleW < scaleH ? scaleW : scaleH;

    // Calculate the size of the rendered image
    double renderedWidth = _imageWidth! * scale;
    double renderedHeight = _imageHeight! * scale;

    // Calculate offsets (black bars)
    double offsetX = (widgetSize.width - renderedWidth) / 2;
    double offsetY = (widgetSize.height - renderedHeight) / 2;

    // Check if tap is within the image bounds
    if (localPosition.dx < offsetX || 
        localPosition.dx > offsetX + renderedWidth ||
        localPosition.dy < offsetY || 
        localPosition.dy > offsetY + renderedHeight) {
      return null;
    }

    // Convert local coordinates to image coordinates
    double imageX = (localPosition.dx - offsetX) / scale;
    double imageY = (localPosition.dy - offsetY) / scale;

    return Offset(imageX, imageY);
  }

  Future<void> _detectFloor() async {
    if (_selectedPoint == null) return;

    // Get current widget size
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error getting image dimensions')),
      );
      return;
    }
    
    // Transform screen coordinates to image coordinates
    final imagePoint = _transformCoordinates(_selectedPoint!, renderBox.size);
    
    if (imagePoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap inside the image area')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _maskBase64 = null; // Clear any existing mask while loading new one
    });

    try {
      final result = await _apiService.segmentFloor(
        File(widget.imagePath),
        imagePoint,
      );

      if (mounted) {
        setState(() {
          _maskBase64 = result['mask'];
          _confidence = result['confidence'];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Floor detected! Tap elsewhere to correct if needed.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect floor: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmAndProceed() {
    if (_maskBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please detect the floor first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TileCatalogScreen(
          imagePath: widget.imagePath,
          maskBase64: _maskBase64!,
        ),
      ),
    );
  }
  
  // Helper to get image display Rect for overlay
  Rect? _getImageDisplayRect(Size widgetSize) {
    if (_imageWidth == null || _imageHeight == null) return null;

    double scaleW = widgetSize.width / _imageWidth!;
    double scaleH = widgetSize.height / _imageHeight!;
    double scale = scaleW < scaleH ? scaleW : scaleH;

    double renderedWidth = _imageWidth! * scale;
    double renderedHeight = _imageHeight! * scale;

    double offsetX = (widgetSize.width - renderedWidth) / 2;
    double offsetY = (widgetSize.height - renderedHeight) / 2;
    
    return Rect.fromLTWH(offsetX, offsetY, renderedWidth, renderedHeight);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Floor Area'),
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Text(
              'AI auto-detects the floor. Tap elsewhere to correct if needed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),

          // Image with tap detection
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (details) {
                        // Update point immediately (visual feedback)
                        setState(() {
                          _selectedPoint = details.localPosition;
                        });
                        
                        // Auto-trigger re-detection when user taps
                        _detectFloor();
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: Image.file(
                          File(widget.imagePath),
                          key: _imageKey,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Show selected point
                    if (_selectedPoint != null)
                      Positioned(
                        left: _selectedPoint!.dx - 15,
                        top: _selectedPoint!.dy - 15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.7),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),

                    // Show mask overlay - green tint on detected floor only
                    if (_maskBase64 != null)
                      Builder(
                        builder: (context) {
                          // We need to position the mask exactly over the image
                          // Logic: Center the mask image which is same aspect ratio as original
                          // And apply BoxFit.contain which matches the underlying image
                          return Positioned.fill(
                            child: Image.memory(
                              base64Decode(_maskBase64!),
                              fit: BoxFit.contain,
                              color: Colors.green.withOpacity(0.5),
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          );
                        }
                      ),

                    // Loading overlay
                    if (_isLoading)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'AI is analyzing your floor...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'This takes 20-40 seconds',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }
            ),
          ),

          // Bottom button - Only Confirm (auto-detect handles detection)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _maskBase64 == null || _isLoading ? null : _confirmAndProceed,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  _maskBase64 == null 
                    ? 'Detecting floor...' 
                    : 'Continue with Selection',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
