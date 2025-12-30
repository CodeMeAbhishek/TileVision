#!/bin/bash
# TileVision Flutter Mobile App Runner
# This script sets up and runs the Flutter mobile app

set -e  # Exit on error

echo "================================"
echo "TileVision Flutter App"
echo "================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed"
    echo "Please install Flutter from https://flutter.dev"
    exit 1
fi

echo "Using Flutter:"
flutter --version

# Get dependencies
echo ""
echo "Installing dependencies..."
flutter pub get

echo "✓ Dependencies installed"

# Check for available devices
echo ""
echo "Checking for available devices..."
flutter devices

# Ask user which platform to run on
echo ""
echo "================================"
echo "Select Platform:"
echo "================================"
echo "1. Android Emulator"
echo "2. iOS Simulator (macOS only)"
echo "3. Chrome (Web)"
echo "4. Auto-detect"
echo ""

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "Starting Android Emulator..."
        flutter run -d android
        ;;
    2)
        echo ""
        echo "Starting iOS Simulator..."
        flutter run -d ios
        ;;
    3)
        echo ""
        echo "Starting Chrome..."
        flutter run -d chrome
        ;;
    *)
        echo ""
        echo "Auto-detecting device..."
        flutter run
        ;;
esac
