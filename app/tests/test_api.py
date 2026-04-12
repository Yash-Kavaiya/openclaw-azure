"""
OpenClaw - Basic Tests
"""
import pytest
from httpx import AsyncClient, ASGITransport
import sys
import os

# Add app directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@pytest.mark.asyncio
async def test_root_endpoint():
    """Test the root endpoint returns application info."""
    from main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["application"] == "OpenClaw"
        assert "version" in data


@pytest.mark.asyncio
async def test_health_endpoint():
    """Test the health endpoint returns OK."""
    from main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/health")
        assert response.status_code == 200
