# Backend Testing & Running Guide

This guide covers how to test and run the TileVision backend.

## 🚀 Quick Start

### Windows
```bash
cd backend
run.bat
```

### Linux/Mac/Git Bash
```bash
cd backend
chmod +x run.sh
./run.sh
```

The script will:
1. Create a virtual environment (if needed)
2. Activate the virtual environment
3. Install all dependencies from requirements.txt
4. Create .env file from .env.example (if needed)
5. Start the development server with auto-reload

Server will be available at:
- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🧪 Running Tests

### Run all tests
```bash
cd backend
pytest test_main.py -v
```

### Run specific test class
```bash
pytest test_main.py::TestHealthEndpoint -v
```

### Run with coverage
```bash
pip install pytest-cov
pytest test_main.py --cov=main --cov-report=html
```

## 📋 Test Coverage

The test suite includes:

✅ **Health Endpoint Tests**
- Returns 200 status
- Contains expected fields
- Reports healthy status
- Service statuses

✅ **CORS Middleware Tests**
- Allows origins
- Allows credentials
- Proper headers

✅ **Tiles Endpoint Tests**
- Returns 200 status
- Returns list of tiles
- Tiles have expected fields
- Valid data types

✅ **Server Startup Tests**
- App creation
- Configuration

✅ **Error Handling Tests**
- 404 for invalid endpoints
- 405 for wrong methods

## 🔍 Manual API Testing

### Test Health Endpoint
```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "timestamp": "2025-12-30T09:07:17.123456",
  "services": {
    "segmentation": false,
    "perspective": true
  }
}
```

### Test Tiles Endpoint
```bash
curl http://localhost:8000/api/tiles
```

### Test CORS
```bash
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     http://localhost:8000/health -v
```

Look for headers:
- `access-control-allow-origin: *`
- `access-control-allow-credentials: true`

## 🐛 Troubleshooting

### Port already in use
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### Module not found errors
```bash
# Ensure virtual environment is activated
# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

### REPLICATE_API_TOKEN not set
The server will start but segmentation will not work. This is expected for testing. Update `.env` file with your token when ready.

## 📊 Expected Test Results

All tests should pass:
```
test_main.py::TestHealthEndpoint::test_health_endpoint_returns_200 PASSED
test_main.py::TestHealthEndpoint::test_health_endpoint_returns_expected_fields PASSED
test_main.py::TestHealthEndpoint::test_health_endpoint_status_is_healthy PASSED
test_main.py::TestHealthEndpoint::test_health_endpoint_services_status PASSED
test_main.py::TestCORSMiddleware::test_cors_allows_origin PASSED
test_main.py::TestCORSMiddleware::test_cors_allows_credentials PASSED
test_main.py::TestTilesEndpoint::test_tiles_endpoint_returns_200 PASSED
test_main.py::TestTilesEndpoint::test_tiles_endpoint_returns_list PASSED
test_main.py::TestTilesEndpoint::test_tiles_have_expected_fields PASSED
test_main.py::TestTilesEndpoint::test_tiles_have_valid_data_types PASSED
test_main.py::TestServerStartup::test_app_is_created PASSED
test_main.py::TestServerStartup::test_app_has_description PASSED
test_main.py::TestErrorHandling::test_404_for_invalid_endpoint PASSED
test_main.py::TestErrorHandling::test_405_for_wrong_method PASSED
```

Total: **14 tests** should pass ✅
