import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilevision/main.dart';
import 'package:tilevision/screens/home_screen.dart';
import 'package:tilevision/screens/floor_selection_screen.dart';
import 'package:tilevision/screens/tile_catalog_screen.dart';
import 'package:tilevision/screens/result_screen.dart';
import 'package:tilevision/models/tile.dart';

void main() {
  group('App Initialization Tests', () {
    testWidgets('TileVisionApp creates MaterialApp', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const TileVisionApp());

      // Verify MaterialApp is created
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App title is TileVision', (WidgetTester tester) async {
      await tester.pumpWidget(const TileVisionApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'TileVision');
    });

    testWidgets('Home screen is the initial route', (WidgetTester tester) async {
      await tester.pumpWidget(const TileVisionApp());

      // Verify HomeScreen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Screen Import Tests', () {
    test('HomeScreen can be imported', () {
      expect(HomeScreen, isNotNull);
    });

    test('FloorSelectionScreen can be imported', () {
      expect(FloorSelectionScreen, isNotNull);
    });

    test('TileCatalogScreen can be imported', () {
      expect(TileCatalogScreen, isNotNull);
    });

    test('ResultScreen can be imported', () {
      expect(ResultScreen, isNotNull);
    });
  });

  group('HomeScreen Tests', () {
    testWidgets('HomeScreen displays app title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      expect(find.text('TileVision'), findsOneWidget);
    });

    testWidgets('HomeScreen displays Take Photo button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      expect(find.text('Take Photo'), findsOneWidget);
    });

    testWidgets('HomeScreen displays Upload Photo button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      expect(find.text('Upload Photo'), findsOneWidget);
    });

    testWidgets('HomeScreen displays camera and gallery icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('HomeScreen displays welcome text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      expect(find.text('Visualize Your Floor'), findsOneWidget);
    });
  });

  group('Model Tests', () {
    test('Tile model can be created from JSON', () {
      final json = {
        'id': 1,
        'name': 'Test Tile',
        'image_url': 'https://example.com/tile.jpg',
        'size': '2x2',
        'price': 1200.0,
      };

      final tile = Tile.fromJson(json);

      expect(tile.id, 1);
      expect(tile.name, 'Test Tile');
      expect(tile.imageUrl, 'https://example.com/tile.jpg');
      expect(tile.size, '2x2');
      expect(tile.price, 1200.0);
    });

    test('Tile model can be converted to JSON', () {
      final tile = Tile(
        id: 1,
        name: 'Test Tile',
        imageUrl: 'https://example.com/tile.jpg',
        size: '2x2',
        price: 1200.0,
      );

      final json = tile.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test Tile');
      expect(json['image_url'], 'https://example.com/tile.jpg');
      expect(json['size'], '2x2');
      expect(json['price'], 1200.0);
    });

    test('Tile equality works correctly', () {
      final tile1 = Tile(
        id: 1,
        name: 'Tile 1',
        imageUrl: 'url1',
        size: '2x2',
        price: 1000,
      );

      final tile2 = Tile(
        id: 1,
        name: 'Different Name',
        imageUrl: 'url2',
        size: '3x3',
        price: 2000,
      );

      final tile3 = Tile(
        id: 2,
        name: 'Tile 3',
        imageUrl: 'url3',
        size: '2x2',
        price: 1000,
      );

      // Same ID means equal
      expect(tile1, tile2);
      // Different ID means not equal
      expect(tile1 == tile3, false);
    });
  });

  group('Theme Tests', () {
    testWidgets('App uses correct primary color', (WidgetTester tester) async {
      await tester.pumpWidget(const TileVisionApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.primaryColor, const Color(0xFF2196F3));
    });

    testWidgets('App uses Material 3', (WidgetTester tester) async {
      await tester.pumpWidget(const TileVisionApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, true);
    });
  });
}
