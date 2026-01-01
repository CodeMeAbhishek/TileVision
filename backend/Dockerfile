FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for OpenCV and image processing
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create static directory for tiles
RUN mkdir -p static/tiles

# Expose port (Cloud Run uses PORT env var)
ENV PORT=8080
EXPOSE 8080

# Run the application
CMD uvicorn main:app --host 0.0.0.0 --port $PORT
