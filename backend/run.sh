#!/bin/bash
# TileVision Backend Development Server
# This script sets up and runs the FastAPI backend server

set -e  # Exit on error

echo "================================"
echo "TileVision Backend Setup"
echo "================================"

# Check if Python is installed
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "Error: Python is not installed"
    exit 1
fi

# Use python3 if available, otherwise python
PYTHON_CMD="python"
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
fi

echo "Using Python: $PYTHON_CMD"
$PYTHON_CMD --version

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo ""
    echo "Creating virtual environment..."
    $PYTHON_CMD -m venv venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
echo ""
echo "Activating virtual environment..."
if [ -f "venv/Scripts/activate" ]; then
    # Windows Git Bash
    source venv/Scripts/activate
elif [ -f "venv/bin/activate" ]; then
    # Linux/Mac
    source venv/bin/activate
else
    echo "Error: Could not find virtual environment activation script"
    exit 1
fi
echo "✓ Virtual environment activated"

# Install/upgrade dependencies
echo ""
echo "Installing dependencies from requirements.txt..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt

# Add pytest for testing
pip install pytest > /dev/null 2>&1
echo "✓ Dependencies installed"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo ""
    echo "⚠ Warning: .env file not found"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "✓ Created .env file"
    echo "⚠ Please update .env with your REPLICATE_API_TOKEN"
fi

echo ""
echo "================================"
echo "Starting Development Server"
echo "================================"
echo "Server will be available at: http://localhost:8000"
echo "API docs at: http://localhost:8000/docs"
echo "Press Ctrl+C to stop the server"
echo ""

# Run uvicorn with reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000
