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
            # Prepare data URIs for the model
            # Nano Banana Pro expects image_input as array of data URIs
            room_data_uri = f"data:image/jpeg;base64,{room_image_b64.split(',')[1] if ',' in room_image_b64 else room_image_b64}"
            material_data_uri = f"data:image/jpeg;base64,{material_image_b64.split(',')[1] if ',' in material_image_b64 else material_image_b64}"
            
            logger.info(f"Calling google/nano-banana-pro with 2 images and prompt...")
            
            # Call Nano Banana Pro with retry logic
            max_retries = 3
            output = None
            
            for attempt in range(max_retries):
                try:
                    output = self.client.run(
                        "google/nano-banana-pro",
                        input={
                            "image_input": [room_data_uri, material_data_uri],
                            "prompt": prompt,
                            "resolution": "2K",  # Good balance of quality and speed
                            "aspect_ratio": "match_input_image",  # Preserve original aspect ratio
                            "output_format": "jpg"
                        }
                    )
                    break # Success
                except Exception as e:
                    if attempt < max_retries - 1:
                        wait_time = 2 * (2 ** attempt)
                        logger.warning(f"Nano Banana API attempt {attempt+1} failed ({e}). Retrying in {wait_time}s...")
                        time.sleep(wait_time)
                    else:
                        raise e # Re-raise last error
            
            # Output is a FileOutput object with URL
            if not output:
                logger.error("Nano Banana Pro returned no output")
                return None, {"success": False, "error": "No image generated"}
            
            # Get original image dimensions to preserve them
            original_image_bytes = base64.b64decode(room_image_b64.split(',')[1] if ',' in room_image_b64 else room_image_b64)
            original_image = Image.open(io.BytesIO(original_image_bytes))
            original_width, original_height = original_image.size
            logger.info(f"Original image dimensions: {original_width}x{original_height}")
            
            # Download the result image
            import requests
            result_url = str(output)
            logger.info(f"Downloading result from: {result_url[:50]}...")
            
            response = requests.get(result_url, timeout=30)
            response.raise_for_status()
            
            # Load AI output and resize to match original dimensions
            ai_output_image = Image.open(io.BytesIO(response.content))
            ai_width, ai_height = ai_output_image.size
            logger.info(f"AI output dimensions: {ai_width}x{ai_height}")
            
            if (ai_width, ai_height) != (original_width, original_height):
                logger.info(f"Resizing AI output from {ai_width}x{ai_height} to {original_width}x{original_height}")
                ai_output_image = ai_output_image.resize(
                    (original_width, original_height),
                    Image.Resampling.LANCZOS  # High-quality resize
                )
            
            # Convert resized image to base64
            buffered = io.BytesIO()
            ai_output_image.save(buffered, format="JPEG", quality=95)
            result_b64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
            
            logger.info(f"✅ Nano Banana Pro Material Replacement complete! Dimensions preserved.")
            
            return result_b64, {
                "success": True,
                "model": "google/nano-banana-pro",
                "method": "Multi-Image Conversational Editing",
                "resolution": "2K",
                "dimensions_preserved": f"{original_width}x{original_height}"
            }

        except Exception as e:
            logger.error(f"❌ Nano Banana Pro Material Replacement failed: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return None, {"success": False, "error": str(e)}
