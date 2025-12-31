from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import base64
import logging
import time
from datetime import datetime
from typing import Optional
import os
from dotenv import load_dotenv

from segmentation import FloorSegmenter
from perspective import PerspectiveCorrector
from ai_inpainting import AIInpainter
from ai_realistic_render import RealisticTileRenderer
from ai_material_replacer import AiMaterialReplacer

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="TileVision API",
    description="Backend API for floor segmentation and tile visualization",
    version="0.1.0"
)

# Enable CORS for all origins (development mode)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Configuration
MAX_FILE_SIZE = int(os.getenv("MAX_IMAGE_SIZE", 1024)) * 1024 * 10  # 10MB default
DEBUG = os.getenv("DEBUG", "true").lower() == "true"

# Initialize services
# Initialize AI Inpainter if token available
try:
    replicate_token = os.getenv("REPLICATE_API_TOKEN")
    if replicate_token:
        ai_inpainter = AIInpainter()
        logger.info("AI Inpainter initialized successfully")
        
        # Initialize ControlNet renderer
        controlnet_renderer = RealisticTileRenderer(replicate_token)
        logger.info("ControlNet Renderer initialized successfully")
        
        # Initialize Material Replacer
        material_replacer = AiMaterialReplacer(replicate_token)
        logger.info("AI Material Replacer initialized successfully")
    else:
        ai_inpainter = None
        controlnet_renderer = None
        logger.warning("REPLICATE_API_TOKEN not found - AI features disabled")
except Exception as e:
    logger.error(f"Failed to initialize AI services: {e}")
    ai_inpainter = None
    controlnet_renderer = None
floor_segmenter = FloorSegmenter(replicate_token) if replicate_token else None
perspective_corrector = PerspectiveCorrector()

# Sample tile catalog - Now with AI-generated seamless textures!
TILE_CATALOG = [
    {
        "id": 1,
        "name": "Carrara Marble White",
        "image_url": "http://10.0.2.2:8000/static/tiles/marble_white_seamless.jpg",
        "size": "2x2",
        "price": 1200.00
    },
    {
        "id": 2,
        "name": "Oak Wood Natural",
        "image_url": "http://10.0.2.2:8000/static/tiles/wooden_oak_seamless.jpg",
        "size": "1x3",
        "price": 890.00
    },
    {
        "id": 3,
        "name": "Ceramic Beige Classic",
        "image_url": "http://10.0.2.2:8000/static/tiles/ceramic_beige_seamless.jpg",
        "size": "2x2",
        "price": 750.00
    },
    {
        "id": 4,
        "name": "Granite Dark Luxury",
        "image_url": "http://10.0.2.2:8000/static/tiles/granite_dark_seamless.jpg",
        "size": "3x3",
        "price": 1500.00
    },
    {
        "id": 5,
        "name": "Terracotta Rustic",
        "image_url": "http://10.0.2.2:8000/static/tiles/terracotta_seamless.jpg",
        "size": "2x2",
        "price": 650.00
    },
]


@app.middleware("http")
async def log_requests(request, call_next):
    """Log all incoming requests with timestamps"""
    start_time = time.time()
    timestamp = datetime.now().isoformat()
    
    logger.info(f"[{timestamp}] {request.method} {request.url.path}")
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    logger.info(f"[{timestamp}] Completed in {process_time:.2f}s - Status: {response.status_code}")
    
    return response


async def validate_file_size(file: UploadFile):
    """Validate uploaded file size"""
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum size is {MAX_FILE_SIZE / (1024 * 1024)}MB"
        )
    await file.seek(0)  # Reset file pointer
    return contents


@app.get("/health")
async def health_check():
    """
    Health check endpoint
    
    Returns:
        dict: Status and version information
    """
    return {
        "status": "healthy",
        "version": "0.1.0",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "segmentation": floor_segmenter is not None,
            "perspective": True
        }
    }


@app.post("/api/segment-floor")
async def segment_floor(
    file: UploadFile = File(...),
    point_x: int = Form(...),
    point_y: int = Form(...)
):
    """
    Segment floor from image using Segment Anything Model
    
    Args:
        file: Image file containing the room/floor
        point_x: X coordinate of point on floor
        point_y: Y coordinate of point on floor
        
    Returns:
        dict: Base64 encoded mask, confidence score, and processing time
    """
    start_time = time.time()
    
    try:
        # Validate file
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        image_bytes = await validate_file_size(file)
        
        logger.info(f"Processing floor segmentation at point ({point_x}, {point_y})")
        
        # Check if segmenter is available
        if not floor_segmenter:
            raise HTTPException(
                status_code=503,
                detail="Segmentation service not available. Please configure REPLICATE_API_TOKEN"
            )
        
        # Perform segmentation
        mask, confidence = floor_segmenter.segment_floor(image_bytes, point_x, point_y)
        
        # Convert mask to base64 encoded PNG
        import cv2
        import numpy as np
        from io import BytesIO
        from PIL import Image
        
        # Convert mask to RGBA image (White + Transparent)
        height, width = mask.shape
        rgba_mask = np.zeros((height, width, 4), dtype=np.uint8)
        
        # Set floor pixels to White (255, 255, 255, 255)
        # Background pixels remain (0, 0, 0, 0) - Transparent
        rgba_mask[mask > 0] = [255, 255, 255, 255]
        
        mask_image = Image.fromarray(rgba_mask, 'RGBA')
        buffered = BytesIO()
        mask_image.save(buffered, format="PNG")
        mask_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
        
        processing_time = time.time() - start_time
        
        return {
            "mask": mask_base64,
            "confidence": float(confidence),
            "processing_time": processing_time
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in floor segmentation: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Segmentation failed: {str(e)}")


@app.post("/api/apply-tile")
async def apply_tile(
    original_image: UploadFile = File(...),
    floor_mask: UploadFile = File(...),
    tile_image: UploadFile = File(...),
    tile_size: str = Form("2x2"),
    use_ai_enhancement: bool = Form(False),  # NEW: Enable ControlNet
    ai_strength: float = Form(0.3),          # NEW: AI modification strength (0.2-0.4)
    ai_blend: float = Form(0.5)              # NEW: Blend ratio (0.5 = 50/50)
):
    """
    Apply tile pattern to floor with optional AI enhancement
    
    Parameters:
    - use_ai_enhancement: Enable ControlNet realistic lighting (default: False)
    - ai_strength: AI modification strength, lower = more preservation (default: 0.3)
    - ai_blend: Blend ratio - 0.0=only direct, 1.0=only AI (default: 0.5)
    """
    start_time = time.time()
    
    try:
        # Validate file types
        if not original_image.content_type.startswith('image/'):
            raise HTTPException(400, "Original must be an image")
        if not tile_image.content_type.startswith('image/'):
            raise HTTPException(400, "Tile must be an image")
        
        # Read images
        original_bytes = await validate_file_size(original_image)
        mask_bytes = await validate_file_size(floor_mask)
        tile_bytes = await validate_file_size(tile_image)
        
        # Convert to numpy arrays
        import cv2
        import numpy as np
        from io import BytesIO
        from PIL import Image
        
        original_np = np.frombuffer(original_bytes, np.uint8)
        original_img = cv2.imdecode(original_np, cv2.IMREAD_COLOR)
        
        mask_np = np.frombuffer(mask_bytes, np.uint8)
        mask_img = cv2.imdecode(mask_np, cv2.IMREAD_GRAYSCALE)
        
        tile_np = np.frombuffer(tile_bytes, np.uint8)
        tile_img = cv2.imdecode(tile_np, cv2.IMREAD_COLOR)
        
        if original_img is None or mask_img is None or tile_img is None:
            raise HTTPException(400, "Failed to decode images")
        
        # Parse tile size (e.g., "2x2" -> (2.0, 2.0) feet)
        try:
            width, height = tile_size.lower().split('x')
            tile_size_feet = (float(width), float(height))
        except:
            tile_size_feet = (2.0, 2.0)  # Default
        
        logger.info(f"Applying tile pattern with size: {tile_size} ({tile_size_feet} feet)")
        
        # STEP 1: Create direct tile overlay (always)
        logger.info("Creating direct tile overlay...")
        direct_overlay = perspective_corrector.process_complete(
            original_img,
            mask_img,
            tile_img,
            tile_size_feet=tile_size_feet,
            pixels_per_foot=50
        )
        
        direct_time = time.time() - start_time
        logger.info(f"✅ Direct overlay complete: {direct_time:.2f}s")
        
        # STEP 2: AI enhancement (optional)
        if use_ai_enhancement:
            logger.info(f"Applying AI enhancement (strength={ai_strength}, blend={ai_blend})...")
            
            try:
                if not controlnet_renderer:
                    raise ValueError("ControlNet not available - check REPLICATE_API_TOKEN")
                
                # Use hybrid approach for safety
                result_img = controlnet_renderer.hybrid_render(
                    direct_overlay,
                    original_room=original_img,
                    strength=ai_strength,
                    blend_ratio=ai_blend
                )
                
                ai_time = time.time() - start_time - direct_time
                logger.info(f"✅ AI enhancement complete: {ai_time:.2f}s")
                
            except Exception as e:
                logger.error(f"⚠️ AI enhancement failed: {e}")
                logger.info("Using direct overlay (safe fallback)")
                result_img = direct_overlay
        else:
            logger.info("Skipping AI enhancement (use_ai_enhancement=False)")
            result_img = direct_overlay
        
        # Encode result as JPEG
        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 92]
        _, result_encoded = cv2.imencode('.jpg', result_img, encode_param)
        result_base64 = base64.b64encode(result_encoded).decode('utf-8')
        
        total_time = time.time() - start_time
        
        logger.info(f"✅ Total processing time: {total_time:.2f}s")
        
        return {
            "result_image": result_base64,
            "processing_time": total_time,
            "used_ai_enhancement": use_ai_enhancement and result_img is not direct_overlay
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error applying tile: {e}", exc_info=True)
        raise HTTPException(500, f"Failed to apply tile: {str(e)}")


@app.post("/api/apply-tile-controlnet")
async def apply_tile_controlnet(
    original_image: UploadFile = File(..., description="Original room image"),
    floor_mask: UploadFile = File(..., description="Floor mask (grayscale PNG)"),
    tile_image: UploadFile = File(..., description="Tile texture image"),
    tile_size: str = Form(..., description="Tile size (e.g., '2x2')")
):
    """
    Apply tile with ControlNet AI enhancement
    
    Pipeline:
    1. Create exact tile overlay (direct)
    2. Enhance with ControlNet (realistic lighting)
    3. Validate pattern preserved
    4. Blend or fallback to direct
    """
    start_time = time.time()
    
    try:
        if not controlnet_renderer:
            raise HTTPException(503, "ControlNet renderer not available - check REPLICATE_API_TOKEN")
        
        # Validate file types
        if not original_image.content_type.startswith('image/'):
            raise HTTPException(400, "Original must be an image")
        if not tile_image.content_type.startswith('image/'):
            raise HTTPException(400, "Tile must be an image")
        
        # Read images
        originalBytes = await validate_file_size(original_image)
        mask_bytes = await validate_file_size(floor_mask)
        tile_bytes = await validate_file_size(tile_image)
        
        # Convert to numpy arrays
        import cv2
        import numpy as np
        from io import BytesIO
        from PIL import Image
        
        original_img = np.array(Image.open(BytesIO(original_bytes)))
        original_img = cv2.cvtColor(original_img, cv2.COLOR_RGB2BGR)
        
        mask_img = np.array(Image.open(BytesIO(mask_bytes)))
        if len(mask_img.shape) == 3:
            mask_img = cv2.cvtColor(mask_img, cv2.COLOR_RGB2GRAY)
        
        tile_img = np.array(Image.open(BytesIO(tile_bytes)))
        tile_img = cv2.cvtColor(tile_img, cv2.COLOR_RGB2BGR)
        
        logger.info(f"Images loaded: original={original_img.shape}, mask={mask_img.shape}, tile={tile_img.shape}")
        
        # Parse tile size
        try:
            width, height = tile_size.lower().split('x')
            tile_size_feet = (float(width), float(height))
        except:
            tile_size_feet = (2.0, 2.0)
        
        logger.info(f"Applying tile with ControlNet: {tile_size} ({tile_size_feet} feet)")
        
        # STEP 1: Create exact tile overlay (direct)
        logger.info("STEP 1: Creating exact tile overlay...")
        direct_overlay = perspective_corrector.process_complete(
            original_img,
            mask_img,
            tile_img,
            tile_size_feet=tile_size_feet,
            pixels_per_foot=50
        )
        logger.info(f"  Direct overlay complete: {direct_overlay.shape}")
        
        # STEP 2: Enhance with ControlNet
        logger.info("STEP 2: Enhancing with ControlNet...")
        result_img = controlnet_renderer.hybrid_render(
            direct_overlay,
            original_room=original_img,
            strength=0.3,        # Low strength to preserve pattern
            blend_ratio=0.5      # 50/50 blend with direct overlay
        )
        logger.info("  ControlNet enhancement complete")
        
        # Encode result as JPEG
        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
        _, result_encoded = cv2.imencode('.jpg', result_img, encode_param)
        result_base64 = base64.b64encode(result_encoded).decode('utf-8')
        
        processing_time = time.time() - start_time
        
        logger.info(f"✅ Applied tile with ControlNet in {processing_time:.2f}s")
        
        return {
            "result_image": result_base64,
            "processing_time": processing_time,
            "method": "controlnet-hybrid"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error applying tile with ControlNet: {e}", exc_info=True)
        raise HTTPException(500, f"Failed to apply tile: {str(e)}")



@app.post("/api/apply_tile_ai")
async def apply_tile_ai(
    original_image: UploadFile = File(..., description="Original room image"),
    floor_mask: UploadFile = File(..., description="Floor mask (grayscale PNG)"),
    tile_image: UploadFile = File(..., description="Tile texture image")
):
    """
    Apply tile using AI-powered image-guided inpainting
    
    This endpoint uses Stable Diffusion with IP-Adapter to apply tiles
    with photorealistic quality. Works with ANY tile image - catalog or user-uploaded.
    
    Cost: ~$0.02 per image
    Processing Time: ~10-15 seconds
    """
    start_time = time.time()
    
    try:
        # Check if AI is available
        if not ai_inpainter:
            logger.warning("AI inpainting not available, falling back to direct overlay")
            # Fallback to regular endpoint
            return await apply_tile(original_image, floor_mask, tile_image, "2x2")
        
        # Validate file types
        if not original_image.content_type.startswith('image/'):
            raise HTTPException(400, "Original must be an image")
        if not tile_image.content_type.startswith('image/'):
            raise HTTPException(400, "Tile must be an image")
        
        # Read images
        original_bytes = await validate_file_size(original_image)
        mask_bytes = await validate_file_size(floor_mask)
        tile_bytes = await validate_file_size(tile_image)
        
        # Convert to numpy arrays
        import cv2
        import numpy as np
        
        original_np = np.frombuffer(original_bytes, np.uint8)
        original_img = cv2.imdecode(original_np, cv2.IMREAD_COLOR)
        
        mask_np = np.frombuffer(mask_bytes, np.uint8)
        mask_img = cv2.imdecode(mask_np, cv2.IMREAD_GRAYSCALE)
        
        tile_np = np.frombuffer(tile_bytes, np.uint8)
        tile_img = cv2.imdecode(tile_np, cv2.IMREAD_COLOR)
        
        if original_img is None or mask_img is None or tile_img is None:
            raise HTTPException(400, "Failed to decode images")
        
        logger.info(f"Starting AI inpainting: original={original_img.shape}, "
                   f"mask={mask_img.shape}, tile={tile_img.shape}")
        
        # Apply AI inpainting with tile image as reference
        result_img = await ai_inpainter.inpaint_with_tile_reference(
            original_image=original_img,
            floor_mask=mask_img,
            tile_image=tile_img
        )
        
        # Encode result as JPEG
        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
        _, result_encoded = cv2.imencode('.jpg', result_img, encode_param)
        result_base64 = base64.b64encode(result_encoded).decode('utf-8')
        
        processing_time = time.time() - start_time
        
        logger.info(f"AI inpainting complete in {processing_time:.2f}s")
        
        return {
            "result_image": result_base64,
            "processing_time": processing_time,
            "method": "ai_inpainting"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"AI inpainting failed: {e}", exc_info=True)
        # Fallback to direct overlay
        logger.info("Falling back to direct overlay method")
        try:
            return await apply_tile(original_image, floor_mask, tile_image, "2x2")
        except:
            raise HTTPException(500, f"All tile application methods failed: {str(e)}")


@app.get("/api/tiles")
async def get_tiles():
    """
    Get available tile catalog
    
    Returns:
        list: List of available tiles with details
    """
    logger.info("Fetching tile catalog")
    return TILE_CATALOG


@app.post("/api/replace-material")
async def replace_material(
    image: UploadFile = File(...),
    mask: UploadFile = File(...),
    tile: UploadFile = File(...),
    prompt: Optional[str] = Form("high quality floor"),
):
    """
    Replace material in masked area using reference tile image (IP-Adapter)
    """
    if not os.getenv("REPLICATE_API_TOKEN"):
        raise HTTPException(status_code=500, detail="AI service not configured")

    try:
        # Read files
        image_bytes = await image.read()
        mask_bytes = await mask.read()
        tile_bytes = await tile.read()

        # Convert to base64
        image_b64 = base64.b64encode(image_bytes).decode('utf-8')
        mask_b64 = base64.b64encode(mask_bytes).decode('utf-8')
        tile_b64 = base64.b64encode(tile_bytes).decode('utf-8')
        
        start_time = time.time()
        logger.info(f"Processing material replacement...")

        result_url, metadata = material_replacer.replace_material(
            image_b64,
            mask_b64,
            tile_b64,
            prompt=prompt
        )

        elapsed = time.time() - start_time
        logger.info(f"✅ Material replacement {'complete' if result_url else 'failed'}: {elapsed:.2f}s")
        
        if not result_url:
             raise HTTPException(status_code=500, detail=metadata.get("error", "Unknown error"))
             
        # Result is already base64 from the updated material_replacer
        result_b64 = result_url

        return JSONResponse({
            "success": True,
            "result_image": result_b64, 
            "metadata": metadata
        })

    except Exception as e:
        logger.error(f"Error in replace_material: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8000))
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=DEBUG,
        log_level="info"
    )
