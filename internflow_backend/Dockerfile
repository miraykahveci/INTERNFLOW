# ============================================
# InternFlow Backend - Production Dockerfile
# ============================================
# Python 3.12 slim image - lightweight production base
FROM python:3.12-slim

# Working directory inside container
WORKDIR /app

# System dependencies (PDF processing)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr \
    tesseract-ocr-tur \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies - cache layer
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Application code
COPY . .

# Render dynamic PORT support
ENV PORT=8000
EXPOSE ${PORT}

# Production server - uvicorn with single worker (Render free tier)
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT}