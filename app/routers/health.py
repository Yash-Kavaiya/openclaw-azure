"""Health check endpoints for OpenClaw."""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from datetime import datetime
import os

from database import get_db
from config import settings

router = APIRouter()


@router.get("/health", summary="Basic health check")
async def health_check():
    return {
        "status": "healthy",
        "application": "OpenClaw",
        "version": "1.0.0",
        "environment": settings.ENVIRONMENT,
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/health/detailed", summary="Detailed health check with dependency status")
async def detailed_health_check(db: AsyncSession = Depends(get_db)):
    checks = {
        "application": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "environment": settings.ENVIRONMENT,
    }

    # Database check
    try:
        await db.execute(text("SELECT 1"))
        checks["database"] = "healthy"
    except Exception as e:
        checks["database"] = f"unhealthy: {str(e)}"

    # Redis check (optional)
    if settings.REDIS_URL:
        try:
            import redis.asyncio as aioredis
            r = aioredis.from_url(settings.REDIS_URL)
            await r.ping()
            await r.close()
            checks["redis"] = "healthy"
        except Exception as e:
            checks["redis"] = f"unhealthy: {str(e)}"
    else:
        checks["redis"] = "not configured"

    overall = "healthy" if all(
        v in ("healthy", "not configured")
        for k, v in checks.items()
        if k not in ["timestamp", "environment"]
    ) else "degraded"
    checks["overall"] = overall

    return checks


@router.get("/ready", summary="Readiness probe")
async def readiness_probe(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception:
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail="Service not ready")


@router.get("/live", summary="Liveness probe")
async def liveness_probe():
    return {"status": "alive"}
