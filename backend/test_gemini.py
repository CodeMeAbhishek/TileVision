"""
Quick test script to verify Gemini API integration
"""
import os
import sys
import base64
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from ai_material_replacer import AiMaterialReplacer

def test_gemini():
    print("🧪 Testing Gemini API Integration...")
    
    # Check API key
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("❌ GOOGLE_API_KEY not found in environment")
        return False
    
    print(f"✅ API Key found: {api_key[:20]}...")
    
    # Initialize replacer
    try:
        replacer = AiMaterialReplacer()
        if not replacer.client:
            print("❌ Gemini client failed to initialize")
            return False
        print("✅ Gemini client initialized")
    except Exception as e:
        print(f"❌ Failed to create replacer: {e}")
        return False
    
    print("\n✅ All checks passed! Gemini is ready to use.")
    print("\n📝 To test with actual images, restart the backend:")
    print("   .\\run.bat")
    print("\nThen in the mobile app, enable 'AI Realistic Lighting' and apply a tile.")
    
    return True

if __name__ == "__main__":
    # Load .env
    from dotenv import load_dotenv
    load_dotenv()
    
    success = test_gemini()
    sys.exit(0 if success else 1)
