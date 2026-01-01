import 'package:flutter/material.dart';
import 'dart:io';
import 'tile_catalog_screen.dart';

class FloorSelectionScreen extends StatelessWidget {
  final String imagePath;

  const FloorSelectionScreen({
    super.key,
    required this.imagePath,
  });

  void _confirmAndProceed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TileCatalogScreen(
          imagePath: imagePath,
          maskBase64: null, // No mask needed for Gemini 2.5 (AI auto-detects floor)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Room Image'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Does this look correct?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _confirmAndProceed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Yes, Select Tiles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Retake Photo"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
