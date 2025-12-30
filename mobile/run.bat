@echo off
REM TileVision Flutter Mobile App Runner
REM This script sets up and runs the Flutter mobile app

echo ================================
echo TileVision Flutter App
echo ================================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed
    echo Please install Flutter from https://flutter.dev
    exit /b 1
)

echo Using Flutter:
flutter --version

REM Get dependencies
echo.
echo Installing dependencies...
flutter pub get

if %errorlevel% neq 0 (
    echo Error: Failed to get dependencies
    exit /b 1
)

echo √ Dependencies installed

REM Check for available devices
echo.
echo Checking for available devices...
flutter devices

REM Ask user which platform to run on
echo.
echo ================================
echo Select Platform:
echo ================================
echo 1. Android Emulator
echo 2. iOS Simulator (macOS only)
echo 3. Chrome (Web)
echo 4. Auto-detect
echo.

set /p choice="Enter choice (1-4): "

if "%choice%"=="1" (
    echo.
    echo Starting Android Emulator...
    flutter run -d android
) else if "%choice%"=="2" (
    echo.
    echo Starting iOS Simulator...
    flutter run -d ios
) else if "%choice%"=="3" (
    echo.
    echo Starting Chrome...
    flutter run -d chrome
) else (
    echo.
    echo Auto-detecting device...
    flutter run
)
