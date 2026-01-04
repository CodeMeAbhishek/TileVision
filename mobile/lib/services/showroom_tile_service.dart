import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/tile.dart';

class ShowroomTileService {
  static const String _showroomTilesFileName = 'showroom_tiles.json';
  static int _nextId = 1000; // Start from 1000 to avoid conflicts with catalog tiles

  /// Save a showroom tile
  static Future<Tile> saveShowroomTile({
    required String name,
    required String imagePath,
    String size = 'Custom',
    double price = 0.0,
  }) async {
    try {
      // Copy image to app documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final showroomTilesDir = Directory('${documentsDir.path}/showroom_tiles');
      if (!await showroomTilesDir.exists()) {
        await showroomTilesDir.create(recursive: true);
      }

      final fileName = 'tile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${showroomTilesDir.path}/$fileName';
      
      // Copy the image file
      final sourceFile = File(imagePath);
      await sourceFile.copy(savedImagePath);

      // Create tile with unique ID
      final tile = Tile.fromLocalFile(
        id: _nextId++,
        name: name,
        localImagePath: savedImagePath,
        size: size,
        price: price,
      );

      // Save to tiles list
      final tiles = await loadShowroomTiles();
      tiles.add(tile);
      await _saveShowroomTiles(tiles);

      return tile;
    } catch (e) {
      throw Exception('Failed to save showroom tile: $e');
    }
  }

  /// Load all showroom tiles
  static Future<List<Tile>> loadShowroomTiles() async {
    try {
      final file = await _getShowroomTilesFile();
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(content);
      final tiles = jsonList.map((json) => Tile.fromJson(json)).toList();
      
      // Filter out tiles whose image files no longer exist
      final validTiles = <Tile>[];
      for (final tile in tiles) {
        if (tile.localImagePath != null) {
          final imageFile = File(tile.localImagePath!);
          if (await imageFile.exists()) {
            validTiles.add(tile);
          }
        }
      }

      // Update saved list if some tiles were removed
      if (validTiles.length != tiles.length) {
        await _saveShowroomTiles(validTiles);
      }

      // Update next ID to be higher than any existing ID
      if (validTiles.isNotEmpty) {
        final maxId = validTiles.map((t) => t.id).reduce((a, b) => a > b ? a : b);
        _nextId = maxId + 1;
      }

      return validTiles;
    } catch (e) {
      return [];
    }
  }

  /// Delete a showroom tile
  static Future<void> deleteShowroomTile(int tileId) async {
    try {
      final tiles = await loadShowroomTiles();
      final tileToDelete = tiles.firstWhere((t) => t.id == tileId);
      
      // Delete image file
      if (tileToDelete.localImagePath != null) {
        final imageFile = File(tileToDelete.localImagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Remove from list
      tiles.removeWhere((t) => t.id == tileId);
      await _saveShowroomTiles(tiles);
    } catch (e) {
      throw Exception('Failed to delete showroom tile: $e');
    }
  }

  /// Clear all showroom tiles
  static Future<void> clearAllShowroomTiles() async {
    try {
      final tiles = await loadShowroomTiles();
      
      // Delete all image files
      for (final tile in tiles) {
        if (tile.localImagePath != null) {
          final imageFile = File(tile.localImagePath!);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }
      }

      // Delete tiles directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final showroomTilesDir = Directory('${documentsDir.path}/showroom_tiles');
      if (await showroomTilesDir.exists()) {
        await showroomTilesDir.delete(recursive: true);
      }

      // Clear JSON file
      final file = await _getShowroomTilesFile();
      if (await file.exists()) {
        await file.delete();
      }

      _nextId = 1000; // Reset ID counter
    } catch (e) {
      throw Exception('Failed to clear showroom tiles: $e');
    }
  }

  static Future<void> _saveShowroomTiles(List<Tile> tiles) async {
    final file = await _getShowroomTilesFile();
    final jsonList = tiles.map((t) => t.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  static Future<File> _getShowroomTilesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_showroomTilesFileName');
  }
}

