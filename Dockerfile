# ============================================================
# OpenClaw - Multi-stage Docker Build
# ============================================================

# --- Stage 1: Builder ---
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip wheel && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


# --- Stage 2: Production Image ---
FROM python:3.12-slim AS production

# Labels
LABEL maintainer="OpenClaw Team"
LABEL org.opencontainers.image.title="OpenClaw"
LABEL org.opencontainers.image.description="Legal Research Platform - Azure Hosted"
LABEL org.opencontainers.image.version="1.0.0"

# Runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r openclaw && useradd -r -g openclaw -d /app openclaw

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY app/ .

# Set ownership
RUN chown -R openclaw:openclaw /app

# Switch to non-root user
USER openclaw

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/api/health || exit 1

# Expose port
EXPOSE 8000

# Environment defaults
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    WORKERS=4 \
    ENVIRONMENT=production

# Entrypoint
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers ${WORKERS} --no-access-log"]
