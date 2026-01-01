import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../models/tile.dart';
import 'result_screen.dart';

class TileCatalogScreen extends StatefulWidget {
  final String imagePath;
  final String? maskBase64;

  const TileCatalogScreen({
    super.key,
    required this.imagePath,
    this.maskBase64,
  });

  @override
  State<TileCatalogScreen> createState() => _TileCatalogScreenState();
}

class _TileCatalogScreenState extends State<TileCatalogScreen> {
  final ApiService _apiService = ApiService();
  List<Tile> _tiles = [];
  Tile? _selectedTile;
  bool _isLoading = false;
  bool _isApplyingTile = false;
  // AI enhancements are always ON for best quality
  static const bool _useAIEnhancement = true;
  static const bool _useMaterialReplacement = true;

  @override
  void initState() {
    super.initState();
    _loadTiles();
  }

  Future<void> _loadTiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tilesData = await _apiService.getTiles();
      
      if (mounted) {
        setState(() {
          _tiles = tilesData.map((data) => Tile.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tiles: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _applyTile() async {
    if (_selectedTile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tile first')),
      );
      return;
    }

    setState(() {
      _isApplyingTile = true;
    });

    // Show progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Applying AI-Enhanced Tile...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take 1-2 minutes',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('• Creating material map...',
                      style: TextStyle(fontSize: 13)),
                  SizedBox(height: 4),
                  Text('• AI texture transfer...',
                      style: TextStyle(fontSize: 13)),
                  SizedBox(height: 4),
                  Text('• Finalizing photorealistic result...',
                      style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      // Download tile image from URL
      final tileUrl = _selectedTile!.imageUrl;
      final tileResponse = await http.get(Uri.parse(tileUrl));
      
      if (tileResponse.statusCode != 200) {
        throw Exception('Failed to download tile image');
      }
      
      // Save tile to temporary file
      final tempDir = await getTemporaryDirectory();
      final tileFile = File('${tempDir.path}/temp_tile_${DateTime.now().millisecondsSinceEpoch}.png');
      await tileFile.writeAsBytes(tileResponse.bodyBytes);
      
      String? resultImageBase64;
      
      // Extended timeout handling is now in ApiService
      if (_useAIEnhancement && _useMaterialReplacement) {
        // Use new IP-Adapter Material Replacement (Nano Banana Pro)
        resultImageBase64 = await _apiService.replaceMaterial(
          File(widget.imagePath),
          tileFile,
          maskBase64: widget.maskBase64,
        );
      } else {
        // Use existing method (ControlNet) - REQUIRES MASK
        if (widget.maskBase64 == null) {
           throw Exception("Mask required for legacy ControlNet method");
        }
        resultImageBase64 = await _apiService.applyTile(
          File(widget.imagePath),
          widget.maskBase64!,
          tileFile,
          _selectedTile!.size,
          useAIEnhancement: _useAIEnhancement,
        );
      }

      // Clean up temp file
      if (await tileFile.exists()) {
        await tileFile.delete();
      }

      if (mounted) {
        // Close progress dialog
        Navigator.of(context).pop();
        
        setState(() {
          _isApplyingTile = false;
        });
      
        if (resultImageBase64 != null && resultImageBase64.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                resultImageBase64: resultImageBase64!,
                originalImagePath: widget.imagePath,
                maskBase64: widget.maskBase64 ?? "",
              ),
            ),
          );
        } else {
          // Show error if result is null
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to apply tile. The server returned no image.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error applying tile: $e');
      if (mounted) {
        // Close progress dialog if context is still valid
        if (Navigator.canPop(context)) {
           Navigator.of(context).pop();
        }
        
        setState(() {
          _isApplyingTile = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply tile: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Tile'),
      ),
      body: Column(
        children: [
          // Original image thumbnail
          Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(widget.imagePath),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Room',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select a tile to visualize',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tiles grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tiles.isEmpty
                    ? const Center(
                        child: Text(
                          'No tiles available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _tiles.length,
                        itemBuilder: (context, index) {
                          final tile = _tiles[index];
                          final isSelected = _selectedTile?.id == tile.id;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTile = tile;
                              });
                            },
                            child: Card(
                              elevation: isSelected ? 8 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        tile.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tile.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              tile.size,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              '₹${tile.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Apply button at bottom
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
                onPressed: _selectedTile == null || _isApplyingTile ? null : _applyTile,
                icon: _isApplyingTile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.brush),
                label: Text(
                  _isApplyingTile ? 'Applying Tile...' : 'Apply Tile',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
