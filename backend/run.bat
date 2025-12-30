@echo off
REM TileVision Backend Development Server
REM This script sets up and runs the FastAPI backend server

echo ================================
echo TileVision Backend Setup
echo ================================

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed
    exit /b 1
)

echo Using Python:
python --version

REM Check if virtual environment exists
if not exist "venv\" (
    echo.
    echo Creating virtual environment...
    python -m venv venv
    echo √ Virtual environment created
)

REM Activate virtual environment
echo.
echo Activating virtual environment...
call venv\Scripts\activate.bat
echo √ Virtual environment activated

REM Install/upgrade dependencies
echo.
echo Installing dependencies from requirements.txt...
python -m pip install --upgrade pip >nul 2>&1
python -m pip install -r requirements.txt

REM Add pytest for testing
python -m pip install pytest >nul 2>&1
echo √ Dependencies installed

REM Check if .env file exists
if not exist ".env" (
    echo.
    echo ⚠ Warning: .env file not found
    echo Creating .env from .env.example...
    copy .env.example .env >nul
    echo √ Created .env file
    echo ⚠ Please update .env with your REPLICATE_API_TOKEN
)

echo.
echo ================================
echo Starting Development Server
echo ================================
echo Server will be available at: http://localhost:8000
echo API docs at: http://localhost:8000/docs
echo Press Ctrl+C to stop the server
echo.

REM Run uvicorn with reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000
