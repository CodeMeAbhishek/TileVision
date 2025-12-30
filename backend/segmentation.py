"""
Floor Segmentation Module using Segment Anything Model (SAM) via Replicate API
"""
import replicate
import numpy as np
import io
import base64
import time
from PIL import Image
import logging

logger = logging.getLogger(__name__)


class FloorSegmenter:
    """
    Floor segmentation using Segment Anything Model (SAM)
    """
    
    def __init__(self, api_token: str):
        """
        Initialize the floor segmenter with Replicate API token
        
        Args:
            api_token: Replicate API authentication token
        """
        if not api_token or api_token == "your_token_here":
            raise ValueError("Valid Replicate API token required")
        
        self.api_token = api_token
        self.client = replicate.Client(api_token=api_token)
        logger.info("FloorSegmenter initialized with Replicate SAM API")
    
    def segment_floor(self, image_bytes: bytes, point_x: int, point_y: int) -> tuple:
        """
        Segment floor area from image using Replicate's SAM API
        
        Uses the Segment Anything Model to identify and segment
        the floor region based on a user-provided point coordinate.
        
        Args:
            image_bytes: Raw image data as bytes
            point_x: X coordinate of point on the floor
            point_y: Y coordinate of point on the floor
            
        Returns:
            tuple: (mask_array, confidence_score)
                - mask_array: numpy array (H, W) with binary mask (0-255)
                - confidence_score: float between 0 and 1
        """
        logger.info(f"Segmenting floor at point ({point_x}, {point_y})")
        
        # Try real SAM API with retry logic
        max_retries = 2
        for attempt in range(max_retries + 1):
            try:
                # Convert bytes to PIL Image
                image = Image.open(io.BytesIO(image_bytes))
                original_width, original_height = image.size
                
                # Validate point coordinates
                if not (0 <= point_x < original_width and 0 <= point_y < original_height):
                    raise ValueError(f"Point ({point_x}, {point_y}) out of bounds ({original_width}x{original_height})")
                
                # Resize if too large (SAM works best with smaller images)
                max_size = 1024
                scale_factor = 1.0
                if max(image.size) > max_size:
                    scale_factor = max_size / max(image.size)
                    new_size = (int(image.size[0] * scale_factor), int(image.size[1] * scale_factor))
                    image = image.resize(new_size, Image.Resampling.LANCZOS)
                    # Scale point coordinates
                    scaled_x = int(point_x * scale_factor)
                    scaled_y = int(point_y * scale_factor)
                    logger.info(f"Resized image from {original_width}x{original_height} to {new_size}, scaled point to ({scaled_x}, {scaled_y})")
                else:
                    scaled_x, scaled_y = point_x, point_y
                
                # Convert to base64 for Replicate
                buffered = io.BytesIO()
                image.save(buffered, format="PNG")
                img_base64 = base64.b64encode(buffered.getvalue()).decode()
                img_data_uri = f"data:image/png;base64,{img_base64}"
                
                # Call Replicate SAM API - use specific version for stability
                # Meta SAM 2
                output = self.client.run(
                    "meta/sam-2:fe97b453a6455861e3bac769b441ca1f1086110da7466dbb65cf1eecfd60dc83",
                    input={
                        "image": img_data_uri,
                        "point_coords": str([[scaled_x, scaled_y]]),
                        "point_labels": str([1]),
                        "multimask_output": False,
                    }
                )
                
                logger.info(f"Replicate RAW Output Type: {type(output)}")
                logger.debug(f"Replicate RAW Output: {output}")

                # Parse output - Handle various formats
                mask_url = None
                use_individual_selection = False
                
                if isinstance(output, str):
                    mask_url = output
                elif isinstance(output, list) and len(output) > 0:
                     # Check if it's a list of strings (simple URLs)
                    if isinstance(output[0], str):
                         # If multiple masks, we need to find the best one
                         use_individual_selection = True
                         possible_masks = output
                    elif isinstance(output[0], dict) and 'mask' in output[0]:
                         mask_url = output[0]['mask']
                elif isinstance(output, dict):
                    # Check for specific SAM-2 keys
                    if 'individual_masks' in output and isinstance(output['individual_masks'], list) and len(output['individual_masks']) > 0:
                        # Prefer individual selection to avoid "whole image" combined masks
                        use_individual_selection = True
                        possible_masks = output['individual_masks']
                    elif 'combined_mask' in output and output['combined_mask']:
                        mask_url = output['combined_mask']
                    # Direct dictionary check (legacy/other models)
                    elif 'mask' in output:
                        mask_url = output['mask']
                    elif 'output' in output:
                         mask_url = output['output']
                
                if not mask_url and not use_individual_selection:
                     raise ValueError(f"Could not find mask in output: {output}")

                import requests
                
                if use_individual_selection:
                    # Download all masks and find the one that actually covers our point
                    # This prevents "whole image" errors
                    logger.info(f"Selecting best mask from {len(possible_masks)} candidates...")
                    mask_image = None
                    
                    # Check up to 10 masks to find the one containing our point
                    for idx, m_url in enumerate(possible_masks[:10]):
                        try:
                            resp = requests.get(m_url, timeout=3)
                            if resp.status_code != 200: 
                                continue
                            
                            m_img = Image.open(io.BytesIO(resp.content)).convert('L')
                            m_arr = np.array(m_img)
                            
                            # Log first mask dimensions to understand what we're getting
                            if idx == 0:
                                logger.info(f"Mask dimensions: {m_arr.shape}, Expected scaled: ({new_size[1] if scale_factor != 1.0 else original_height}, {new_size[0] if scale_factor != 1.0 else original_width})")
                            
                            # The masks should already be at the scaled resolution (same as input)
                            # So we check the point at scaled coordinates
                            py, px = int(scaled_y), int(scaled_x)
                            
                            h, w = m_arr.shape
                            logger.debug(f"Mask {idx}: shape={m_arr.shape}, checking point ({px}, {py})")
                            
                            if 0 <= py < h and 0 <= px < w:
                                # Check a small region around the point for robustness
                                window_size = 5
                                y_start = max(0, py - window_size)
                                y_end = min(h, py + window_size + 1)
                                x_start = max(0, px - window_size)
                                x_end = min(w, px + window_size + 1)
                                
                                region = m_arr[y_start:y_end, x_start:x_end]
                                if np.any(region > 0):
                                    # This mask contains our point!
                                    mask_area = np.count_nonzero(m_arr)
                                    logger.info(f"✓ Mask {idx} contains the point! Area: {mask_area} pixels")
                                    mask_image = m_img
                                    mask_url = "found"
                                    break
                                else:
                                    logger.debug(f"  Mask {idx}: point region is empty")
                            else:
                                logger.warning(f"  Mask {idx}: point ({px}, {py}) out of bounds {m_arr.shape}")
                        except Exception as e:
                            logger.warning(f"Failed to check mask {idx}: {e}")
                            continue
                    
                    if not mask_url:
                        # Fallback: just use combined mask or first individual
                        logger.warning("No individual mask contained the point, falling back to combined")
                        if isinstance(output, dict) and 'combined_mask' in output:
                             mask_url = output['combined_mask']
                        else:
                             mask_url = possible_masks[0]

                # Download if we haven't already loaded it
                if mask_url != "found":
                    logger.info(f"Downloading mask from URL: {mask_url}")
                    response = requests.get(mask_url)
                    response.raise_for_status()
                    mask_bytes = response.content
                    mask_image = Image.open(io.BytesIO(mask_bytes)).convert('L')
                
                # Resize mask back to original dimensions if needed
                if scale_factor != 1.0:
                    mask_image = mask_image.resize((original_width, original_height), Image.Resampling.NEAREST)
                
                mask = np.array(mask_image)
                
                # Calculate confidence (percentage of non-zero pixels)
                total_pixels = mask.size
                floor_pixels = np.count_nonzero(mask)
                confidence = floor_pixels / total_pixels if total_pixels > 0 else 0.0
                
                logger.info(f"SAM API success! Mask: {mask.shape}, Confidence: {confidence:.2f}")
                return mask, confidence
                
            except Exception as e:
                logger.error(f"SAM API attempt {attempt + 1} failed: {str(e)}")
                if attempt < max_retries:
                    time.sleep(2)  # Wait before retry
                    continue
                else:
                    # Final attempt failed - Propagate error to user
                    logger.error("All SAM API attempts failed.")
                    raise RuntimeError(f"Floor segmentation failed: {str(e)}")

    
    def segment_multiple_objects(self, image_bytes: bytes, points: list) -> list:
        """
        Segment multiple objects from image using multiple point prompts
        
        This can be used for advanced scenarios where multiple floor regions
        or objects need to be segmented separately.
        
        Args:
            image_bytes: Raw image data as bytes
            points: List of (x, y) coordinate tuples
            
        Returns:
            list: List of (mask_array, confidence_score) tuples for each point
        """
        results = []
        
        for point_x, point_y in points:
            mask, confidence = self.segment_floor(image_bytes, point_x, point_y)
            results.append((mask, confidence))
        
        return results
    
    def refine_mask(self, mask: np.ndarray, iterations: int = 2) -> np.ndarray:
        """
        Refine segmentation mask using morphological operations
        
        This helps clean up the mask by removing noise and filling holes.
        
        Args:
            mask: Input binary mask
            iterations: Number of morphological iterations
            
        Returns:
            np.ndarray: Refined binary mask
        """
        import cv2
        
        # TODO: Implement mask refinement using morphological operations
        # - Remove small noise with opening
        # - Fill holes with closing
        # - Smooth boundaries
        
        kernel = np.ones((5, 5), np.uint8)
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=iterations)
        
        return mask
