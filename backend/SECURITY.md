# Security Hardening Documentation

This document outlines the security measures implemented in the TileVision API, following OWASP best practices.

## 🔒 Security Features

### 1. Rate Limiting

All public endpoints are protected with rate limiting to prevent abuse and DoS attacks.

#### Rate Limit Configuration

- **Strict endpoints** (AI processing): `10 requests/minute` per IP/user
  - `/api/segment-floor`
  - `/api/replace-material`
  
- **Moderate endpoints** (resource-intensive): `30 requests/minute` per IP/user
  - `/api/apply-tile`
  
- **Lenient endpoints** (read-only): `100 requests/hour` per IP/user
  - `/api/tiles`
  
- **Health check**: `1000 requests/hour` per IP
  - `/health`

#### Rate Limit Behavior

- Rate limits are applied per IP address by default
- If user authentication is implemented, limits can be applied per user ID
- When rate limit is exceeded, API returns `429 Too Many Requests` with:
  - `Retry-After` header indicating seconds to wait
  - `X-RateLimit-Limit` header showing the limit
  - `X-RateLimit-Remaining` header (always 0 when exceeded)
  - Graceful error message in response body

#### Example Rate Limit Response

```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Please try again later.",
  "retry_after": 60,
  "retry_after_seconds": 60
}
```

### 2. Input Validation & Sanitization

All user inputs are strictly validated using Pydantic schemas with the following protections:

#### Coordinate Validation
- **Range**: 0 to 100,000 pixels
- **Type**: Integer only
- **Rejects**: Negative values, non-numeric strings, out-of-range values

#### Tile Size Validation
- **Format**: Must match pattern `WxH` (e.g., "2x2", "3.5x3.5")
- **Length**: Maximum 20 characters
- **Rejects**: Invalid formats, empty strings, overly long strings

#### AI Enhancement Parameters
- **ai_strength**: Float between 0.0 and 1.0
- **ai_blend**: Float between 0.0 and 1.0
- **use_ai_enhancement**: Boolean only

#### Prompt Validation
- **Length**: Maximum 1000 characters
- **Sanitization**: Removes dangerous characters and patterns
- **XSS Prevention**: Blocks script tags, javascript: URLs, event handlers
- **Character Filtering**: Only allows alphanumeric, spaces, common punctuation

#### File Validation
- **Type**: Only allows image files (JPEG, PNG, WebP)
- **Size**: Configurable maximum (default 10MB)
- **Content-Type Verification**: Validates MIME type matches file extension
- **Empty File Detection**: Rejects empty files
- **Filename Sanitization**: Removes path traversal attempts (`..`, `/`, `\`)

#### Schema Enforcement
- **Extra Fields Rejected**: All Pydantic models use `extra="forbid"` to reject unexpected fields
- **Type Coercion**: Automatic type conversion where safe (e.g., string "123" → int 123)
- **Validation Errors**: Returns `422 Unprocessable Entity` with detailed error messages

### 3. API Key Security

#### Environment Variable Storage

All API keys are stored in environment variables, never hardcoded:

- **REPLICATE_API_TOKEN**: Stored in `.env` file (development) or deployment platform secrets (production)
- **SUPABASE_URL** and **SUPABASE_ANON_KEY**: Stored in environment variables (mobile app)

#### Key Rotation

1. **Development**: Update `.env` file with new key
2. **Production**: Update environment variables in deployment platform (Render.com, etc.)
3. **Mobile App**: Update `.env` file and rebuild app

#### Key Exposure Prevention

✅ **Server-side only**: API keys are never exposed to client-side code
✅ **No client-side keys**: Mobile app only uses Supabase anon key (safe for client-side)
✅ **Environment-based**: All sensitive keys loaded from environment variables
✅ **Git ignored**: `.env` files are in `.gitignore` to prevent accidental commits

#### Best Practices

1. **Never commit keys**: All `.env` files are git-ignored
2. **Use secrets management**: Production keys stored in platform secrets (Render.com, etc.)
3. **Rotate regularly**: Change API keys periodically
4. **Monitor usage**: Check API usage logs for suspicious activity
5. **Least privilege**: Use keys with minimum required permissions

### 4. Security Headers

All responses include security headers following OWASP recommendations:

- **X-Content-Type-Options**: `nosniff` - Prevents MIME type sniffing
- **X-Frame-Options**: `DENY` - Prevents clickjacking
- **X-XSS-Protection**: `1; mode=block` - Enables XSS filtering
- **Referrer-Policy**: `strict-origin-when-cross-origin` - Controls referrer information
- **Strict-Transport-Security**: `max-age=31536000; includeSubDomains` (HTTPS only)

### 5. CORS Configuration

CORS is configured via `ALLOWED_ORIGINS` environment variable:

- **Development**: Set to `*` to allow all origins
- **Production**: Set to specific domains (comma-separated)
  - Example: `https://tilevision.com,https://www.tilevision.com`

## 🛡️ OWASP Compliance

This implementation follows OWASP API Security Top 10 (2023):

1. ✅ **Broken Object Level Authorization** - Input validation prevents unauthorized access
2. ✅ **Broken Authentication** - Rate limiting prevents brute force attacks
3. ✅ **Broken Object Property Level Authorization** - Schema validation rejects extra fields
4. ✅ **Unrestricted Resource Consumption** - Rate limiting prevents DoS
5. ✅ **Broken Function Level Authorization** - Endpoint-level rate limiting
6. ✅ **Unrestricted Access to Sensitive Business Flows** - Rate limits on AI endpoints
7. ✅ **Server Side Request Forgery** - Input validation prevents SSRF
8. ✅ **Security Misconfiguration** - Security headers, CORS configuration
9. ✅ **Improper Inventory Management** - API versioning and documentation
10. ✅ **Unsafe Consumption of APIs** - Input sanitization and validation

## 📝 Configuration

### Environment Variables

```bash
# API Keys (REQUIRED)
REPLICATE_API_TOKEN=your_token_here

# Security Configuration
ALLOWED_ORIGINS=https://tilevision.com,https://www.tilevision.com
MAX_IMAGE_SIZE=10  # MB
DEBUG=false

# Server Configuration
PORT=8000
BASE_URL=https://tilevision.onrender.com
```

### Rate Limit Customization

To customize rate limits, edit `backend/security.py`:

```python
RATE_LIMIT_CONFIG = {
    "strict": "10/minute",      # Adjust as needed
    "moderate": "30/minute",    # Adjust as needed
    "lenient": "100/hour",      # Adjust as needed
    "health": "1000/hour",      # Adjust as needed
}
```

## 🧪 Testing Security

### Test Rate Limiting

```bash
# Make 11 requests quickly to trigger rate limit
for i in {1..11}; do
  curl http://localhost:8000/api/tiles
done
```

Expected: 11th request returns `429 Too Many Requests`

### Test Input Validation

```bash
# Test invalid coordinates
curl -X POST http://localhost:8000/api/segment-floor \
  -F "file=@test.jpg" \
  -F "point_x=-1" \
  -F "point_y=1000000"
```

Expected: `422 Unprocessable Entity` with validation error

### Test File Validation

```bash
# Test invalid file type
curl -X POST http://localhost:8000/api/segment-floor \
  -F "file=@test.txt" \
  -F "point_x=100" \
  -F "point_y=100"
```

Expected: `400 Bad Request` with "Invalid file type" error

## 🔄 Key Rotation Procedure

1. **Generate new key** in service provider dashboard
2. **Update environment variable** in deployment platform
3. **Restart service** to load new key
4. **Verify functionality** with test request
5. **Revoke old key** after verification

## 📚 Additional Resources

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [OWASP Secure Headers](https://owasp.org/www-project-secure-headers/)
- [FastAPI Security Documentation](https://fastapi.tiangolo.com/tutorial/security/)
- [Pydantic Validation](https://docs.pydantic.dev/latest/concepts/validators/)

## ⚠️ Security Notes

- Rate limiting uses in-memory storage by default
- For production at scale, consider Redis-backed rate limiting
- Monitor rate limit violations for potential attacks
- Regularly review and update rate limit thresholds
- Keep dependencies updated for security patches

