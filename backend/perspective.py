"""
Perspective correction and tile application module with real perspective transformation
"""
import cv2
import numpy as np
from PIL import Image
from io import BytesIO
import logging
from typing import Tuple

logger = logging.getLogger(__name__)


class PerspectiveCorrector:
    """
    Handles perspective correction and tile pattern application
    """
    
    def __init__(self):
        """Initialize the perspective corrector"""
        logger.info("PerspectiveCorrector initialized")
    
    def _improve_mask(self, mask: np.ndarray, original_image: np.ndarray = None) -> np.ndarray:
        """
        Improve mask quality with edge-aware gap filling
        
        Goals:
        1. Fill floor gaps
        2. PRESERVE furniture legs by using edge detection
        """
        # Ensure binary
        if mask.dtype != np.uint8:
            mask = (mask * 255).astype(np.uint8)
        _, mask = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)
        
        # Save original mask to know what was definitely floor
        original_mask = mask.copy()
        
        
        # Step 1: Aggressive closing to fill ALL gaps (including legs)
        # 200x200 kernel bridges virtually any furniture gap
        kernel_large = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (200, 200))
        filled_mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel_large, iterations=1)
        
        # Step 2: Fill ALL internal holes to ensure solid floor
        # (moved this BEFORE leg verification to prevent re-filling legs)
        contours, _ = cv2.findContours(filled_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if contours:
            largest_contour = max(contours, key=cv2.contourArea)
            # Create a completely solid mask from the largest contour
            solid_mask = np.zeros_like(filled_mask)
            cv2.drawContours(solid_mask, [largest_contour], -1, 255, thickness=cv2.FILLED)
            filled_mask = solid_mask

        # Step 3: Precise Leg Protection (Subtract legs from the solid mask)
        if original_image is not None:
             # Convert to gray
            if len(original_image.shape) == 3:
                gray = cv2.cvtColor(original_image, cv2.COLOR_BGR2GRAY)
            else:
                gray = original_image

            # Identify "newly filled" areas (Gaps that were filled in Step 1 & 2)
            # Use original_mask to know what was originally detected as floor
            newly_filled = cv2.subtract(filled_mask, original_mask)
            
            # COLOR AWARENESS: Precise Dark Object Protection
            # Lower threshold to 40 to only catch deep black features (legs)
            _, dark_objects = cv2.threshold(gray, 40, 255, cv2.THRESH_BINARY_INV)
            
            # Intersect: Only remove mask if it's a NEWLY FILLED area AND it's VERY DARK
            legs_to_remove = cv2.bitwise_and(newly_filled, newly_filled, mask=dark_objects)
             
            # Subtract the specific dark pixels from the filled mask
            final_mask = cv2.subtract(filled_mask, legs_to_remove)
            
            # Ensure we didn't remove actual floor (add back original)
            final_mask = cv2.bitwise_or(final_mask, original_mask)
            
            mask = final_mask
        else:
            mask = filled_mask
            
        return mask

    def process_complete(
        self,
        original_image: np.ndarray,
        floor_mask: np.ndarray,
        tile_image: np.ndarray,
        tile_size_feet: tuple[float, float] = (2.0, 2.0),
        pixels_per_foot: int = 50
    ) -> np.ndarray:
        """
        Direct texture overlay - preserves exact catalog appearance
        
        Args:
            original_image: Original room photo
            floor_mask: Binary mask of floor area
            tile_image: Single tile texture
            tile_size_feet: Real-world tile dimensions (width, height) in feet
            pixels_per_foot: Scale factor for tile size
        
        Returns: Final visualization with exact catalog tiles
        """
        try:
            # Step 0: Improve mask quality
            floor_mask = self._improve_mask(floor_mask, original_image)
            
            # Step 1: Find floor bounding box (instead of corners)
            contours, _ = cv2.findContours(
                floor_mask, 
                cv2.RETR_EXTERNAL, 
                cv2.CHAIN_APPROX_SIMPLE
            )
            
            if not contours:
                logger.warning("No floor contours found, using fallback")
                return self._simple_overlay(original_image, floor_mask, tile_image)
            
            # Get bounding rectangle
            largest_contour = max(contours, key=cv2.contourArea)
            x, y, w, h = cv2.boundingRect(largest_contour)
            
            # Step 2: Calculate tile size in pixels
            tile_size_px = int(max(tile_size_feet) * pixels_per_foot)
            
            # Step 3: Create seamless tile pattern fitted to floor size
            # Calculate how many tiles needed
            tiles_x = int(np.ceil(w / tile_size_px)) + 1
            tiles_y = int(np.ceil(h / tile_size_px)) + 1
            
            # Resize single tile with highest quality
            tile_resized = cv2.resize(
                tile_image,
                (tile_size_px, tile_size_px),
                interpolation=cv2.INTER_LANCZOS4
            )
            
            # Create pattern by tiling
            row = np.hstack([tile_resized] * tiles_x)
            tile_pattern = np.vstack([row] * tiles_y)
            
            # Crop to exact floor size
            tile_pattern = tile_pattern[:h, :w]
            
            # Step 4: Create canvas and place pattern
            canvas = np.zeros_like(original_image)
            canvas[y:y+h, x:x+w] = tile_pattern
            
            # Step 5: Simple alpha blend (no color manipulation)
            # Normalize mask to 0-1 range
            if len(floor_mask.shape) == 2:
                mask_3ch = cv2.cvtColor(floor_mask, cv2.COLOR_GRAY2BGR)
            else:
                mask_3ch = floor_mask
            
            mask_norm = mask_3ch.astype(np.float32) / 255.0
            
            # Direct alpha compositing - preserves exact tile colors
            result = (
                canvas.astype(np.float32) * mask_norm +
                original_image.astype(np.float32) * (1 - mask_norm)
            ).astype(np.uint8)
            
            logger.info(f"Applied tiles directly: {tiles_x}x{tiles_y} tiles, " 
                       f"pattern size: {tile_pattern.shape}")
            
            return result
            
        except Exception as e:
            logger.error(f"Perspective correction error: {e}")
            # Fallback: simple overlay without perspective
            return self._simple_overlay(original_image, floor_mask, tile_image)

    def _simple_overlay(self, original, mask, tile):
        """Fallback: simple tile overlay without perspective"""
        # Resize tile to average size
        tile_resized = cv2.resize(tile, (200, 200))
        
        # Create simple repeating pattern
        h, w = original.shape[:2]
        tiles_x = w // 200 + 1
        tiles_y = h // 200 + 1
        
        row = np.hstack([tile_resized] * tiles_x)
        pattern = np.vstack([row] * tiles_y)
        pattern = pattern[:h, :w]
        
        # Simple alpha blend
        mask_3ch = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR) / 255.0
        result = (pattern * mask_3ch + original * (1 - mask_3ch)).astype(np.uint8)
        
        return result
