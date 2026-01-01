# ⚡ Quick Deploy Checklist

## Render.com Setup (5 minutes)

1. **Create Web Service**
   - Go to: https://dashboard.render.com
   - New → Web Service
   - Connect Git repo

2. **Settings** ⚠️ **CRITICAL**
   - **Python Version**: Set to **Python 3.11.9** (in Settings → Python Version)
   - **Root Directory**: `backend` (if backend is in subdirectory)
   - **Build**: `pip install --upgrade pip setuptools wheel && pip install -r requirements.txt`
   - **Start**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **OR use Dockerfile**: Set Environment to "Docker", Dockerfile Path: `backend/Dockerfile`

3. **Environment Variables**
   ```
   REPLICATE_API_TOKEN=your_token
   PORT=10000
   DEBUG=false
   MAX_IMAGE_SIZE=1024
   ALLOWED_ORIGINS=*
   ```

4. **Deploy** → Get URL: `https://your-app.onrender.com`

---

## UptimeRobot Setup (2 minutes)

1. **Add Monitor**
   - Go to: https://uptimerobot.com/dashboard
   - Add New Monitor → HTTP(s)
   - URL: `https://your-app.onrender.com/health`
   - Interval: 5 minutes

2. **Done!** Service stays awake 24/7

---

## Update Mobile App

**File**: `mobile/lib/services/api_service.dart`

```dart
static const String _defaultBaseUrl = 'https://your-app.onrender.com';
```

---

## Test

```bash
curl https://your-app.onrender.com/health
```

Should return: `{"status": "healthy", ...}`

---

✅ **That's it!** Your backend is live and free forever.

