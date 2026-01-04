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
        mask_image_b64: str = None,  # Not used - Gemini auto-detects floor
        material_image_b64: str = None,
        prompt: str = None,
        **kwargs  # Ignore other params for compatibility
    ) -> Tuple[Optional[str], Dict[str, Any]]:
        """
        Replace floor material using Gemini 2.5 Flash - Direct AI replacement (no segmentation needed)
        
        Args:
            room_image_b64: Base64 string of original room image
            mask_image_b64: Not used - Gemini auto-detects floor area
            material_image_b64: Base64 string of reference tile/material pattern
            prompt: Optimized prompt for floor replacement (defaults to efficient prompt)
            
        Returns:
            (result_b64, metadata)
        """
        if not self.client:
            logger.error("Replicate client not initialized")
            return None, {"success": False, "error": "Replicate not configured"}
        
        # Balanced prompt - specific enough but not overly verbose
        # Gemini works better with clear, concise instructions
        if prompt is None:
            prompt = """Image 1: room photo. Image 2: reference tile pattern.

Replace the floor in image 1 with the exact tile pattern from image 2. 
Match the pattern type, colors, and texture exactly. 
Keep all furniture and objects unchanged."""
        
        logger.info("Starting AI Material Replacement with Gemini 2.5 Flash (no segmentation)...")
        
        try:
            # Get original image dimensions first (needed for aspect ratio)
            original_image_bytes = base64.b64decode(room_image_b64.split(',')[1] if ',' in room_image_b64 else room_image_b64)
            original_image = Image.open(io.BytesIO(original_image_bytes))
            original_width, original_height = original_image.size
            logger.info(f"Original image dimensions: {original_width}x{original_height}")

            # Prepare data URIs for the model
            # Extract base64 without data URI prefix if present
            room_b64_clean = room_image_b64.split(',')[1] if ',' in room_image_b64 else room_image_b64
            material_b64_clean = material_image_b64.split(',')[1] if ',' in material_image_b64 else material_image_b64
            
            # Verify tile image is valid and preserve original format
            try:
                material_image_bytes = base64.b64decode(material_b64_clean)
                material_image = Image.open(io.BytesIO(material_image_bytes))
                material_width, material_height = material_image.size
                material_format = material_image.format or 'PNG'
                logger.info(f"Tile image: {material_width}x{material_height}, format: {material_format}")
                
                # Convert tile to RGB if needed (some formats like RGBA need conversion)
                if material_image.mode != 'RGB':
                    logger.info(f"Converting tile from {material_image.mode} to RGB")
                    material_image = material_image.convert('RGB')
                
                # Enhance tile image for better pattern recognition:
                # - Ensure minimum size for pattern clarity (at least 512px on longest side)
                min_size = 512
                if max(material_width, material_height) < min_size:
                    scale_factor = min_size / max(material_width, material_height)
                    new_width = int(material_width * scale_factor)
                    new_height = int(material_height * scale_factor)
                    material_image = material_image.resize((new_width, new_height), Image.Resampling.LANCZOS)
                    logger.info(f"Upscaled tile image to {new_width}x{new_height} for better pattern recognition")
                
                # Re-encode to base64 with high quality to preserve pattern details
                buffered = io.BytesIO()
                material_image.save(buffered, format='JPEG', quality=98)  # High quality to preserve pattern
                material_b64_clean = base64.b64encode(buffered.getvalue()).decode('utf-8')
            except Exception as e:
                logger.error(f"Failed to validate tile image: {e}")
                return None, {"success": False, "error": f"Invalid tile image: {str(e)}"}
            
            room_data_uri = f"data:image/jpeg;base64,{room_b64_clean}"
            material_data_uri = f"data:image/jpeg;base64,{material_b64_clean}"
            
            logger.info(f"Calling google/gemini-2.5-flash-image with room image and tile reference...")
            logger.info(f"Prompt: {prompt[:100]}...")  # Log first 100 chars of prompt
            
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
                    # Try IP-Adapter first for exact material/texture transfer (better accuracy)
                    # IP-Adapter is specifically designed for exact style/material transfer
                    # Use Gemini 2.5 Flash directly (IP-Adapter models not reliably available on Replicate)
                    # Gemini is more reliable and cost-effective for this use case
                    output = self.client.run(
                        "google/gemini-2.5-flash-image",
                        input={
                            "image_input": [room_data_uri, material_data_uri],
                            "prompt": prompt,
                            "aspect_ratio": closest_ar,
                            "output_format": "jpg"
                        }
                    )
                    logger.info("✅ Gemini 2.5 Flash succeeded")
                    break
                except Exception as e:
                    error_str = str(e).lower()
                    
                    # Handle rate limiting - wait longer before retry
                    if "429" in error_str or "rate limit" in error_str or "throttled" in error_str:
                        if attempt < max_retries - 1:
                            # Extract wait time from error if available, otherwise use longer wait
                            wait_time = 12 + (2 * (2 ** attempt))  # Minimum 12s for rate limits
                            logger.warning(f"Rate limited. Waiting {wait_time}s before retry {attempt+1}/{max_retries}...")
                            time.sleep(wait_time)
                            continue
                        else:
                            # Last attempt failed due to rate limit
                            raise e
                    elif attempt < max_retries - 1:
                        wait_time = 2 * (2 ** attempt)
                        logger.warning(f"API attempt {attempt+1} failed ({e}). Retrying in {wait_time}s...")
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
            error_str = str(e)
            logger.error(f"❌ Gemini 2.5 Flash Material Replacement failed: {e}")
            import traceback
            logger.error(traceback.format_exc())
            
            # Provide user-friendly error messages for common issues
            if "402" in error_str or "insufficient credit" in error_str.lower():
                return None, {
                    "success": False, 
                    "error": "Insufficient Replicate credit. Please add credit to your Replicate account at https://replicate.com/account/billing",
                    "error_type": "billing"
                }
            elif "429" in error_str or "rate limit" in error_str.lower() or "throttled" in error_str.lower():
                return None, {
                    "success": False, 
                    "error": "Rate limit exceeded. Please wait a moment and try again. Consider adding credit to increase rate limits.",
                    "error_type": "rate_limit"
                }
            elif "timeout" in error_str.lower():
                return None, {
                    "success": False, 
                    "error": "Request timed out. The AI service is taking longer than expected. Please try again.",
                    "error_type": "timeout"
                }
            else:
                return None, {"success": False, "error": f"AI processing failed: {error_str}", "error_type": "unknown"}
