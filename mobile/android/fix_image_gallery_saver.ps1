# Fix image_gallery_saver namespace and AndroidManifest issues
$packageBasePath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\image_gallery_saver-2.0.3\android"
$buildGradlePath = "$packageBasePath\build.gradle"
$manifestPath = "$packageBasePath\src\main\AndroidManifest.xml"

# Fix 1: Add namespace and fix JVM target in build.gradle
if (Test-Path $buildGradlePath) {
    $content = Get-Content $buildGradlePath -Raw
    
    # Add namespace if missing
    if ($content -notmatch "namespace\s*=") {
        # Add namespace after android block
        $content = $content -replace "(android\s*\{)", "`$1`n    namespace = 'com.example.image_gallery_saver'"
        Write-Host "Added namespace to build.gradle"
    } else {
        Write-Host "Namespace already exists in build.gradle"
    }
    
    # Fix JVM target compatibility - ensure Java and Kotlin use same target
    if ($content -notmatch "kotlinOptions\s*\{") {
        # Add kotlinOptions after android block or at the end
        if ($content -match "(android\s*\{[^}]*\})") {
            $content = $content -replace "(android\s*\{[^}]*\})", "`$1`n`n    kotlinOptions {`n        jvmTarget = '17'`n    }"
        } else {
            $content = $content + "`n`nkotlinOptions {`n    jvmTarget = '17'`n}"
        }
        Write-Host "Added kotlinOptions with JVM target 17"
    } else {
        # Update existing kotlinOptions to use JVM 17
        $content = $content -replace "jvmTarget\s*=\s*['`"]\d+['`"]", "jvmTarget = '17'"
        Write-Host "Updated kotlinOptions JVM target to 17"
    }
    
    # Ensure compileOptions uses Java 17
    if ($content -notmatch "compileOptions\s*\{") {
        if ($content -match "(android\s*\{[^}]*\})") {
            $content = $content -replace "(android\s*\{[^}]*\})", "`$1`n`n    compileOptions {`n        sourceCompatibility JavaVersion.VERSION_17`n        targetCompatibility JavaVersion.VERSION_17`n    }"
        } else {
            $content = $content + "`n`ncompileOptions {`n    sourceCompatibility JavaVersion.VERSION_17`n    targetCompatibility JavaVersion.VERSION_17`n}"
        }
        Write-Host "Added compileOptions with Java 17"
    } else {
        # Update existing compileOptions to use Java 17
        $content = $content -replace "sourceCompatibility\s+JavaVersion\.VERSION_\d+", "sourceCompatibility JavaVersion.VERSION_17"
        $content = $content -replace "targetCompatibility\s+JavaVersion\.VERSION_\d+", "targetCompatibility JavaVersion.VERSION_17"
        Write-Host "Updated compileOptions to Java 17"
    }
    
    # Fix compileSdk - ensure it's at least 34 (required for lStar attribute)
    # Remove old compileSdkVersion if present (conflicts with compileSdk)
    $content = $content -replace "compileSdkVersion\s+\d+", ""
    
    if ($content -notmatch "compileSdk\s*=") {
        # Add compileSdk after namespace or in defaultConfig
        if ($content -match "(namespace\s*=\s*['`"][^'`"]+['`"])") {
            $content = $content -replace "(namespace\s*=\s*['`"][^'`"]+['`"])", "`$1`n    compileSdk = 34"
        } elseif ($content -match "(android\s*\{)") {
            $content = $content -replace "(android\s*\{)", "`$1`n    compileSdk = 34"
        }
        Write-Host "Added compileSdk = 34"
    } else {
        # Update existing compileSdk to at least 34
        $content = $content -replace "compileSdk\s*=\s*\d+", "compileSdk = 34"
        Write-Host "Updated compileSdk to 34"
    }
    
    Set-Content $buildGradlePath -Value $content -NoNewline
} else {
    Write-Host "build.gradle not found at: $buildGradlePath"
}

# Fix 2: Remove package attribute from AndroidManifest.xml
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    
    if ($manifestContent -match 'package\s*=\s*"[^"]*"') {
        # Remove package attribute from manifest tag
        $manifestContent = $manifestContent -replace '\s+package\s*=\s*"[^"]*"', ''
        Set-Content $manifestPath -Value $manifestContent -NoNewline
        Write-Host "Removed package attribute from AndroidManifest.xml"
    } else {
        Write-Host "Package attribute not found in AndroidManifest.xml (already fixed)"
    }
} else {
    Write-Host "AndroidManifest.xml not found at: $manifestPath"
    Write-Host "Run 'flutter pub get' first"
}

# Fix 3: Remove unused Registrar import from Kotlin file
$kotlinFile = "$packageBasePath\src\main\kotlin\com\example\imagegallerysaver\ImageGallerySaverPlugin.kt"
if (Test-Path $kotlinFile) {
    $kotlinContent = Get-Content $kotlinFile -Raw
    
    if ($kotlinContent -match "import io\.flutter\.plugin\.common\.PluginRegistry\.Registrar") {
        # Remove the unused Registrar import
        $kotlinContent = $kotlinContent -replace "import io\.flutter\.plugin\.common\.PluginRegistry\.Registrar\s*\n", ""
        Set-Content $kotlinFile -Value $kotlinContent -NoNewline
        Write-Host "Removed unused Registrar import from Kotlin file"
    } else {
        Write-Host "Registrar import not found (already fixed)"
    }
} else {
    Write-Host "Kotlin file not found at: $kotlinFile"
}

