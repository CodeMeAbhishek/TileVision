# Flutter Mobile App Testing Guide

This guide covers how to test and run the TileVision Flutter mobile app.

## 🚀 Quick Start

### Windows
```bash
cd mobile
run.bat
```

### Linux/Mac/Git Bash
```bash
cd mobile
chmod +x run.sh
./run.sh
```

The script will:
1. Check Flutter installation
2. Get all dependencies (flutter pub get)
3. Show available devices
4. Let you choose platform
5. Run the app in debug mode

## 🧪 Running Tests

### Run all tests
```bash
cd mobile
flutter test
```

### Run with coverage
```bash
flutter test --coverage
```

### Run specific test file
```bash
flutter test test/widget_test.dart
```

### Run tests in watch mode (auto-rerun)
```bash
flutter test --watch
```

## 📋 Test Coverage

The test suite includes:

✅ **App Initialization Tests**
- MaterialApp creation
- App title verification
- Initial route (HomeScreen)

✅ **Screen Import Tests**
- HomeScreen import
- FloorSelectionScreen import
- TileCatalogScreen import
- ResultScreen import

✅ **HomeScreen Widget Tests**
- App title display
- Take Photo button
- Upload Photo button
- Camera and gallery icons
- Welcome text

✅ **Model Tests**
- Tile JSON serialization
- Tile JSON deserialization
- Tile equality comparison

✅ **Theme Tests**
- Primary color verification
- Material 3 usage

✅ **Navigation Tests**
- Route configuration

## 🎯 Manual Testing Checklist

### 1. Device Setup

#### Android Emulator
```bash
# List available emulators
flutter emulators

# Create new emulator if needed
flutter emulators --create

# Launch emulator
flutter emulators --launch <emulator_id>

# Run app
flutter run -d android
```

#### iOS Simulator (macOS only)
```bash
# Open simulator
open -a Simulator

# List devices
xcrun simctl list devices

# Run app
flutter run -d ios
```

### 2. Screen Navigation Test

**Expected Flow:**
1. ✅ HomeScreen displays with 2 buttons
2. ✅ Tap "Take Photo" or "Upload Photo"
3. ✅ Navigate to FloorSelectionScreen
4. ✅ Tap on image to select point
5. ✅ "Detect Floor" button appears
6. ✅ Navigate to TileCatalogScreen
7. ✅ Select a tile
8. ✅ "Apply Tile" button becomes active
9. ✅ Navigate to ResultScreen
10. ✅ View processed image
11. ✅ Save/Share/Try Another options work

### 3. UI Elements Test

**HomeScreen:**
- [ ] TileVision title in AppBar
- [ ] Grid icon displayed
- [ ] "Visualize Your Floor" heading
- [ ] "Take Photo" card with camera icon
- [ ] "Upload Photo" card with gallery icon
- [ ] Cards have 150px height
- [ ] Blue theme (#2196F3) applied

**FloorSelectionScreen:**
- [ ] Image displays correctly
- [ ] Tap detection works
- [ ] Red circle appears at tap point
- [ ] "Detect Floor" button functional
- [ ] Loading indicator shows during API call
- [ ] Green mask overlay appears (40% opacity)
- [ ] "Confirm" button enables after detection

**TileCatalogScreen:**
- [ ] Original image thumbnail at top
- [ ] 2-column grid layout
- [ ] Tile cards show image, name, size, price
- [ ] Selection highlights with blue border
- [ ] "Apply Tile" button at bottom
- [ ] Loading state during application

**ResultScreen:**
- [ ] Full-screen image display
- [ ] Zoom functionality (pinch/double-tap)
- [ ] Save button functional
- [ ] Share button functional
- [ ] "Try Another" button navigates back

## 🔧 Platform-Specific Setup

### Android

**Minimum Requirements:**
- Android SDK 21 or higher
- Android Studio (optional but recommended)

**Permissions (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

**Run on physical device:**
```bash
# Enable USB debugging on device
# Connect device via USB
flutter run
```

### iOS

**Minimum Requirements:**
- iOS 11.0 or higher
- Xcode (macOS only)
- CocoaPods

**Permissions (Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos of your room</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images</string>
```

**First-time setup:**
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

## 🐛 Troubleshooting

### "Flutter not found"
```bash
# Install Flutter: https://flutter.dev/docs/get-started/install
# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"  # Mac/Linux
```

### "No devices connected"
```bash
# Android
flutter emulators --launch <emulator_id>

# iOS (macOS)
open -a Simulator
```

### "Failed to get dependencies"
```bash
flutter clean
flutter pub get
```

### "Build failed"
```bash
# Android
flutter clean
cd android
./gradlew clean
cd ..
flutter build apk

# iOS
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter build ios
```

### API Connection Issues
```bash
# Make sure backend is running on http://localhost:8000
# Update API base URL in lib/services/api_service.dart if needed

# For Android emulator, use:
# http://10.0.2.2:8000 instead of http://localhost:8000

# For iOS simulator, localhost should work
```

## 📊 Mock Data

Mock data is available in `test/mock_data.dart` for testing:

```dart
import 'test/mock_data.dart';

// Get sample tiles
final tiles = MockData.getTiles();

// Get specific tile
final tile = MockData.getTileById(1);

// Filter by price
final affordableTiles = MockData.getTilesByPriceRange(0, 1000);

// Mock API responses
final segmentationResponse = MockData.getMockSegmentationResponse();
```

## 🎨 Testing with Mock Backend

If backend is not available, you can test UI with mock data:

1. Create a mock API service
2. Use test/mock_data.dart
3. Replace API calls with mock responses

## ✅ Pre-Deployment Checklist

- [ ] All tests passing (`flutter test`)
- [ ] No linter warnings (`flutter analyze`)
- [ ] App runs on Android emulator
- [ ] App runs on iOS simulator (if macOS)
- [ ] Navigation between screens works
- [ ] Image picker permissions granted
- [ ] API service connects to backend
- [ ] Error handling tested
- [ ] Loading states verified
- [ ] UI responsive on different screen sizes

## 📱 Build for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only)
```bash
flutter build ios --release
# Open in Xcode for signing and distribution
```

---

**Happy Testing!** 🚀
