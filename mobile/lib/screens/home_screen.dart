import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'floor_selection_screen.dart';

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
        String errorMessage = 'Failed to pick image';
        
        // Handle specific error types
        if (e.toString().contains('Permission')) {
          errorMessage = 'Camera/Gallery permission denied. Please enable it in settings.';
        } else if (e.toString().contains('camera_access_denied')) {
          errorMessage = 'Camera access denied. Please grant permission in app settings.';
        } else if (e.toString().contains('photo_access_denied')) {
          errorMessage = 'Photo library access denied. Please grant permission in app settings.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('TileVision'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/title section
                const Icon(
                  Icons.grid_on,
                  size: 80,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Visualize Your Floor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take or upload a photo of your room to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Take Photo button
                Card(
                  child: InkWell(
                    onTap: () => _pickImage(context, ImageSource.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: Color(0xFF2196F3),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use your camera',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Upload Photo button
                Card(
                  child: InkWell(
                    onTap: () => _pickImage(context, ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 48,
                            color: Color(0xFF2196F3),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Upload Photo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose from gallery',
                            style: TextStyle(
                              fontSize: 14,
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
