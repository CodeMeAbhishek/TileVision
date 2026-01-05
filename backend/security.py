"""
Security utilities for TileVision API
Implements rate limiting, input validation, and security best practices
Following OWASP guidelines for API security
"""

from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from pydantic import BaseModel, Field, validator, ValidationError
from typing import Optional, List
import re
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

# ============================================================================
# Rate Limiting Configuration
# ============================================================================

# Initialize rate limiter
# Uses in-memory storage by default (for production, consider Redis)
limiter = Limiter(key_func=get_remote_address)

# Rate limit configurations (requests per time window)
# Following OWASP recommendations for API rate limiting
RATE_LIMIT_CONFIG = {
    # Public endpoints - stricter limits
    "strict": "10/minute",      # 10 requests per minute per IP
    "moderate": "30/minute",    # 30 requests per minute per IP
    "lenient": "100/hour",      # 100 requests per hour per IP
    
    # User-authenticated endpoints - higher limits
    "user_strict": "20/minute",    # 20 requests per minute per user
    "user_moderate": "60/minute",  # 60 requests per minute per user
    "user_lenient": "200/hour",    # 200 requests per hour per user
    
    # Health check - very lenient (for monitoring)
    "health": "1000/hour",
}

def get_user_identifier(request: Request) -> str:
    """
    Get user identifier for rate limiting
    Falls back to IP address if user is not authenticated
    
    Args:
        request: FastAPI request object
        
    Returns:
        User ID if authenticated, otherwise IP address
    """
    # Try to get user ID from request state (set by auth middleware)
    user_id = getattr(request.state, "user_id", None)
    if user_id:
        return f"user:{user_id}"
    
    # Fall back to IP address
    return get_remote_address(request)

# Custom rate limit key function that supports both IP and user-based limiting
def rate_limit_key_func(request: Request) -> str:
    """
    Custom key function for rate limiting
    Uses user ID if available, otherwise IP address
    """
    return get_user_identifier(request)

# ============================================================================
# Input Validation Schemas
# ============================================================================

class CoordinateInput(BaseModel):
    """Validates coordinate inputs for floor segmentation"""
    point_x: int = Field(..., ge=0, le=100000, description="X coordinate (0-100000)")
    point_y: int = Field(..., ge=0, le=100000, description="Y coordinate (0-100000)")
    
    @validator('point_x', 'point_y')
    def validate_coordinate(cls, v):
        """Ensure coordinates are reasonable"""
        if v < 0 or v > 100000:
            raise ValueError('Coordinate must be between 0 and 100000')
        return v
    
    class Config:
        # Reject extra fields
        extra = "forbid"


class TileSizeInput(BaseModel):
    """Validates tile size input"""
    tile_size: str = Field(..., min_length=1, max_length=20, description="Tile size (e.g., '2x2')")
    
    @validator('tile_size')
    def validate_tile_size_format(cls, v):
        """Validate tile size format (e.g., '2x2', '3x3')"""
        pattern = r'^\d+(\.\d+)?x\d+(\.\d+)?$'
        if not re.match(pattern, v.lower()):
            raise ValueError('Tile size must be in format "WxH" (e.g., "2x2", "3.5x3.5")')
        return v.lower()
    
    class Config:
        extra = "forbid"


class AIEnhancementInput(BaseModel):
    """Validates AI enhancement parameters"""
    use_ai_enhancement: bool = Field(default=False, description="Enable AI enhancement")
    ai_strength: float = Field(default=0.3, ge=0.0, le=1.0, description="AI strength (0.0-1.0)")
    ai_blend: float = Field(default=0.5, ge=0.0, le=1.0, description="Blend ratio (0.0-1.0)")
    
    class Config:
        extra = "forbid"


class MaterialReplacementPromptInput(BaseModel):
    """Validates material replacement prompt input"""
    prompt: Optional[str] = Field(None, max_length=1000, description="Custom prompt for material replacement")
    
    @validator('prompt')
    def validate_prompt_content(cls, v):
        """Sanitize and validate prompt content"""
        if v is None:
            return v
        
        # Remove potentially dangerous characters
        # Allow alphanumeric, spaces, common punctuation, and newlines
        sanitized = re.sub(r'[^\w\s\.,!?;:\-\n]', '', v)
        
        # Check for suspicious patterns (basic XSS prevention)
        dangerous_patterns = [
            r'<script',
            r'javascript:',
            r'onerror=',
            r'onload=',
        ]
        for pattern in dangerous_patterns:
            if re.search(pattern, sanitized, re.IGNORECASE):
                raise ValueError('Prompt contains potentially unsafe content')
        
        return sanitized.strip() if sanitized.strip() else None
    
    class Config:
        extra = "forbid"


# ============================================================================
# File Validation
# ============================================================================

ALLOWED_IMAGE_TYPES = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp'
}

ALLOWED_IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB default (can be overridden via env)

def validate_image_file(content_type: Optional[str], filename: Optional[str] = None) -> bool:
    """
    Validate image file type
    
    Args:
        content_type: MIME type of the file
        filename: Optional filename for extension check
        
    Returns:
        True if valid, raises HTTPException if invalid
    """
    if not content_type:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing content type"
        )
    
    # Check MIME type
    if content_type.lower() not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed types: {', '.join(ALLOWED_IMAGE_TYPES)}"
        )
    
    # Additional check: verify extension matches content type
    if filename:
        ext = filename.lower()
        if not any(ext.endswith(allowed_ext) for allowed_ext in ALLOWED_IMAGE_EXTENSIONS):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File extension does not match content type"
            )
    
    return True


def sanitize_filename(filename: str) -> str:
    """
    Sanitize filename to prevent path traversal and other attacks
    
    Args:
        filename: Original filename
        
    Returns:
        Sanitized filename
    """
    # Remove path components
    filename = filename.replace('..', '').replace('/', '').replace('\\', '')
    
    # Remove dangerous characters
    filename = re.sub(r'[^\w\-_\.]', '', filename)
    
    # Limit length
    if len(filename) > 255:
        filename = filename[:255]
    
    return filename


# ============================================================================
# Security Headers Middleware
# ============================================================================

async def add_security_headers(request: Request, call_next):
    """
    Add security headers to all responses
    Following OWASP security headers recommendations
    """
    response = await call_next(request)
    
    # Security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    
    # Only add Strict-Transport-Security if using HTTPS
    if request.url.scheme == "https":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    return response


# ============================================================================
# Rate Limit Error Handler
# ============================================================================

def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """
    Custom handler for rate limit exceeded errors
    Returns graceful 429 response with retry information
    """
    retry_after = int(exc.retry_after) if exc.retry_after else 60
    
    return JSONResponse(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        content={
            "error": "Rate limit exceeded",
            "message": "Too many requests. Please try again later.",
            "retry_after": retry_after,
            "retry_after_seconds": retry_after
        },
        headers={
            "Retry-After": str(retry_after),
            "X-RateLimit-Limit": str(exc.detail) if hasattr(exc, 'detail') else "unknown",
            "X-RateLimit-Remaining": "0"
        }
    )


# ============================================================================
# Input Sanitization Utilities
# ============================================================================

def sanitize_string(value: str, max_length: int = 1000) -> str:
    """
    Sanitize string input to prevent injection attacks
    
    Args:
        value: Input string
        max_length: Maximum allowed length
        
    Returns:
        Sanitized string
    """
    if not isinstance(value, str):
        raise ValueError("Input must be a string")
    
    # Remove null bytes
    value = value.replace('\x00', '')
    
    # Trim whitespace
    value = value.strip()
    
    # Enforce length limit
    if len(value) > max_length:
        value = value[:max_length]
    
    return value


def validate_numeric_range(value: float, min_val: float, max_val: float, field_name: str) -> float:
    """
    Validate numeric value is within range
    
    Args:
        value: Numeric value to validate
        min_val: Minimum allowed value
        max_val: Maximum allowed value
        field_name: Name of field for error messages
        
    Returns:
        Validated value
        
    Raises:
        HTTPException if value is out of range
    """
    if not isinstance(value, (int, float)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{field_name} must be a number"
        )
    
    if value < min_val or value > max_val:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{field_name} must be between {min_val} and {max_val}"
        )
    
    return float(value)

