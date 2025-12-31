"""
Generate seamless tile textures with realistic grout using Replicate AI
"""

import replicate
import requests
from PIL import Image
import io
import random
import os
from pathlib import Path
import time

# You already have this token in your .env
from dotenv import load_dotenv
load_dotenv()

REPLICATE_TOKEN = os.getenv('REPLICATE_API_TOKEN')

# Set the API token for replicate client
if REPLICATE_TOKEN:
    os.environ["REPLICATE_API_TOKEN"] = REPLICATE_TOKEN

def generate_seamless_tile_texture(
    tile_type: str,
    tile_color: str,
    output_path: str,
    size: int = 1024
):
    """
    Generate a single seamless tile texture
    
    Args:
        tile_type: "marble", "ceramic", "wood", "granite", "terracotta"
        tile_color: "white", "beige", "dark", "natural", etc.
        output_path: Where to save (e.g., "marble_white_seamless.jpg")
        size: Texture resolution (1024x1024 recommended)
    """
    
    print(f"\n{'='*60}")
    print(f"Generating: {tile_type} {tile_color}")
    print(f"{'='*60}")
    
    # Craft the perfect prompt for realistic tiles with grout
    prompt = f"""
    Professional seamless repeating pattern of {tile_color} {tile_type} floor tiles,
    square tiles arranged in grid pattern,
    clearly visible individual tiles with clean edges,
    thin light gray grout lines between each tile,
    grout lines have subtle depth and shadows,
    beveled tile edges with realistic lighting,
    photorealistic high-quality flooring texture,
    top-down perfectly flat view,
    even professional lighting,
    8K ultra detailed,
    seamless tileable texture without visible seams,
    architectural visualization quality
    """
    
    negative_prompt = """
    blurry, low quality, distorted, warped,
    no grout lines, merged tiles, fused tiles,
    grid overlay, artificial lines, drawn lines,
    visible seams, pattern mismatch,
    angled view, perspective, 3D view,
    text, watermark, signature
    """
    
    try:
        print("📤 Sending request to Replicate AI...")
        print(f"   Model: SDXL (Stable Diffusion XL)")
        print(f"   Resolution: {size}x{size}")
        
        # Create Replicate client with explicit token
        client = replicate.Client(api_token=REPLICATE_TOKEN)
        
        # Use Replicate's SDXL model
        output = client.run(
            "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
            input={
                "prompt": prompt,
                "negative_prompt": negative_prompt,
                "width": size,
                "height": size,
                "num_outputs": 1,
                "scheduler": "K_EULER",
                "num_inference_steps": 40,
                "guidance_scale": 7.5,
                "seed": random.randint(1, 1000000),  # Random integer for variety
            }
        )
        
        print("✅ Generation complete!")
        
        # Output is a list of URLs
        image_url = output[0] if isinstance(output, list) else output
        
        print(f"📥 Downloading image from: {image_url[:50]}...")
        
        # Download the generated image
        response = requests.get(image_url, timeout=30)
        response.raise_for_status()
        
        # Open and save
        img = Image.open(io.BytesIO(response.content))
        
        # Ensure RGB mode
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Save with high quality
        img.save(output_path, 'JPEG', quality=95)
        
        print(f"💾 Saved to: {output_path}")
        print(f"   Size: {img.size}")
        print(f"   Mode: {img.mode}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error generating texture: {e}")
        print(f"   Creating fallback texture instead...")
        create_fallback_texture(tile_type, tile_color, output_path, size)
        return False

def create_fallback_texture(
    tile_type: str,
    tile_color: str,
    output_path: str,
    size: int
):
    """
    Create a basic solid color texture as fallback
    """
    import numpy as np
    
    print(f"🎨 Creating fallback texture...")
    
    # Base colors
    color_map = {
        "white": (245, 245, 250),
        "beige": (220, 210, 190),
        "dark": (60, 60, 65),
        "natural": (180, 160, 140),
        "gray": (150, 150, 155),
    }
    
    base_color = color_map.get(tile_color.lower(), (200, 200, 200))
    
    # Create texture with slight noise
    texture = np.full((size, size, 3), base_color, dtype=np.uint8)
    noise = np.random.normal(0, 3, (size, size, 3)).astype(np.int16)
    texture = np.clip(texture + noise, 0, 255).astype(np.uint8)
    
    img = Image.fromarray(texture)
    img.save(output_path, 'JPEG', quality=95)
    
    print(f"✅ Fallback texture saved")

def generate_all_tiles():
    """
    Generate complete set of tile textures for catalog
    """
    
    print("\n" + "="*60)
    print("TILEVISION - SEAMLESS TILE TEXTURE GENERATOR")
    print("="*60)
    
    # Check API token
    if not REPLICATE_TOKEN or REPLICATE_TOKEN == "your_token_here":
        print("\n❌ ERROR: REPLICATE_API_TOKEN not found in .env")
        print("   Please add your Replicate API token to backend/.env")
        return False
    
    print(f"\n✅ Replicate API token found: {REPLICATE_TOKEN[:15]}...")
    
    # Create output directory
    output_dir = Path("../mobile/assets/tiles")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"📁 Output directory: {output_dir.absolute()}")
    
    # Define tiles to generate
    tiles_to_generate = [
        {
            "type": "marble",
            "color": "white",
            "filename": "marble_white_seamless.jpg",
            "name": "Carrara Marble White"
        },
        {
            "type": "ceramic",
            "color": "beige",
            "filename": "ceramic_beige_seamless.jpg",
            "name": "Ceramic Beige Classic"
        },
        {
            "type": "wood",
            "color": "natural oak",
            "filename": "wooden_oak_seamless.jpg",
            "name": "Oak Wood Natural"
        },
        {
            "type": "granite",
            "color": "dark gray",
            "filename": "granite_dark_seamless.jpg",
            "name": "Granite Dark Luxury"
        },
        {
            "type": "terracotta",
            "color": "rustic orange",
            "filename": "terracotta_seamless.jpg",
            "name": "Terracotta Rustic"
        },
    ]
    
    print(f"\n🎨 Generating {len(tiles_to_generate)} tile textures...")
    print("⏱️  This will take ~3-5 minutes total\n")
    
    results = []
    
    for i, tile_spec in enumerate(tiles_to_generate, 1):
        print(f"\n[{i}/{len(tiles_to_generate)}] Processing: {tile_spec['name']}")
        
        output_path = output_dir / tile_spec['filename']
        
        success = generate_seamless_tile_texture(
            tile_type=tile_spec['type'],
            tile_color=tile_spec['color'],
            output_path=str(output_path),
            size=1024
        )
        
        results.append({
            "name": tile_spec['name'],
            "file": tile_spec['filename'],
            "success": success
        })
        
        # Rate limiting: wait 12 seconds between requests (6 req/min limit)
        if i < len(tiles_to_generate):
            print("\n⏳ Waiting 12 seconds before next generation (rate limit)...")
            time.sleep(12)
    
    # Summary
    print("\n" + "="*60)
    print("GENERATION COMPLETE")
    print("="*60)
    
    successful = sum(1 for r in results if r['success'])
    total = len(results)
    
    print(f"\n✅ Successfully generated: {successful}/{total} textures")
    
    if successful < total:
        print(f"⚠️  {total - successful} textures used fallback (solid colors)")
    
    print(f"\n📁 All textures saved to: {output_dir.absolute()}")
    print("\nGenerated files:")
    for result in results:
        status = "✅" if result['success'] else "⚠️ "
        print(f"  {status} {result['file']} - {result['name']}")
    
    print("\n" + "="*60)
    print("NEXT STEPS:")
    print("="*60)
    print("1. Check the generated textures in mobile/assets/tiles/")
    print("2. Update Flutter pubspec.yaml to include these assets")
    print("3. Update tile catalog to use new seamless textures")
    print("4. Restart Flutter app and test!")
    print("="*60)
    
    return True

if __name__ == "__main__":
    success = generate_all_tiles()
    
    if success:
        print("\n🎉 All done! Ready to use in your app.")
    else:
        print("\n⚠️  Some issues occurred. Check messages above.")
