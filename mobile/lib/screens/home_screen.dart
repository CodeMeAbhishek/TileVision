import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'floor_selection_screen.dart';
import '../helpers/error_helper.dart';
import '../helpers/responsive_helper.dart';
import 'project_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && context.mounted) {
        // Navigate to floor selection screen with the image path
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FloorSelectionScreen(
              imagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHelper.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getPadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TileVision'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProjectHistoryScreen(),
                ),
              );
            },
            tooltip: 'Project History',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/title section
                Icon(
                  Icons.grid_on,
                  size: ResponsiveHelper.getIconSize(context) * 3,
                  color: const Color(0xFF2196F3),
                ),
                SizedBox(height: spacing * 2),
                Text(
                  'Visualize Your Floor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, mobile: 24, tablet: 28, desktop: 32),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                SizedBox(height: spacing),
                Text(
                  'Take or upload a photo of your room to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: spacing * 3),
                
                // Test button - load sample image directly
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Load asset and save to temp file
                      final ByteData data = await rootBundle.load('assets/test_room.jpg');
                      final Uint8List bytes = data.buffer.asUint8List();
                      
                      final tempDir = await getTemporaryDirectory();
                      final file = File('${tempDir.path}/test_room.jpg');
                      await file.writeAsBytes(bytes);
                      
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FloorSelectionScreen(
                              imagePath: file.path,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to load test image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.science),
                  label: const Text('Test with Sample Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: ResponsiveHelper.getButtonPadding(context),
                  ),
                ),
                
                SizedBox(height: spacing * 2),
                
                // Take Photo button
                Card(
                  child: InkWell(
                    onTap: () => _pickImage(context, ImageSource.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(padding.left),
                      height: ResponsiveHelper.getCardHeight(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: ResponsiveHelper.getIconSize(context) * 2,
                            color: const Color(0xFF2196F3),
                          ),
                          SizedBox(height: spacing),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2196F3),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use your camera',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: spacing * 2),
                
                // Upload Photo button
                Card(
                  child: InkWell(
                    onTap: () => _pickImage(context, ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(padding.left),
                      height: ResponsiveHelper.getCardHeight(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: ResponsiveHelper.getIconSize(context) * 2,
                            color: const Color(0xFF2196F3),
                          ),
                          SizedBox(height: spacing),
                          Text(
                            'Upload Photo',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2196F3),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose from gallery',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
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
