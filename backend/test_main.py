"""
Backend API Tests
Tests for FastAPI endpoints and middleware
"""
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


class TestHealthEndpoint:
    """Test cases for /health endpoint"""
    
    def test_health_endpoint_returns_200(self):
        """Test that health endpoint returns 200 status code"""
        response = client.get("/health")
        assert response.status_code == 200
    
    def test_health_endpoint_returns_expected_fields(self):
        """Test that health endpoint returns all expected fields"""
        response = client.get("/health")
        data = response.json()
        
        assert "status" in data
        assert "version" in data
        assert "timestamp" in data
        assert "services" in data
        
    def test_health_endpoint_status_is_healthy(self):
        """Test that health endpoint reports healthy status"""
        response = client.get("/health")
        data = response.json()
        
        assert data["status"] == "healthy"
        assert data["version"] == "0.1.0"
    
    def test_health_endpoint_services_status(self):
        """Test that health endpoint reports service statuses"""
        response = client.get("/health")
        data = response.json()
        
        assert "services" in data
        assert "segmentation" in data["services"]
        assert "perspective" in data["services"]
        assert data["services"]["perspective"] is True


class TestCORSMiddleware:
    """Test cases for CORS middleware"""
    
    def test_cors_allows_origin(self):
        """Test that CORS middleware allows origins"""
        response = client.options(
            "/health",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET",
            }
        )
        
        # Should have CORS headers
        assert "access-control-allow-origin" in response.headers
    
    def test_cors_allows_credentials(self):
        """Test that CORS allows credentials"""
        response = client.get(
            "/health",
            headers={"Origin": "http://localhost:3000"}
        )
        
        # Check CORS headers are present
        assert "access-control-allow-origin" in response.headers
        assert response.headers["access-control-allow-origin"] == "*"


class TestTilesEndpoint:
    """Test cases for /api/tiles endpoint"""
    
    def test_tiles_endpoint_returns_200(self):
        """Test that tiles endpoint returns 200 status code"""
        response = client.get("/api/tiles")
        assert response.status_code == 200
    
    def test_tiles_endpoint_returns_list(self):
        """Test that tiles endpoint returns a list"""
        response = client.get("/api/tiles")
        data = response.json()
        
        assert isinstance(data, list)
        assert len(data) > 0
    
    def test_tiles_have_expected_fields(self):
        """Test that each tile has expected fields"""
        response = client.get("/api/tiles")
        tiles = response.json()
        
        for tile in tiles:
            assert "id" in tile
            assert "name" in tile
            assert "image_url" in tile
            assert "size" in tile
            assert "price" in tile
    
    def test_tiles_have_valid_data_types(self):
        """Test that tile fields have correct data types"""
        response = client.get("/api/tiles")
        tiles = response.json()
        
        for tile in tiles:
            assert isinstance(tile["id"], int)
            assert isinstance(tile["name"], str)
            assert isinstance(tile["image_url"], str)
            assert isinstance(tile["size"], str)
            assert isinstance(tile["price"], (int, float))


class TestServerStartup:
    """Test cases for server startup and configuration"""
    
    def test_app_is_created(self):
        """Test that FastAPI app is created successfully"""
        assert app is not None
        assert app.title == "TileVision API"
        assert app.version == "0.1.0"
    
    def test_app_has_description(self):
        """Test that app has description"""
        assert app.description == "Backend API for floor segmentation and tile visualization"


class TestErrorHandling:
    """Test cases for error handling"""
    
    def test_404_for_invalid_endpoint(self):
        """Test that invalid endpoints return 404"""
        response = client.get("/api/invalid-endpoint")
        assert response.status_code == 404
    
    def test_405_for_wrong_method(self):
        """Test that wrong HTTP methods return 405"""
        response = client.post("/health")
        assert response.status_code == 405


# Run tests with pytest
if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
