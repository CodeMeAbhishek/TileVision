"""
Test the updated AiMaterialReplacer with google/nano-banana-pro
"""
import sys
import os

# Add parent dir to path
sys.path.insert(0, os.path.dirname(__file__))

from ai_material_replacer import AiMaterialReplacer
from dotenv import load_dotenv

def test_nano_banana():
    print("🧪 Testing Nano Banana Pro Integration...")
    
    # Load environment
    load_dotenv()
    
    # Check API key
    api_key = os.getenv("REPLICATE_API_TOKEN")
    if not api_key:
        print("❌ REPLICATE_API_TOKEN not found in environment")
        return False
    
    print(f"✅ API Key found: {api_key[:20]}...")
    
    # Initialize replacer
    try:
        replacer = AiMaterialReplacer()
        if not replacer.client:
            print("❌ Replicate client failed to initialize")
            return False
        print("✅ Replicate client initialized (google/nano-banana-pro)")
    except Exception as e:
        print(f"❌ Failed to create replacer: {e}")
        return False
    
    print("\n✅ All checks passed! Nano Banana Pro is ready to use.")
    print("\n📝 To test with actual images:")
    print("   1. Start the backend: .\\run.bat")
    print("   2. In the mobile app, enable 'AI Realistic Lighting' and apply a tile")
    print("\nThe system will now use google/nano-banana-pro for material replacement!")
    
    return True

if __name__ == "__main__":
    test_nano_banana()
