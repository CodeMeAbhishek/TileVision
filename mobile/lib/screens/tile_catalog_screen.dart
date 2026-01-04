import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/showroom_tile_service.dart';
import '../models/tile.dart';
import '../helpers/error_helper.dart';
import '../helpers/responsive_helper.dart';
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
  List<Tile> _catalogTiles = [];
  List<Tile> _showroomTiles = [];
  Tile? _selectedTile;
  bool _isLoading = false;
  bool _isApplyingTile = false;

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
      // Load catalog tiles
      final tilesData = await _apiService.getTiles();
      final catalogTiles = tilesData.map((data) => Tile.fromJson(data)).toList();
      
      // Load showroom tiles
      final showroomTiles = await ShowroomTileService.loadShowroomTiles();
      
      if (mounted) {
        setState(() {
          _catalogTiles = catalogTiles;
          _showroomTiles = showroomTiles;
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
            content: Text(ErrorHelper.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: ErrorHelper.isRetryable(e)
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _loadTiles(),
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _addShowroomTile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image == null) return;

      // Show dialog to enter tile details
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _ShowroomTileDialog(),
      );

      if (result != null && mounted) {
        try {
          final tile = await ShowroomTileService.saveShowroomTile(
            name: result['name'] ?? 'My Tile',
            imagePath: image.path,
            size: result['size'] ?? 'Custom',
            price: (result['price'] ?? 0.0) as double,
          );

          // Reload tiles
          await _loadTiles();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Showroom tile added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add tile: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
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
      File tileFile;
      
      if (_selectedTile!.isShowroomTile && _selectedTile!.localImagePath != null) {
        // Use local file for showroom tiles
        tileFile = File(_selectedTile!.localImagePath!);
        if (!await tileFile.exists()) {
          throw Exception('Tile image file not found');
        }
      } else {
        // Download tile image from URL for catalog tiles
        final tileUrl = _selectedTile!.imageUrl;
        final tileResponse = await http.get(Uri.parse(tileUrl));
        
        if (tileResponse.statusCode != 200) {
          throw Exception('Failed to download tile image');
        }
        
        // Save tile to temporary file
        final tempDir = await getTemporaryDirectory();
        tileFile = File('${tempDir.path}/temp_tile_${DateTime.now().millisecondsSinceEpoch}.png');
        await tileFile.writeAsBytes(tileResponse.bodyBytes);
      }
      
      // Use IP-Adapter Material Replacement (Gemini 2.5) for best quality
      final resultImageBase64 = await _apiService.replaceMaterial(
        File(widget.imagePath),
        tileFile,
        maskBase64: widget.maskBase64,
      );

      // Clean up temp file if it was created
      if (!_selectedTile!.isShowroomTile && await tileFile.exists()) {
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
                tile: _selectedTile, // Pass tile info for saving project
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
            content: Text(ErrorHelper.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: ErrorHelper.isRetryable(e)
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _applyTile(),
                  )
                : null,
          ),
        );
      }
    }
  }

  List<Tile> get _allTiles => [..._catalogTiles, ..._showroomTiles];

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper.getDeviceType(context);
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final padding = ResponsiveHelper.getPadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Tile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _addShowroomTile,
            tooltip: 'Add Showroom Tile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Original image thumbnail
          Container(
            width: double.infinity,
            height: ResponsiveHelper.isMobile(context) ? 100 : 120,
            padding: EdgeInsets.all(spacing),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(widget.imagePath),
                    width: ResponsiveHelper.isMobile(context) ? 80 : 100,
                    height: ResponsiveHelper.isMobile(context) ? 80 : 100,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Room',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select a tile to visualize',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section headers and tiles grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allTiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.grid_on,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tiles available',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _addShowroomTile,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Add Your First Showroom Tile'),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          // Catalog tiles section
                          if (_catalogTiles.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  padding.left,
                                  padding.top,
                                  padding.right,
                                  spacing,
                                ),
                                child: Text(
                                  'Catalog Tiles',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (_catalogTiles.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: padding.left),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: spacing * 2,
                                  mainAxisSpacing: spacing * 2,
                                  childAspectRatio: 0.75,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildTileCard(_catalogTiles[index]),
                                  childCount: _catalogTiles.length,
                                ),
                              ),
                            ),

                          // Showroom tiles section
                          if (_showroomTiles.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  padding.left,
                                  padding.top * 2,
                                  padding.right,
                                  spacing,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'My Showroom Tiles',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_photo_alternate),
                                      onPressed: _addShowroomTile,
                                      tooltip: 'Add Showroom Tile',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_showroomTiles.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: padding.left),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: spacing * 2,
                                  mainAxisSpacing: spacing * 2,
                                  childAspectRatio: 0.75,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildTileCard(_showroomTiles[index]),
                                  childCount: _showroomTiles.length,
                                ),
                              ),
                            ),
                        ],
                      ),
          ),

          // Apply button at bottom
          Container(
            padding: padding,
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
                    ? SizedBox(
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
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveHelper.getButtonPadding(context),
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

  Widget _buildTileCard(Tile tile) {
    final isSelected = _selectedTile?.id == tile.id && _selectedTile?.isShowroomTile == tile.isShowroomTile;

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
                child: tile.isShowroomTile && tile.localImagePath != null
                    ? Image.file(
                        File(tile.localImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: tile.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                        cacheKey: 'tile_${tile.id}',
                        maxWidthDiskCache: 500,
                        maxHeightDiskCache: 500,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tile.name,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tile.isShowroomTile)
                        Icon(
                          Icons.store,
                          size: 16,
                          color: Colors.orange,
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tile.size,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(context, mobile: 11, tablet: 12, desktop: 14),
                          color: Colors.grey,
                        ),
                      ),
                      if (tile.price > 0)
                        Text(
                          '₹${tile.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
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
  }
}

class _ShowroomTileDialog extends StatefulWidget {
  @override
  State<_ShowroomTileDialog> createState() => _ShowroomTileDialogState();
}

class _ShowroomTileDialogState extends State<_ShowroomTileDialog> {
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController(text: 'Custom');
  final _priceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Showroom Tile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tile Name *',
                hintText: 'e.g., Premium Marble',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Size',
                hintText: 'e.g., 2x2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a tile name')),
              );
              return;
            }
            Navigator.pop(
              context,
              {
                'name': _nameController.text.trim(),
                'size': _sizeController.text.trim(),
                'price': double.tryParse(_priceController.text) ?? 0.0,
              },
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
