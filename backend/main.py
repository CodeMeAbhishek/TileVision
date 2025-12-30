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
replicate_token = os.getenv("REPLICATE_API_TOKEN")
floor_segmenter = FloorSegmenter(replicate_token) if replicate_token else None
perspective_corrector = PerspectiveCorrector()

# Sample tile catalog (in production, this would come from a database)
# Sample tile catalog (in production, this would come from a database)
TILE_CATALOG = [
    {
        "id": 1,
        "name": "Marble White",
        "image_url": "http://10.0.2.2:8000/static/tiles/tile_marble_white.png",
        "size": "2x2",
        "price": 1200.00
    },
    {
        "id": 2,
        "name": "Wooden Oak",
        "image_url": "https://images.unsplash.com/photo-1610260408542-a6f959c9ee2b?q=80&w=400&h=400&fit=crop",
        "size": "1x3",
        "price": 890.00
    },
    {
        "id": 3,
        "name": "Ceramic Beige",
        "image_url": "https://images.unsplash.com/photo-1615971677499-5467eab533b8?q=80&w=400&h=400&fit=crop",
        "size": "2x2",
        "price": 750.00
    },
    {
        "id": 4,
        "name": "Granite Dark",
        "image_url": "https://images.unsplash.com/photo-1618215570228-a6d888047f38?q=80&w=400&h=400&fit=crop",
        "size": "3x3",
        "price": 1500.00
    },
    {
        "id": 5,
        "name": "Terracotta",
        "image_url": "https://images.unsplash.com/photo-1596253406214-38c7f96b9a89?q=80&w=400&h=400&fit=crop",
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
    tile_size: str = Form(...)
):
    """Apply tile pattern to floor with perspective correction"""
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
        
        # Process with perspective correction using new pipeline
        result_img = perspective_corrector.process_complete(
            original_img,
            mask_img,
            tile_img,
            tile_size_feet=tile_size_feet,
            pixels_per_foot=50
        )
        
        # Encode result as JPEG
        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
        _, result_encoded = cv2.imencode('.jpg', result_img, encode_param)
        result_base64 = base64.b64encode(result_encoded).decode('utf-8')
        
        processing_time = time.time() - start_time
        
        logger.info(f"Applied tile in {processing_time:.2f}s")
        
        return {
            "result_image": result_base64,
            "processing_time": processing_time
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error applying tile: {e}", exc_info=True)
        raise HTTPException(500, f"Failed to apply tile: {str(e)}")


@app.get("/api/tiles")
async def get_tiles():
    """
    Get available tile catalog
    
    Returns:
        list: List of available tiles with details
    """
    logger.info("Fetching tile catalog")
    return TILE_CATALOG


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
