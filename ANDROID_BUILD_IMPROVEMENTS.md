# 🔧 Android Build Configuration - Specific Improvements

**File**: `mobile/android/app/build.gradle.kts`  
**Current Status**: Functional but needs production hardening

---

## 🔴 Critical Issues

### 1. **Namespace Mismatch** ⚠️
**Line 9**: `namespace = "com.example.tilevision"`  
**Line 25**: `applicationId = "com.tilevision.app"`

**Issue**: Namespace and applicationId don't match. This can cause issues with R class generation and resource access.

**Fix**:
```kotlin
namespace = "com.tilevision.app"  // Should match applicationId
```

---

### 2. **Debug Signing in Release** ⚠️
**Line 38**: `signingConfig = signingConfigs.getByName("debug")`

**Issue**: Release builds are signed with debug keys. This prevents:
- Play Store distribution
- App updates
- Production security

**Fix**:
```kotlin
buildTypes {
    release {
        // Enable code shrinking and obfuscation
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
        
        // Use release signing config
        signingConfig = signingConfigs.getByName("release")
    }
}

// Add signing configs block
signingConfigs {
    create("release") {
        // Use environment variables for security
        val keystoreFile = System.getenv("KEYSTORE_FILE")
        val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
        val keyAlias = System.getenv("KEY_ALIAS")
        val keyPassword = System.getenv("KEY_PASSWORD")
        
        if (keystoreFile != null && keystorePassword != null && 
            keyAlias != null && keyPassword != null) {
            storeFile = file(keystoreFile)
            storePassword = keystorePassword
            this.keyAlias = keyAlias
            this.keyPassword = keyPassword
        } else {
            // Fallback to debug for local builds (not recommended for production)
            storeFile = file("${project.rootDir}/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
}
```

---

## 🟡 Recommended Improvements

### 3. **Add ProGuard Rules File**
**Missing**: `mobile/android/app/proguard-rules.pro`

**Create the file**:
```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep HTTP classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Keep Retrofit (if used)
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Keep image libraries
-keep class com.bumptech.glide.** { *; }
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
    <init>(...);
}

# Keep your app's classes
-keep class com.tilevision.app.** { *; }
```

---

### 4. **Add Build Variants**
**Enhancement**: Support for different build flavors (dev, staging, production)

**Add**:
```kotlin
flavorDimensions += "environment"

productFlavors {
    create("dev") {
        dimension = "environment"
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
        resValue("string", "app_name", "TileVision Dev")
    }
    
    create("staging") {
        dimension = "environment"
        applicationIdSuffix = ".staging"
        versionNameSuffix = "-staging"
        resValue("string", "app_name", "TileVision Staging")
    }
    
    create("production") {
        dimension = "environment"
        resValue("string", "app_name", "TileVision")
    }
}
```

---

### 5. **Optimize Build Performance**
**Add**:
```kotlin
android {
    // ... existing config ...
    
    // Enable build cache
    buildCache {
        isEnabled = true
    }
    
    // Parallel builds
    defaultConfig {
        // ... existing config ...
        
        // Enable multidex if needed
        multiDexEnabled = true
    }
    
    // Optimize dex options
    dexOptions {
        javaMaxHeapSize = "4g"
        preDexLibraries = true
    }
}
```

---

### 6. **Add Version Management**
**Enhancement**: Better version code management

**Add**:
```kotlin
defaultConfig {
    // ... existing config ...
    
    // Auto-increment version code (optional)
    versionCode = (System.currentTimeMillis() / 1000).toInt()
    versionName = "1.0.0"
    
    // Add build config fields for API URLs
    buildConfigField("String", "API_BASE_URL", "\"https://tilevision.onrender.com\"")
    buildConfigField("boolean", "ENABLE_LOGGING", "true")
}
```

---

### 7. **Add Lint Options**
**Enhancement**: Configure lint for better code quality

**Add**:
```kotlin
android {
    // ... existing config ...
    
    lint {
        // Don't abort build on lint errors
        abortOnError = false
        
        // Check all issues
        checkAllWarnings = true
        
        // Ignore warnings for dependencies
        disable.add("InvalidPackage")
        
        // Treat warnings as errors in release
        warningsAsErrors = false
    }
}
```

---

## 📋 Complete Improved build.gradle.kts

Here's the complete improved version:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tilevision.app"  // ✅ Fixed: matches applicationId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.tilevision.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex if needed
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Use environment variables for security
            val keystoreFile = System.getenv("KEYSTORE_FILE")
            val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
            val keyAlias = System.getenv("KEY_ALIAS")
            val keyPassword = System.getenv("KEY_PASSWORD")
            
            if (keystoreFile != null && keystorePassword != null && 
                keyAlias != null && keyPassword != null) {
                storeFile = file(keystoreFile)
                storePassword = keystorePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            } else {
                // Fallback: Use debug keys for local development only
                // ⚠️ WARNING: Never use this in CI/CD or production!
                logger.warn("⚠️ Using debug signing config. Set KEYSTORE_* environment variables for production builds.")
                storeFile = signingConfigs.getByName("debug").storeFile
                storePassword = signingConfigs.getByName("debug").storePassword
                this.keyAlias = signingConfigs.getByName("debug").keyAlias
                this.keyPassword = signingConfigs.getByName("debug").keyPassword
            }
        }
    }

    buildTypes {
        release {
            // ✅ Use release signing config
            signingConfig = signingConfigs.getByName("release")
            
            // Enable code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            // Keep debug builds fast
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    lint {
        abortOnError = false
        checkAllWarnings = true
        disable.add("InvalidPackage")
    }
    
    // Enable build cache for faster builds
    buildCache {
        isEnabled = true
    }
}

flutter {
    source = "../.."
}
```

---

## 🔑 Creating Production Keystore

To create a production keystore:

```bash
# Generate keystore
keytool -genkey -v -keystore tilevision-release.keystore \
  -alias tilevision-key -keyalg RSA -keysize 2048 \
  -validity 10000

# Store securely (never commit to git!)
# Add to .gitignore:
# *.keystore
# *.jks
```

**Set environment variables** (for CI/CD):
```bash
export KEYSTORE_FILE=/path/to/tilevision-release.keystore
export KEYSTORE_PASSWORD=your_keystore_password
export KEY_ALIAS=tilevision-key
export KEY_PASSWORD=your_key_password
```

---

## ✅ Checklist

Before production release:

- [ ] Fix namespace to match applicationId
- [ ] Create production keystore
- [ ] Configure release signing
- [ ] Create proguard-rules.pro file
- [ ] Test release build: `flutter build apk --release`
- [ ] Verify APK is signed correctly: `jarsigner -verify -verbose -certs app-release.apk`
- [ ] Test on real device
- [ ] Set up CI/CD with keystore (securely)

---

## 🚨 Security Notes

1. **Never commit keystore files to git**
2. **Use environment variables for credentials**
3. **Store keystore securely** (password manager, secure vault)
4. **Backup keystore** (you can't update app without it!)
5. **Use different keystores** for dev/staging/production

---

**Last Updated**: 2025-01-01

