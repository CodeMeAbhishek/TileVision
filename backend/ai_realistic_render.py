"""
AI-powered realistic tile rendering using ControlNet
Enhances lighting while preserving exact tile patterns
"""

import replicate
import requests
import numpy as np
import cv2
import base64
import io
from PIL import Image
import logging
import time
import os
from typing import Optional, Tuple

logger = logging.getLogger(__name__)


class RealisticTileRenderer:
    """
    Uses ControlNet Tile to add realistic lighting to tile overlays
    """
    
    def __init__(self, api_token: str):
        """
        Initialize with Replicate API token
        
        Args:
            api_token: Replicate API token
        """
        if not api_token or api_token == "your_token_here":
            raise ValueError("Valid Replicate API token required")
        
        self.client = replicate.Client(api_token=api_token)
        logger.info("RealisticTileRenderer initialized")
    
    def enhance_with_controlnet(
        self,
        tile_overlay: np.ndarray,
        original_room: Optional[np.ndarray] = None,
        strength: float = 0.3,
        guidance_scale: float = 7.5,
        conditioning_scale: float = 0.85
    ) -> Tuple[Optional[np.ndarray], dict]:
        """
        Enhance tile overlay with realistic lighting using ControlNet
        
        Args:
            tile_overlay: Direct tile overlay (exact pattern)
            original_room: Original room image (for context, optional)
            strength: How much AI modifies (0.2-0.4, lower = more preservation)
            guidance_scale: Prompt following strength (7-8 recommended)
            conditioning_scale: Pattern preservation (0.8-0.95, higher = more preservation)
        
        Returns:
            (enhanced_image, metadata) or (None, error_info)
        """
        
        logger.info("Starting ControlNet enhancement...")
        logger.info(f"  Strength: {strength}")
        logger.info(f"  Guidance: {guidance_scale}")
        logger.info(f"  Conditioning: {conditioning_scale}")
        
        try:
            # Resize if too large (ControlNet works best at 512-1024)
            h, w = tile_overlay.shape[:2]
            max_size = 1024
            
            if max(h, w) > max_size:
                scale = max_size / max(h, w)
                new_w = int(w * scale)
                new_h = int(h * scale)
                tile_overlay_resized = cv2.resize(
                    tile_overlay, 
                    (new_w, new_h),
                    interpolation=cv2.INTER_LANCZOS4
                )
                logger.info(f"  Resized: {w}x{h} → {new_w}x{new_h}")
            else:
                tile_overlay_resized = tile_overlay
                new_w, new_h = w, h
            
            # Convert to base64
            _, buffer = cv2.imencode('.png', tile_overlay_resized)
            overlay_b64 = base64.b64encode(buffer).decode()
            overlay_uri = f"data:image/png;base64,{overlay_b64}"
            
            logger.info("  Calling ControlNet API...")
            
            # Call ControlNet Tile model
            # Using lucataco/controlnet-tile (verified working)
            output = self.client.run(
                "lucataco/controlnet-tile:f688ff774c27a4843c819c9264c0f949925970bb278669ed9140364c8389869c",
                input={
                    "image": overlay_uri,
                    "prompt": """
                        photorealistic floor tiles with natural interior lighting,
                        realistic shadows and reflections,
                        professional architectural photography,
                        high quality indoor flooring,
                        natural ambient lighting,
                        sharp focus, 8k quality
                    """,
                    "negative_prompt": """
                        blurry, low quality, distorted, 
                        changed tile pattern, different tiles,
                        added furniture, added objects,
                        coffee tables, decorations,
                        cartoon, painting, illustration,
                        warped, deformed tiles
                    """,
                    "num_inference_steps": 25,
                    "guidance_scale": guidance_scale,
                    "controlnet_conditioning_scale": conditioning_scale,
                    "seed": int(time.time()),  # Random integer seed
                }
            )
            
            logger.info("  ControlNet API responded")
            
            # Get result URL
            result_url = output[0] if isinstance(output, list) else output
            
            # Download result
            logger.info(f"  Downloading result from: {result_url[:50]}...")
            response = requests.get(result_url, timeout=30)
            response.raise_for_status()
            
            # Decode image
            img = Image.open(io.BytesIO(response.content))
            result_array = np.array(img)
            
            # Convert RGB to BGR (OpenCV format)
            if len(result_array.shape) == 3 and result_array.shape[2] == 3:
                result_array = cv2.cvtColor(result_array, cv2.COLOR_RGB2BGR)
            
            # Resize back to original dimensions if needed
            if result_array.shape[:2] != tile_overlay.shape[:2]:
                result_array = cv2.resize(
                    result_array,
                    (tile_overlay.shape[1], tile_overlay.shape[0]),
                    interpolation=cv2.INTER_LANCZOS4
                )
            
            logger.info("✅ ControlNet enhancement complete")
            
            metadata = {
                "success": True,
                "model": "controlnet-tile",
                "strength": strength,
                "guidance_scale": guidance_scale,
                "conditioning_scale": conditioning_scale
            }
            
            return result_array, metadata
            
        except Exception as e:
            logger.error(f"❌ ControlNet enhancement failed: {e}")
            import traceback
            traceback.print_exc()
            
            return None, {
                "success": False,
                "error": str(e)
            }
    
    def validate_pattern_preserved(
        self,
        original: np.ndarray,
        enhanced: np.ndarray,
        threshold: Optional[float] = None
    ) -> Tuple[bool, float]:
        """
        Validate that AI preserved the tile pattern
        
        Args:
            original: Direct overlay
            enhanced: AI-enhanced version
            threshold: Acceptable difference (defaults to env var or 0.12)
        
        Returns:
            (is_preserved, similarity_score)
        """
        if threshold is None:
            threshold = float(os.getenv("AI_VALIDATION_THRESHOLD", "0.12"))
            logger.info(f"Using validation threshold: {threshold}")
        
        try:
            # Convert to grayscale
            orig_gray = cv2.cvtColor(original, cv2.COLOR_BGR2GRAY)
            enh_gray = cv2.cvtColor(enhanced, cv2.COLOR_BGR2GRAY)
            
            # Ensure same size
            if orig_gray.shape != enh_gray.shape:
                enh_gray = cv2.resize(enh_gray, (orig_gray.shape[1], orig_gray.shape[0]))
            
            # Compute structural similarity (requires skimage)
            try:
                from skimage.metrics import structural_similarity as ssim
                similarity = ssim(orig_gray, enh_gray)
            except ImportError:
                # Fallback: simple MSE-based similarity
                mse = np.mean((orig_gray - enh_gray) ** 2)
                similarity = 1.0 - (mse / 10000.0)  # Normalize
            
            difference = 1.0 - similarity
            preserved = difference <= threshold
            
            logger.info(f"  Pattern validation: {'✅ PASS' if preserved else '⚠️ FAIL'}")
            logger.info(f"  Similarity: {similarity:.3f} (difference: {difference:.3f})")
            
            return preserved, similarity
            
        except Exception as e:
            logger.error(f"Validation failed: {e}")
            # If validation fails, assume not preserved (safe fallback)
            return False, 0.0
    
    def hybrid_render(
        self,
        direct_overlay: np.ndarray,
        original_room: Optional[np.ndarray] = None,
        strength: float = 0.3,
        blend_ratio: float = 0.5
    ) -> np.ndarray:
        """
        Hybrid approach: Direct overlay + AI enhancement with blending
        
        Args:
            direct_overlay: Exact tile overlay
            original_room: Original room (optional)
            strength: AI modification strength
            blend_ratio: 0.0 = only direct, 1.0 = only AI (0.5 = 50/50)
        
        Returns:
            Blended result (fallback to direct on failure)
        """
        
        logger.info("Starting hybrid render...")
        
        # Get AI enhancement
        enhanced, metadata = self.enhance_with_controlnet(
            direct_overlay,
            original_room,
            strength=strength
        )
        
        if enhanced is None:
            logger.warning("AI enhancement failed, using direct overlay")
            return direct_overlay
        
        # Validate pattern
        preserved, similarity = self.validate_pattern_preserved(
            direct_overlay,
            enhanced
        )
        
        if not preserved:
            logger.warning(f"Pattern not preserved (similarity: {similarity:.3f})")
            logger.warning("Using direct overlay (safe fallback)")
            return direct_overlay
        
        # Blend direct overlay with AI enhancement
        result = cv2.addWeighted(
            direct_overlay, 1.0 - blend_ratio,
            enhanced, blend_ratio,
            0
        )
        
        logger.info(f"✅ Hybrid render complete (blend: {blend_ratio:.0%} AI)")
        
        return result


# Helper function for easy import
def enhance_tile_overlay(
    tile_overlay: np.ndarray,
    api_token: str,
    strength: float = 0.3,
    use_hybrid: bool = True,
    blend_ratio: float = 0.5
) -> np.ndarray:
    """
    Convenience function to enhance tile overlay
    
    Args:
        tile_overlay: Direct tile overlay
        api_token: Replicate API token
        strength: AI modification strength (0.2-0.4)
        use_hybrid: Use hybrid approach with blending
        blend_ratio: Blend ratio if using hybrid
    
    Returns:
        Enhanced overlay (or original on failure)
    """
    
    try:
        renderer = RealisticTileRenderer(api_token)
        
        if use_hybrid:
            return renderer.hybrid_render(
                tile_overlay,
                strength=strength,
                blend_ratio=blend_ratio
            )
        else:
            enhanced, _ = renderer.enhance_with_controlnet(
                tile_overlay,
                strength=strength
            )
            return enhanced if enhanced is not None else tile_overlay
            
    except Exception as e:
        logger.error(f"Enhancement failed: {e}")
        return tile_overlay
