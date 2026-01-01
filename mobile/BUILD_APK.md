# 📱 Building APK for TileVision Mobile App

## 🎯 Quick Build Guide

### Prerequisites
- Flutter SDK installed and configured
- Android Studio (for Android SDK)
- Connected Android device OR ready to build APK

---

## 🚀 Step 1: Update API URL (Already Done ✅)

The API URL has been updated to production:
- **Production URL**: `https://tilevision.onrender.com`
- Located in: `mobile/lib/services/api_service.dart`

---

## 🔨 Step 2: Build Release APK

### Option A: Build APK (Recommended for Sharing)

```bash
cd mobile
flutter build apk --release
```

**Output Location:**
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Build App Bundle (For Play Store)

```bash
cd mobile
flutter build appbundle --release
```

**Output Location:**
```
mobile/build/app/outputs/bundle/release/app-release.aab
```

---

## 📦 Step 3: Find Your APK

After building, the APK will be at:
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

**File Size**: Typically 20-40 MB

---

## 📤 Step 4: Share Your APK

### Method 1: Direct Transfer
1. Copy `app-release.apk` to your phone
2. Install directly (enable "Install from Unknown Sources" if needed)
3. Share via:
   - Email
   - Google Drive
   - WhatsApp/Telegram
   - USB transfer

### Method 2: Upload to Cloud Storage
1. Upload to Google Drive / Dropbox / OneDrive
2. Share the download link
3. Recipients can download and install

### Method 3: QR Code (Easy Sharing)
1. Upload APK to a file sharing service
2. Generate QR code for the download link
3. Share QR code - recipients scan and download

---

## ✅ Pre-Build Checklist

- [x] API URL updated to production: `https://tilevision.onrender.com`
- [ ] Test app on device/emulator first
- [ ] Verify all features work (camera, tile selection, AI processing)
- [ ] Check app version in `pubspec.yaml` (currently `1.0.0+1`)

---

## 🧪 Test Before Sharing

### 1. Test on Device/Emulator
```bash
cd mobile
flutter run --release
```

### 2. Test Key Features
- [ ] Camera/Gallery image picker works
- [ ] Floor selection screen loads
- [ ] Tile catalog loads from API
- [ ] Tile application works (AI processing)
- [ ] Result screen displays correctly
- [ ] Share functionality works

---

## 📝 Build Commands Reference

### Development Build (Debug)
```bash
flutter build apk --debug
```

### Release Build (For Sharing)
```bash
flutter build apk --release
```

### Split APKs (Smaller file size)
```bash
flutter build apk --split-per-abi
```
Creates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (x86)

**Recommendation**: Use `--split-per-abi` for smaller file sizes!

---

## 🔧 Troubleshooting

### Build Fails

**Error**: "Gradle build failed"
```bash
cd mobile/android
./gradlew clean
cd ../..
flutter clean
flutter pub get
flutter build apk --release
```

### APK Too Large

**Solution**: Use split APKs
```bash
flutter build apk --release --split-per-abi
```

### Signing Issues

For production, you'll need a signing key. For testing/demo:
- Current config uses debug signing (works for sharing)
- For Play Store: Create a release keystore

---

## 📱 Installation Instructions for Recipients

### For Android Users:

1. **Enable Unknown Sources:**
   - Settings → Security → Enable "Install from Unknown Sources"
   - OR Settings → Apps → Special Access → Install Unknown Apps

2. **Download APK:**
   - Open the APK file
   - Tap "Install"
   - Wait for installation

3. **Launch App:**
   - Find "TileVision" in app drawer
   - Open and test!

---

## 🎯 For Your Pitch

### What to Include:

1. **APK File**: `app-release.apk`
2. **Demo Video**: Screen recording showing the app in action
3. **Screenshots**: Key screens (home, tile selection, results)
4. **Features List**:
   - AI-powered floor segmentation
   - Real-time tile visualization
   - Multiple tile options
   - Share results

### Pitch Points:

✅ **Working Backend**: Live on Render.com  
✅ **AI Integration**: Gemini 2.5 for realistic tile replacement  
✅ **Free Hosting**: $0/month (Render + UptimeRobot)  
✅ **Production Ready**: Fully functional app  

---

## 🚀 Quick Build Command

**One-liner to build and locate APK:**
```bash
cd mobile && flutter build apk --release --split-per-abi && echo "APK built at: build/app/outputs/flutter-apk/"
```

---

## 📊 File Sizes (Approximate)

- **Full APK**: ~30-40 MB
- **Split APK (arm64)**: ~15-20 MB (recommended)
- **Split APK (armeabi)**: ~15-20 MB

---

## ✅ Ready to Build!

Your app is configured for production. Just run:

```bash
cd mobile
flutter build apk --release --split-per-abi
```

Then share the APK from `build/app/outputs/flutter-apk/` folder!

**Good luck with your pitch! 🎉**

