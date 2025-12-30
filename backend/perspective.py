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
    
    def find_floor_corners(self, mask: np.ndarray) -> np.ndarray:
        """
        Extract 4 corner points from floor mask
        
        Returns: numpy array shape (4, 2) with corners [TL, TR, BR, BL]
        """
        # Find contours in mask
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            raise ValueError("No contours found in mask")
        
        # Get largest contour (should be the floor)
        floor_contour = max(contours, key=cv2.contourArea)
        
        # Approximate to polygon to reduce points
        epsilon = 0.02 * cv2.arcLength(floor_contour, True)
        approx = cv2.approxPolyDP(floor_contour, epsilon, True)
        
        # If we got exactly 4 points, use them
        if len(approx) == 4:
            corners = approx.reshape(4, 2)
        else:
            # Otherwise, get bounding rectangle
            rect = cv2.minAreaRect(floor_contour)
            corners = cv2.boxPoints(rect).astype(np.int32)
        
        # Order points: [top-left, top-right, bottom-right, bottom-left]
        corners = self._order_points(corners)
        
        return corners.astype(np.float32)

    def _order_points(self, pts: np.ndarray) -> np.ndarray:
        """
        Order points consistently: TL, TR, BR, BL
        """
        # Sort by y-coordinate
        sorted_pts = pts[np.argsort(pts[:, 1])]
        
        # Top two points
        top = sorted_pts[:2]
        top = top[np.argsort(top[:, 0])]  # Left to right
        
        # Bottom two points  
        bottom = sorted_pts[2:]
        bottom = bottom[np.argsort(bottom[:, 0])]  # Left to right
        
        return np.array([top[0], top[1], bottom[1], bottom[0]], dtype=np.float32)

    def calculate_homography(self, corners: np.ndarray) -> tuple[np.ndarray, tuple[int, int]]:
        """
        Calculate perspective transform matrix
        
        Returns: (3x3 transform matrix, (width, height) of destination)
        """
        tl, tr, br, bl = corners
        
        # Calculate dimensions for destination rectangle
        # Use maximum dimensions to avoid distortion
        
        # Width: max of top and bottom edges
        width_top = np.linalg.norm(tr - tl)
        width_bottom = np.linalg.norm(br - bl)
        max_width = int(max(width_top, width_bottom))
        
        # Height: max of left and right edges
        height_left = np.linalg.norm(bl - tl)
        height_right = np.linalg.norm(br - tr)
        max_height = int(max(height_left, height_right))
        
        # Define destination rectangle (perfect rectangle view from top)
        dst_corners = np.array([
            [0, 0],                           # Top-left
            [max_width - 1, 0],               # Top-right
            [max_width - 1, max_height - 1],  # Bottom-right
            [0, max_height - 1]               # Bottom-left
        ], dtype=np.float32)
        
        # Calculate perspective transform matrix
        transform_matrix = cv2.getPerspectiveTransform(corners, dst_corners)
        
        return transform_matrix, (max_width, max_height)

    def create_tile_pattern(
        self, 
        tile_image: np.ndarray, 
        dimensions: tuple[int, int],
        tile_size_px: int = 100
    ) -> np.ndarray:
        """
        Create repeating tile pattern
        
        Args:
            tile_image: Single tile image (H, W, 3)
            dimensions: (width, height) of target area
            tile_size_px: Size of each tile in pixels
        
        Returns: Tiled pattern image
        """
        width, height = dimensions
        
        # Resize single tile to tile_size_px x tile_size_px
        tile_resized = cv2.resize(tile_image, (tile_size_px, tile_size_px))
        
        # Calculate how many tiles needed
        tiles_x = int(np.ceil(width / tile_size_px)) + 1
        tiles_y = int(np.ceil(height / tile_size_px)) + 1
        
        # Create pattern by stacking tiles
        row = np.hstack([tile_resized] * tiles_x)
        pattern = np.vstack([row] * tiles_y)
        
        # Crop to exact dimensions
        pattern = pattern[:height, :width]
        
        return pattern

    def apply_tiles(
        self,
        original: np.ndarray,
        mask: np.ndarray,
        tile_pattern: np.ndarray,
        transform: np.ndarray
    ) -> np.ndarray:
        """
        Apply tile pattern to floor area with perspective correction
        
        Returns: Final composite image
        """
        # Warp tile pattern from rectangle to floor perspective
        inverse_transform = np.linalg.inv(transform)
        
        warped_tiles = cv2.warpPerspective(
            tile_pattern,
            inverse_transform,
            (original.shape[1], original.shape[0]),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_CONSTANT,
            borderValue=(0, 0, 0)
        )
        
        # Create 3-channel mask
        if len(mask.shape) == 2:
            mask_3ch = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
        else:
            mask_3ch = mask
        
        # Normalize mask to 0-1 range
        mask_norm = mask_3ch.astype(np.float32) / 255.0
        
        # Blend: original image where mask=0, warped tiles where mask=1
        # Also blend lighting from original for realism
        result = (
            warped_tiles * mask_norm * 0.95 +  # 95% tiles
            original * mask_norm * 0.05 +       # 5% original lighting
            original * (1 - mask_norm)          # Keep non-floor areas
        ).astype(np.uint8)
        
        return result

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
        Complete pipeline: perspective-corrected tile application
        
        Args:
            original_image: Original room photo
            floor_mask: Binary mask of floor area
            tile_image: Single tile texture
            tile_size_feet: Real-world tile dimensions (width, height) in feet
            pixels_per_foot: Scale factor for tile size
        
        Returns: Final visualization
        """
        try:
            # Step 0: Improve mask quality with edge awareness
            floor_mask = self._improve_mask(floor_mask, original_image)
            
            # Step 1: Find floor corners
            corners = self.find_floor_corners(floor_mask)
            
            # Step 2: Calculate perspective transform
            transform, rect_dims = self.calculate_homography(corners)
            
            # Step 3: Calculate tile size in pixels
            tile_size_px = int(max(tile_size_feet) * pixels_per_foot)
            
            # Step 4: Create tile pattern in rectangular space
            tile_pattern = self.create_tile_pattern(
                tile_image,
                rect_dims,
                tile_size_px
            )
            
            # Step 5: Apply tiles with perspective correction
            result = self.apply_tiles(
                original_image,
                floor_mask,
                tile_pattern,
                transform
            )
            
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
    
    # Keep backward compatibility methods
    def _load_image(self, image_bytes: bytes, grayscale: bool = False) -> np.ndarray:
        """
        Load image from bytes
        
        Args:
            image_bytes: Raw image data
            grayscale: Whether to load as grayscale
            
        Returns:
            np.ndarray: Image array
        """
        image = Image.open(BytesIO(image_bytes))
        
        if grayscale:
            image = image.convert('L')
            return np.array(image)
        else:
            image = image.convert('RGB')
            return cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
