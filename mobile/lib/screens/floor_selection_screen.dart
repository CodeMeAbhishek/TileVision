import 'package:flutter/material.dart';
import 'dart:io';
import 'tile_catalog_screen.dart';
import '../helpers/responsive_helper.dart';

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
            padding: ResponsiveHelper.getPadding(context),
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
                Text(
                  "Does this look correct?",
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
                SizedBox(
                  width: double.infinity,
                  height: ResponsiveHelper.isMobile(context) ? 48 : 56,
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
                    child: Text(
                      'Yes, Select Tiles',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getSpacing(context)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Retake Photo",
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
