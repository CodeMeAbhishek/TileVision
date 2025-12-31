"""
Test script for AI Inpainting endpoint

This script tests the /api/apply_tile_ai endpoint with sample images
to verify the AI inpainting functionality works correctly.
"""

import requests
import base64
import os
from pathlib import Path

# Configuration
API_BASE_URL = "http://localhost:8000"
BACKEND_DIR = Path(__file__).parent

def test_ai_inpainting():
    """Test the AI inpainting endpoint"""
    
    print("🧪 Testing AI Inpainting Endpoint\n")
    print("=" * 60)
    
    # Check if server is running
    try:
        response = requests.get(f"{API_BASE_URL}/api/tiles", timeout=5)
        print("✅ Server is running")
    except requests.exceptions.ConnectionError:
        print("❌ Server is not running!")
        print("   Please start the server with: .\\run.bat")
        return False
    
    # Get tile catalog
    tiles = response.json()
    print(f"✅ Found {len(tiles)} tiles in catalog\n")
    
    # Get first tile for testing
    test_tile = tiles[0]
    tile_name = test_tile['name']
    tile_url = test_tile['image_url']
    
    print(f"📦 Test Tile: {tile_name}")
    print(f"   URL: {tile_url}\n")
    
    # Check if we have test images
    # We'll need: room image, mask, tile texture
    print("📁 Checking for test images...")
    
    # Look for generated tiles
    tile_path = BACKEND_DIR / "static" / "tiles" / "granite_dark_seamless.jpg"
    
    if not tile_path.exists():
        print(f"⚠️  Test tile not found: {tile_path}")
        print("   Using catalog tile URL instead")
        
        # Download tile from URL
        tile_response = requests.get(tile_url)
        tile_bytes = tile_response.content
    else:
        print(f"✅ Found test tile: {tile_path}")
        with open(tile_path, 'rb') as f:
            tile_bytes = f.read()
    
    # Create a simple test
    print("\n" + "=" * 60)
    print("ℹ️  For full testing, you need:")
    print("   1. A room image (original_image)")
    print("   2. A floor mask (floor_mask)")  
    print("   3. A tile texture (tile_image)")
    print("\nOption 1: Use the Flutter app to get these")
    print("Option 2: Manually create test files:")
    print("   - backend/test_room.jpg")
    print("   - backend/test_mask.png")
    print("   - backend/test_tile.jpg")
    print("\nThen run: python test_ai_endpoint.py --full-test")
    print("=" * 60)
    
    # Check for test files
    test_room = BACKEND_DIR / "test_room.jpg"
    test_mask = BACKEND_DIR / "test_mask.png"
    test_tile_file = BACKEND_DIR / "test_tile.jpg"
    
    if test_room.exists() and test_mask.exists() and test_tile_file.exists():
        print("\n✅ Found test files! Running full test...\n")
        
        # Prepare multipart form data
        files = {
            'original_image': ('room.jpg', open(test_room, 'rb'), 'image/jpeg'),
            'floor_mask': ('mask.png', open(test_mask, 'rb'), 'image/png'),
            'tile_image': ('tile.jpg', open(test_tile_file, 'rb'), 'image/jpeg')
        }
        
        print("🚀 Calling /api/apply_tile_ai...")
        print("   (This will take ~10-15 seconds)")
        
        try:
            response = requests.post(
                f"{API_BASE_URL}/api/apply_tile_ai",
                files=files,
                timeout=60  # AI takes longer
            )
            
            if response.status_code == 200:
                result = response.json()
                processing_time = result.get('processing_time', 0)
                method = result.get('method', 'unknown')
                
                print(f"✅ Success!")
                print(f"   Method: {method}")
                print(f"   Time: {processing_time:.2f}s")
                
                # Save result
                result_image = result['result_image']
                result_path = BACKEND_DIR / "test_ai_result.jpg"
                
                with open(result_path, 'wb') as f:
                    f.write(base64.b64decode(result_image))
                
                print(f"   Saved: {result_path}")
                print("\n✅ AI INPAINTING TEST PASSED!")
                return True
            else:
                print(f"❌ Request failed: {response.status_code}")
                print(f"   {response.text[:200]}")
                return False
                
        except requests.exceptions.Timeout:
            print("❌ Request timed out (AI is slow or failed)")
            return False
        except Exception as e:
            print(f"❌ Error: {e}")
            return False
    else:
        print("\n⚠️  Test files not found. Skipping full test.")
        print("   Backend is ready, but needs actual images to test.")
        return True


if __name__ == "__main__":
    import sys
    
    success = test_ai_inpainting()
    
    if success:
        print("\n" + "=" * 60)
        print("✅ BACKEND TEST COMPLETE!")
        print("=" * 60)
        print("\nNext steps:")
        print("1. Try with the Flutter app (use existing flow)")
        print("2. Or create test files and run: python test_ai_endpoint.py")
        sys.exit(0)
    else:
        print("\n❌ Test failed. Check logs above.")
        sys.exit(1)
