#!/bin/bash
# Build script for Render.com deployment
# Ensures Python 3.11 and proper dependency installation

set -e

echo "Python version:"
python --version

echo "Upgrading pip..."
pip install --upgrade pip setuptools wheel

echo "Installing dependencies..."
pip install -r requirements.txt

echo "Build complete!"

