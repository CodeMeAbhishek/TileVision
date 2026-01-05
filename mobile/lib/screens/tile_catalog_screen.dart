import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/showroom_tile_service.dart';
import '../services/usage_service.dart';
import '../models/tile.dart';
import '../helpers/error_helper.dart';
import '../helpers/responsive_helper.dart';
import '../helpers/page_transitions.dart';
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

class _TileCatalogScreenState extends State<TileCatalogScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Tile> _showroomTiles = [];
  Tile? _selectedTile;
  bool _isLoading = false;
  bool _isApplyingTile = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadTiles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load only showroom tiles (shop owner's own tiles)
      final showroomTiles = await ShowroomTileService.loadShowroomTiles();
      
      if (mounted) {
        setState(() {
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
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadTiles(),
            ),
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

    // Check usage limit before proceeding
    final hasRemaining = await UsageService.hasRemainingImages();
    if (!hasRemaining) {
      final stats = await UsageService.getUsageStats();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.block, color: Colors.red),
                SizedBox(width: 8),
                Text('Limit Reached'),
              ],
            ),
            content: Text(
              'You have reached your image generation limit (${stats.imageLimit} images).\n\n'
              'Please contact support to increase your limit or check your profile for more details.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to profile to see usage details
                  // This will be handled by the main navigation
                },
                child: const Text('View Profile'),
              ),
            ],
          ),
        );
      }
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
      // All tiles are now showroom tiles (shop owner's own tiles)
      if (_selectedTile!.localImagePath == null) {
        throw Exception('Tile image file not found');
      }
      
      final tileFile = File(_selectedTile!.localImagePath!);
      if (!await tileFile.exists()) {
        throw Exception('Tile image file not found');
      }
      
      // Use IP-Adapter Material Replacement (Gemini 2.5) for best quality
      final resultImageBase64 = await _apiService.replaceMaterial(
        File(widget.imagePath),
        tileFile,
        maskBase64: widget.maskBase64,
      );

      if (mounted) {
        // Close progress dialog
        Navigator.of(context).pop();
        
        setState(() {
          _isApplyingTile = false;
        });
      
        if (resultImageBase64 != null && resultImageBase64.isNotEmpty) {
          // Track usage when image is successfully generated
          await UsageService.incrementUsage();
          
          Navigator.pushReplacement(
            context,
            FadeSlideRoute(
              page: ResultScreen(
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

  List<Tile> get _allTiles => _showroomTiles;

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
          // Original image thumbnail with improved design
          Container(
            width: double.infinity,
            height: ResponsiveHelper.isMobile(context) ? 110 : 130,
            margin: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            padding: EdgeInsets.all(spacing * 1.2),
            child: Row(
              children: [
                Hero(
                  tag: 'room_image_${widget.imagePath}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePath),
                      width: ResponsiveHelper.isMobile(context) ? 85 : 105,
                      height: ResponsiveHelper.isMobile(context) ? 85 : 105,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: spacing * 1.5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Room',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Select a tile to visualize',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(
                            context,
                            mobile: 13,
                            tablet: 15,
                            desktop: 17,
                          ),
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: spacing * 2),
                        Text(
                          'Loading tiles...',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _allTiles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: padding,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_on_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: spacing * 2),
                              Text(
                                'No tiles available',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getFontSize(
                                    context,
                                    mobile: 18,
                                    tablet: 20,
                                    desktop: 22,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: spacing * 0.5),
                              Text(
                                'Add your own tiles to visualize them in customer spaces',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: spacing * 2),
                              ElevatedButton.icon(
                                onPressed: _addShowroomTile,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Add Your Tile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing * 2,
                                    vertical: spacing * 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          // Showroom tiles section (only section now)
                          if (_showroomTiles.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  padding.left,
                                  padding.top * 2.5,
                                  padding.right,
                                  spacing * 1.5,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.store,
                                          size: 20,
                                          color: Colors.orange.shade700,
                                        ),
                                        SizedBox(width: spacing * 0.5),
                                        Text(
                                          'Your Tiles',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.getFontSize(
                                              context,
                                              mobile: 18,
                                              tablet: 20,
                                              desktop: 22,
                                            ),
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_photo_alternate),
                                      onPressed: _addShowroomTile,
                                      tooltip: 'Add Showroom Tile',
                                      color: Theme.of(context).primaryColor,
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
                                  (context, index) => _buildTileCard(_showroomTiles[index], context),
                                  childCount: _showroomTiles.length,
                                ),
                              ),
                            ),
                        ],
                      ),
          ),

          // Apply button at bottom with improved design
          Container(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top * 1.2,
              padding.right,
              padding.bottom * 1.2,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: ResponsiveHelper.isMobile(context) ? 52 : 56,
                child: ElevatedButton.icon(
                  onPressed: _selectedTile == null || _isApplyingTile ? null : _applyTile,
                  icon: _isApplyingTile
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 22),
                  label: Text(
                    _isApplyingTile ? 'Applying Tile...' : 'Apply Tile',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTile == null
                        ? Colors.grey.shade400
                        : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: _selectedTile == null ? 0 : 3,
                    shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileCard(Tile tile, BuildContext context) {
    final isSelected = _selectedTile?.id == tile.id && _selectedTile?.isShowroomTile == tile.isShowroomTile;
    final spacing = ResponsiveHelper.getSpacing(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTile = tile;
        });
        // Haptic feedback
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.grey.shade200,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section - Larger and more prominent
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
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
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor.withOpacity(0.5),
                                      ),
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
                      // Selection indicator
                      if (isSelected)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info Section - Cleaner layout
                Padding(
                  padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context) * 1.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tile.name,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getFontSize(
                                  context,
                                  mobile: 15,
                                  tablet: 17,
                                  desktop: 19,
                                ),
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tile.isShowroomTile)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.store,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tile.size,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getFontSize(
                                  context,
                                  mobile: 11,
                                  tablet: 12,
                                  desktop: 13,
                                ),
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (tile.price > 0)
                            Text(
                              '₹${tile.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
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
