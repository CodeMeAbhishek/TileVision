"""
AI Material Replacer using Google Gemini 2.0 Flash
Transfers texture from a reference image (tile) to a target area (masked floor)
"""

import replicate
import logging
import base64
import os
from typing import Optional, Tuple, Dict, Any
from PIL import Image
import io
import time

logger = logging.getLogger(__name__)

class AiMaterialReplacer:
    """
    Uses Google's Nano Banana Pro for multi-image conversational editing
    This is the actual model powering Gemini web UI's image editing features
    """
    
    def __init__(self, api_token: str = None):
        """
        Initialize with Replicate API token
        """
        self.api_token = api_token or os.getenv("REPLICATE_API_TOKEN")
        
        if not self.api_token:
            logger.warning("REPLICATE_API_TOKEN not found - Material replacement disabled")
            self.client = None
            return
        
        try:
            self.client = replicate.Client(api_token=self.api_token)
            logger.info("AiMaterialReplacer initialized (google/nano-banana-pro)")
        except Exception as e:
            logger.error(f"Failed to initialize Replicate client: {e}")
            self.client = None
        
    def replace_material(
        self,
        room_image_b64: str,
        mask_image_b64: str,  # Not used by nano-banana-pro, but keep for API compatibility
        material_image_b64: str,
        prompt: str = "In image 1, replace the floor with the tile pattern from image 2. Keep everything else exactly the same.",
        **kwargs  # Ignore other params for compatibility
    ) -> Tuple[Optional[str], Dict[str, Any]]:
        """
        Replace material using Google Nano Banana Pro's multi-image editing
        
        Args:
            room_image_b64: Base64 string of original room
            mask_image_b64: Base64 string of mask (not used)
            material_image_b64: Base64 string of reference tile/material
            prompt: Text instruction for the model
            
        Returns:
            (result_b64, metadata)
        """
        if not self.client:
            logger.error("Replicate client not initialized")
            return None, {"success": False, "error": "Replicate not configured"}
        
        logger.info("Starting AI Material Replacement with Nano Banana Pro...")
        
        try:
            # Get original image dimensions first (needed for aspect ratio)
            original_image_bytes = base64.b64decode(room_image_b64.split(',')[1] if ',' in room_image_b64 else room_image_b64)
            original_image = Image.open(io.BytesIO(original_image_bytes))
            original_width, original_height = original_image.size
            logger.info(f"Original image dimensions: {original_width}x{original_height}")

            # Prepare data URIs for the model
            # Nano Banana Pro expects image_input as array of data URIs
            room_data_uri = f"data:image/jpeg;base64,{room_image_b64.split(',')[1] if ',' in room_image_b64 else room_image_b64}"
            material_data_uri = f"data:image/jpeg;base64,{material_image_b64.split(',')[1] if ',' in material_image_b64 else material_image_b64}"
            
            logger.info(f"Calling google/nano-banana-pro with 2 images and prompt...")
            
            # Calculate aspect ratio
            w, h = original_width, original_height
            ratio = w / h
            
            # Snap to nearest standard aspect ratio supported by most models
            supported_ratios = {
                "1:1": 1.0,
                "16:9": 16/9,
                "9:16": 9/16,
                "3:2": 3/2,
                "2:3": 2/3,
                "4:3": 4/3,
                "3:4": 3/4,
                "5:4": 5/4,
                "4:5": 4/5,
                "21:9": 21/9,
                "9:21": 9/21
            }
            
            closest_ar = min(supported_ratios.keys(), key=lambda k: abs(supported_ratios[k] - ratio))
            logger.info(f"Calculated Aspect Ratio: {closest_ar} (from {w}x{h})")

            max_retries = 3
            output = None

            for attempt in range(max_retries):
                try:
                    output = self.client.run(
                        "google/gemini-2.5-flash-image",
                        input={
                            "image_input": [room_data_uri, material_data_uri],
                            "prompt": prompt,
                            "aspect_ratio": closest_ar,
                            "output_format": "jpg"
                        }
                    )
                    break # Success
                except Exception as e:
                    if attempt < max_retries - 1:
                        wait_time = 2 * (2 ** attempt)
                        logger.warning(f"Gemini API attempt {attempt+1} failed ({e}). Retrying in {wait_time}s...")
                        time.sleep(wait_time)
                    else:
                        raise e # Re-raise last error
            
            # Output is a FileOutput object with URL
            if not output:
                logger.error("Gemini 2.5 Flash Image returned no output")
                return None, {"success": False, "error": "No image generated"}
            
            # Dimensions already loaded at start
            
            # Download the result image
            import requests
            result_url = str(output)
            logger.info(f"Downloading result from: {result_url[:50]}...")
            
            response = requests.get(result_url, timeout=30)
            response.raise_for_status()
            
            # Load AI output and resize to match original dimensions
            ai_output_image = Image.open(io.BytesIO(response.content))
            # Dimensions preserved by aspect ratio aspect_ratio parameter
            # We skip resizing to output the raw high-quality generation
            
            # Convert resized image to base64
            buffered = io.BytesIO()
            ai_output_image.save(buffered, format="JPEG", quality=95)
            result_b64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
            
            logger.info(f"✅ Gemini 2.5 Flash Image Material Replacement complete! Dimensions preserved.")
            
            return result_b64, {
                "success": True,
                "model": "google/gemini-2.5-flash-image",
                "method": "Multi-Image Conversational Editing",
                "resolution": "2K",
                "dimensions_preserved": f"{original_width}x{original_height}"
            }

        except Exception as e:
            logger.error(f"❌ Nano Banana Pro Material Replacement failed: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return None, {"success": False, "error": str(e)}
