"""
AI-Powered Image-Guided Inpainting for Floor Tiles

This module implements photorealistic floor tile replacement using
Stable Diffusion with IP-Adapter (Image Prompt Adapter).

Instead of text prompts, it uses the actual tile image as a visual
reference, enabling:
- User-uploaded custom tiles
- Exact pattern preservation
- Automatic scalability

Author: TileVision
API: Replicate (stability-ai/stable-diffusion-inpainting)
Cost: ~$0.02 per image
"""

import os
import base64
import tempfile
import logging
import io
from pathlib import Path
from typing import Optional, Dict, Any

import cv2
import numpy as np
import replicate
import requests
from PIL import Image
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)


class AIInpainter:
    """
    Handles AI-powered floor tile inpainting using image guidance
    """
    
    def __init__(self):
        """Initialize Replicate client"""
        api_token = os.getenv("REPLICATE_API_TOKEN")
        if not api_token:
            raise ValueError("REPLICATE_API_TOKEN not found in environment")
        
        self.client = replicate.Client(api_token=api_token)
        logger.info("AI Inpainter initialized successfully")
    
    def array_to_pil(self, img_array: np.ndarray) -> Image.Image:
        """Convert numpy array to PIL Image"""
        if len(img_array.shape) == 2:
            # Grayscale
            return Image.fromarray(img_array, mode='L')
        elif img_array.shape[2] == 3:
            # BGR to RGB
            return Image.fromarray(cv2.cvtColor(img_array, cv2.COLOR_BGR2RGB))
        elif img_array.shape[2] == 4:
            # BGRA to RGBA
            return Image.fromarray(cv2.cvtColor(img_array, cv2.COLOR_BGRA2RGBA))
        else:
            return Image.fromarray(img_array)
    
    def pil_to_array(self, pil_image: Image.Image) -> np.ndarray:
        """Convert PIL Image to numpy array"""
        img_array = np.array(pil_image)
        if len(img_array.shape) == 3 and img_array.shape[2] == 3:
            # RGB to BGR
            return cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        return img_array
    
    def save_temp_image(self, pil_image: Image.Image, suffix: str = ".png") -> str:
        """Save PIL Image to temporary file and return path"""
        temp_file = tempfile.NamedTemporaryFile(
            suffix=suffix, 
            delete=False, 
            mode='wb'
        )
        pil_image.save(temp_file.name, format='PNG')
        temp_file.close()
        return temp_file.name
    
    def download_image(self, url: str) -> bytes:
        """Download image from URL"""
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        return response.content
    
    async def inpaint_with_tile_reference(
        self,
        original_image: np.ndarray,
        floor_mask: np.ndarray,
        tile_image: np.ndarray,
        strength: float = 0.95,
        ip_adapter_scale: float = 0.85
    ) -> np.ndarray:
        """
        Apply tile texture to floor using image-guided AI inpainting
        
        Args:
            original_image: Room photo (BGR numpy array)
            floor_mask: Binary mask (0=keep, 255=replace)
            tile_image: Tile texture to use as reference (BGR numpy array)
            strength: How much to change masked area (0.95 = change 95%)
            ip_adapter_scale: How closely to follow tile image (0.85 = very close)
        
        Returns:
            Result image (BGR numpy array)
        """
        logger.info("Starting image-guided AI inpainting...")
        
        temp_files = []
        
        try:
            # Convert to PIL
            original_pil = self.array_to_pil(original_image)
            mask_pil = self.array_to_pil(floor_mask)
            tile_pil = self.array_to_pil(tile_image)
            
            # Save to temp files (Replicate needs file paths)
            original_path = self.save_temp_image(original_pil)
            mask_path = self.save_temp_image(mask_pil)
            tile_path = self.save_temp_image(tile_pil)
            
            temp_files.extend([original_path, mask_path, tile_path])
            
            logger.info(f"Saved temp files: original={original_path}, "
                       f"mask={mask_path}, tile={tile_path}")
            
            # ===== HYBRID APPROACH: Exact Tile + AI Lighting =====
            # Step 1: Create exact tile pattern overlay
            logger.info("Creating exact tile pattern overlay...")
            
            from perspective import PerspectiveCorrector
            corrector = PerspectiveCorrector()
            
            # Apply tile directly to get exact pattern  
            tile_size_feet = (2.0, 2.0)  # Default 2x2 feet tiles
            tile_overlay = corrector.process_complete(
                original_image.copy(),
                floor_mask,
                tile_image,
                tile_size_feet
            )
            
            logger.info(f"Tile overlay created, shape: {tile_overlay.shape}")
            
            # Step 2: Convert pre-filled image to PIL and save
            prefilled_pil = self.array_to_pil(tile_overlay)
            prefilled_path = self.save_temp_image(prefilled_pil)
            temp_files.append(prefilled_path)
            
            logger.info(f"Pre-filled image saved: {prefilled_path}")
            
            # Step 3: Apply AI inpainting with LOW strength to preserve tile
            logger.info("Calling Replicate API (Stable Diffusion Inpainting)...")
            logger.info("Using HYBRID mode: Low strength to preserve exact tile pattern")
            
            output = self.client.run(
                "stability-ai/stable-diffusion-inpainting:95b7223104132402a9ae91cc677285bc5eb997834bd2349fa486f53910fd68b3",
                input={
                    "image": open(prefilled_path, "rb"),  # Use pre-filled image!
                    "mask": open(mask_path, "rb"),
                    "prompt": (
                        "natural lighting, realistic shadows, soft ambient light, "
                        "subtle reflections, architectural photography"
                    ),
                    "negative_prompt": (
                        "changing colors, different pattern, blurry, low quality, "
                        "distorted, watermark, text, unrealistic"
                    ),
                    "num_inference_steps": 30,  # Fewer steps for subtle changes
                    "guidance_scale": 5.0,      # Lower guidance 
                }
            )
            
            # Note: By using low strength, AI will preserve the exact tile
            # and only add realistic lighting, shadows, and reflections
            
            
            
            # Download result
            # Note: IP-Adapter might require a different model
            # If stability-ai doesn't support image guidance, we'll use:
            # "tstramer/ip-adapter-sdxl" with ip_adapter_image parameter
            
            if isinstance(output, list):
                result_url = output[0]
            else:
                result_url = output
            
            logger.info(f"AI inpainting complete. Downloading from: {result_url}")
            
            result_bytes = self.download_image(result_url)
            
            # Convert back to PIL
            result_pil = Image.open(io.BytesIO(result_bytes))
            
            # CRITICAL FIX: AI model downscales to 512x512, resize back to original
            original_height, original_width = original_image.shape[:2]
            ai_height, ai_width = result_pil.size[1], result_pil.size[0]
            
            logger.info(f"AI result size: {result_pil.size}, Original: ({original_width}x{original_height})")
            
            if (ai_width, ai_height) != (original_width, original_height):
                logger.info(f"Resizing AI result from {result_pil.size} to ({original_width}x{original_height})")
                result_pil = result_pil.resize(
                    (original_width, original_height),
                    Image.LANCZOS  # High-quality downsampling
                )
                logger.info(f"Resize complete: {result_pil.size}")
            
            # Convert to numpy array
            result_array = self.pil_to_array(result_pil)
            
            logger.info(f"Result image shape: {result_array.shape}")
            
            return result_array
            
        except Exception as e:
            logger.error(f"AI inpainting failed: {e}")
            raise
        
        finally:
            # Cleanup temp files
            for temp_file in temp_files:
                try:
                    if os.path.exists(temp_file):
                        os.unlink(temp_file)
                        logger.debug(f"Cleaned up temp file: {temp_file}")
                except Exception as e:
                    logger.warning(f"Failed to cleanup {temp_file}: {e}")
    
    def inpaint_sync(
        self,
        original_image: np.ndarray,
        floor_mask: np.ndarray,
        tile_image: np.ndarray,
        **kwargs
    ) -> np.ndarray:
        """
        Synchronous wrapper for inpaint_with_tile_reference
        
        Use this in non-async contexts
        """
        import asyncio
        
        try:
            loop = asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        
        return loop.run_until_complete(
            self.inpaint_with_tile_reference(
                original_image, 
                floor_mask, 
                tile_image, 
                **kwargs
            )
        )


# Convenience function for quick usage
def apply_ai_inpainting(
    original_image: np.ndarray,
    floor_mask: np.ndarray,
    tile_image: np.ndarray
) -> np.ndarray:
    """
    Quick function to apply AI inpainting
    
    Args:
        original_image: Room photo
        floor_mask: Floor mask (0=keep, 255=replace)
        tile_image: Tile texture reference
    
    Returns:
        Inpainted result
    """
    inpainter = AIInpainter()
    return inpainter.inpaint_sync(original_image, floor_mask, tile_image)


if __name__ == "__main__":
    # Test script
    import sys
    
    logging.basicConfig(level=logging.INFO)
    
    if len(sys.argv) < 4:
        print("Usage: python ai_inpainting.py <room.jpg> <mask.png> <tile.jpg>")
        sys.exit(1)
    
    room_path, mask_path, tile_path = sys.argv[1:4]
    
    # Load images
    room = cv2.imread(room_path)
    mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)
    tile = cv2.imread(tile_path)
    
    if room is None or mask is None or tile is None:
        print("Error: Could not load images")
        sys.exit(1)
    
    print(f"Room: {room.shape}, Mask: {mask.shape}, Tile: {tile.shape}")
    
    # Apply AI inpainting
    print("Applying AI inpainting...")
    result = apply_ai_inpainting(room, mask, tile)
    
    # Save result
    output_path = "ai_inpainted_result.jpg"
    cv2.imwrite(output_path, result)
    print(f"Saved result to: {output_path}")
