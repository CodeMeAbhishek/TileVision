#!/bin/bash
# Fix image_gallery_saver namespace issue

PACKAGE_PATH="$HOME/.pub-cache/hosted/pub.dev/image_gallery_saver-2.0.3/android/build.gradle"

if [ -f "$PACKAGE_PATH" ]; then
    if ! grep -q "namespace" "$PACKAGE_PATH"; then
        # Add namespace after android block
        sed -i '/android\s*{/a\    namespace = "com.example.image_gallery_saver"' "$PACKAGE_PATH"
        echo "Fixed namespace in image_gallery_saver"
    else
        echo "Namespace already exists"
    fi
else
    echo "Package not found. Run 'flutter pub get' first"
fi

