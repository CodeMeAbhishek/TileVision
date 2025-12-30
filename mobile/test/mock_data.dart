import 'package:tilevision/models/tile.dart';

/// Mock data for testing the TileVision app
class MockData {
  /// Sample tile catalog for testing
  static List<Tile> getTiles() {
    return [
      Tile(
        id: 1,
        name: 'Marble White',
        imageUrl: 'https://images.unsplash.com/photo-1615873968403-89e068629265?w=400',
        size: '2x2',
        price: 1200.00,
      ),
      Tile(
        id: 2,
        name: 'Wooden Oak',
        imageUrl: 'https://images.unsplash.com/photo-1534237710431-e2fc698436d0?w=400',
        size: '1x3',
        price: 890.00,
      ),
      Tile(
        id: 3,
        name: 'Ceramic Gray',
        imageUrl: 'https://images.unsplash.com/photo-1584622650647-5d4b8e58c8e7?w=400',
        size: '2x2',
        price: 750.00,
      ),
      Tile(
        id: 4,
        name: 'Granite Black',
        imageUrl: 'https://images.unsplash.com/photo-1556912998-c57cc6b63cd7?w=400',
        size: '3x3',
        price: 1500.00,
      ),
      Tile(
        id: 5,
        name: 'Terracotta Red',
        imageUrl: 'https://images.unsplash.com/photo-1604150414070-e779c09dd94d?w=400',
        size: '2x2',
        price: 650.00,
      ),
      Tile(
        id: 6,
        name: 'Porcelain Blue',
        imageUrl: 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?w=400',
        size: '1x1',
        price: 950.00,
      ),
      Tile(
        id: 7,
        name: 'Mosaic Pattern',
        imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400',
        size: '1x1',
        price: 1100.00,
      ),
      Tile(
        id: 8,
        name: 'Classic Beige',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        size: '2x2',
        price: 820.00,
      ),
    ];
  }

  /// Get tile by ID
  static Tile? getTileById(int id) {
    try {
      return getTiles().firstWhere((tile) => tile.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get tiles in a specific price range
  static List<Tile> getTilesByPriceRange(double min, double max) {
    return getTiles().where((tile) => tile.price >= min && tile.price <= max).toList();
  }

  /// Get tiles by size
  static List<Tile> getTilesBySize(String size) {
    return getTiles().where((tile) => tile.size == size).toList();
  }

  /// Sample base64 encoded image (1x1 transparent PNG)
  static String getMockImageBase64() {
    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  }

  /// Sample floor mask (base64 encoded)
  static String getMockFloorMask() {
    return getMockImageBase64(); // In real app, this would be an actual mask
  }

  /// Sample API response for segmentation
  static Map<String, dynamic> getMockSegmentationResponse() {
    return {
      'mask': getMockFloorMask(),
      'confidence': 0.92,
      'processing_time': 1.5,
    };
  }

  /// Sample API response for tile application
  static Map<String, dynamic> getMockTileApplicationResponse() {
    return {
      'result_image': getMockImageBase64(),
      'processing_time': 2.3,
    };
  }

  /// Sample tiles API response
  static List<Map<String, dynamic>> getMockTilesResponse() {
    return getTiles().map((tile) => tile.toJson()).toList();
  }
}
