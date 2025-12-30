# TileVision

**TileVision** is a mobile application that allows users to visualize different tiles on their room floors using AI-powered floor segmentation. Simply take or upload a photo of your room, select the floor area, choose a tile from the catalog, and see how it looks in real-time!

## 🚀 Features

- **Photo Capture**: Take photos directly from your device camera or upload from gallery
- **AI Floor Segmentation**: Automatically detect and segment floor areas using Segment Anything Model (SAM)
- **Tile Visualization**: Apply different tile patterns to your floor with realistic perspective correction
- **Tile Catalog**: Browse through a variety of tiles with pricing and size information
- **Share & Save**: Save your visualizations to gallery or share them directly

## 📁 Project Structure

```
tilevision/
├── backend/                 # FastAPI backend server
│   ├── main.py             # Main API endpoints
│   ├── segmentation.py     # Floor segmentation using SAM
│   ├── perspective.py      # Perspective correction and tile application
│   ├── requirements.txt    # Python dependencies
│   ├── .env.example        # Environment variables template
│   └── Dockerfile          # Docker configuration
├── mobile/                 # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart       # App entry point
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API service
│   │   └── models/         # Data models
│   └── pubspec.yaml        # Flutter dependencies
└── README.md
```

## 🛠️ Tech Stack

### Backend
- **FastAPI**: High-performance Python web framework
- **OpenCV**: Image processing and perspective transformation
- **Pillow**: Image manipulation
- **Replicate API**: Segment Anything Model integration
- **Python 3.11**: Programming language

### Mobile
- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language
- **image_picker**: Camera and gallery access
- **http**: API communication
- **share_plus**: Sharing functionality

## 📋 Prerequisites

### Backend
- Python 3.11 or higher
- pip package manager
- Replicate API token (for SAM integration)

### Mobile
- Flutter SDK (latest stable version)
- Android Studio / Xcode (for mobile development)
- Android/iOS device or emulator

## 🔧 Setup Instructions

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd tilevision/backend
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv venv
   
   # On Windows
   venv\Scripts\activate
   
   # On macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables**:
   ```bash
   # Copy example env file
   cp .env.example .env
   
   # Edit .env and add your Replicate API token
   # REPLICATE_API_TOKEN=your_token_here
   ```

5. **Run the server**:
   ```bash
   python main.py
   ```
   
   The API will be available at `http://localhost:8000`

### Mobile Setup

1. **Navigate to mobile directory**:
   ```bash
   cd tilevision/mobile
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint** (if not using localhost):
   - Open `lib/services/api_service.dart`
   - Update the `_defaultBaseUrl` to your backend server URL

4. **Run the app**:
   ```bash
   # For Android
   flutter run
   
   # For iOS (macOS only)
   flutter run -d ios
   ```

## 🐳 Docker Setup (Backend)

1. **Build Docker image**:
   ```bash
   cd tilevision/backend
   docker build -t tilevision-backend .
   ```

2. **Run container**:
   ```bash
   docker run -p 8000:8000 -e REPLICATE_API_TOKEN=your_token tilevision-backend
   ```

## 🔑 Environment Variables

### Backend (.env)

| Variable | Description | Default |
|----------|-------------|---------|
| `REPLICATE_API_TOKEN` | Replicate API token for SAM | Required |
| `MAX_IMAGE_SIZE` | Maximum image dimension in pixels | 1024 |
| `DEBUG` | Enable debug mode | true |
| `PORT` | Server port | 8000 |

## 📡 API Endpoints

### Health Check
```
GET /health
```
Returns server status and version information.

### Segment Floor
```
POST /api/segment-floor
Content-Type: multipart/form-data

Parameters:
- file: Image file (required)
- point_x: X coordinate of point on floor (required)
- point_y: Y coordinate of point on floor (required)

Response:
{
  "mask": "base64_encoded_png",
  "confidence": 0.95,
  "processing_time": 2.3
}
```

### Apply Tile
```
POST /api/apply-tile
Content-Type: multipart/form-data

Parameters:
- original_image: Original room image (required)
- floor_mask: Floor segmentation mask (required)
- tile_image: Tile pattern image (required)
- tile_size: Tile dimensions like "2x2" (required)

Response:
{
  "result_image": "base64_encoded_jpeg",
  "processing_time": 1.8
}
```

### Get Tiles
```
GET /api/tiles

Response:
[
  {
    "id": 1,
    "name": "Marble White",
    "image_url": "https://...",
    "size": "2x2",
    "price": 1200.00
  },
  ...
]
```

## 🧪 Testing

### Backend Testing
```bash
cd backend

# Test health endpoint
curl http://localhost:8000/health

# Test with sample image
curl -X POST http://localhost:8000/api/segment-floor \
  -F "file=@test_image.jpg" \
  -F "point_x=500" \
  -F "point_y=600"
```

### Mobile Testing
```bash
cd mobile

# Run Flutter tests
flutter test

# Run on device/emulator
flutter run
```

## 🚧 Development Roadmap

### Phase 1 (Current)
- [x] Basic project structure
- [x] Backend API endpoints
- [x] Flutter mobile UI
- [x] Floor segmentation integration
- [x] Basic tile application

### Phase 2 (TODO)
- [ ] Complete SAM API integration
- [ ] Advanced perspective correction algorithms
- [ ] Real tile catalog with database
- [ ] User authentication
- [ ] Saved projects/history

### Phase 3 (TODO)
- [ ] Multiple floor support
- [ ] 3D visualization
- [ ] AR preview mode
- [ ] Cost estimation
- [ ] Tile vendor integration

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- **Segment Anything Model (SAM)** by Meta AI
- **Replicate** for AI model hosting
- **FastAPI** for the excellent web framework
- **Flutter** for cross-platform mobile development

## 📧 Support

For questions or issues, please open an issue on GitHub or contact the development team.

---

**Made with ❤️ using Flutter and FastAPI**
