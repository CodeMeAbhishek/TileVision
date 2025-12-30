# Flutter Setup Guide for TileVision

## 📋 Prerequisites

Flutter is required to run the mobile app. Follow these steps to set it up:

## 🔽 Install Flutter

### Windows

1. **Download Flutter SDK**
   - Visit: https://docs.flutter.dev/get-started/install/windows
   - Download the latest stable release
   - Extract to: `C:\src\flutter` (recommended)

2. **Update PATH**
   ```powershell
   # Add to System Environment Variables:
   C:\src\flutter\bin
   ```

3. **Run Flutter Doctor**
   ```bash
   flutter doctor
   ```

4. **Install Android Studio** (for Android development)
   - Download: https://developer.android.com/studio
   - Install Android SDK
   - Install Android SDK Command-line Tools

5. **Accept Android Licenses**
   ```bash
   flutter doctor --android-licenses
   ```

### macOS

1. **Download Flutter SDK**
   ```bash
   cd ~/development
   curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.16.0-stable.zip
   unzip flutter_macos_3.16.0-stable.zip
   ```

2. **Update PATH**
   ```bash
   # Add to ~/.zshrc or ~/.bash_profile:
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

3. **Run Flutter Doctor**
   ```bash
   flutter doctor
   ```

4. **Install Xcode** (for iOS development)
   - Download from Mac App Store
   - Install Xcode command-line tools:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

5. **Install CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

### Linux

1. **Download Flutter SDK**
   ```bash
   cd ~/development
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
   tar xf flutter_linux_3.16.0-stable.tar.xz
   ```

2. **Update PATH**
   ```bash
   # Add to ~/.bashrc:
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

3. **Run Flutter Doctor**
   ```bash
   flutter doctor
   ```

4. **Install Android Studio**
   - Download: https://developer.android.com/studio
   - Follow installation instructions

## ✅ Verify Installation

After installation, run:
```bash
flutter doctor -v
```

Expected output:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] VS Code (version x.x.x)
[✓] Connected device
```

## 🚀 Run the TileVision App

Once Flutter is installed:

### Option 1: Using the run script
```bash
cd c:\Clients\tile visualization\tilevision\mobile

# Windows
run.bat

# macOS/Linux
chmod +x run.sh
./run.sh
```

### Option 2: Manual commands
```bash
cd c:\Clients\tile visualization\tilevision\mobile

# Get dependencies
flutter pub get

# Run on available device
flutter run

# Or specify device
flutter run -d android     # Android
flutter run -d ios        # iOS (macOS only)
flutter run -d chrome     # Web
```

## 📱 Setup Android Emulator

1. **Open Android Studio**
2. **Tools > Device Manager**
3. **Create Device**
   - Choose: Pixel 5 or similar
   - System Image: Android 11+ (API 30+)
   - Click Finish

4. **Start Emulator**
   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

## 📱 Setup iOS Simulator (macOS only)

1. **Open Simulator**
   ```bash
   open -a Simulator
   ```

2. **Select Device**
   - File > Open Simulator > iPhone 14 (or similar)

3. **Run App**
   ```bash
   flutter run -d ios
   ```

## 🧪 Run Tests

```bash
cd c:\Clients\tile visualization\tilevision\mobile
flutter test
```

## 🔧 Common Issues

### "cmdlet not found" or "command not found"
- Flutter not in PATH
- Restart terminal after adding to PATH
- Run `flutter doctor` to verify

### "No devices found"
- Start an emulator/simulator
- Connect a physical device with USB debugging
- Run `flutter devices` to check

### "License not accepted"
```bash
flutter doctor --android-licenses
```

### "CocoaPods not installed" (macOS)
```bash
sudo gem install cocoapods
```

## 📚 Additional Resources

- **Flutter Documentation**: https://docs.flutter.dev
- **Flutter YouTube**: https://www.youtube.com/flutterdev
- **Flutter Community**: https://flutter.dev/community
- **Sample Apps**: https://github.com/flutter/samples

## 🎯 Quick Verification

After setup, verify everything works:

```bash
# 1. Check Flutter
flutter doctor

# 2. Get dependencies
cd c:\Clients\tile visualization\tilevision\mobile
flutter pub get

# 3. Run tests
flutter test

# 4. Run app
flutter run
```

All should complete successfully! ✅
