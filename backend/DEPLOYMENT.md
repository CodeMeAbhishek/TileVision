# 🚀 TileVision Backend Deployment Guide

## Render.com + UptimeRobot Setup

This guide will help you deploy the TileVision backend to Render.com with 24/7 uptime using UptimeRobot.

---

## 📋 Prerequisites

1. **Render.com Account** (Free tier)
   - Sign up at: https://render.com
   - Free tier includes: 750 hours/month (enough for 24/7 uptime)

2. **UptimeRobot Account** (Free tier)
   - Sign up at: https://uptimerobot.com
   - Free tier includes: 50 monitors, 5-minute intervals

3. **Replicate API Token**
   - Get from: https://replicate.com/account/api-tokens
   - Required for AI features (SAM segmentation, ControlNet, Gemini)

---

## 🔧 Step 1: Prepare Your Code

### Option A: Using Procfile (Recommended for Render)

Your `Procfile` is already configured:
```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

### Option B: Using Docker

If you prefer Docker, your `Dockerfile` is ready. Render supports both methods.

---

## 🌐 Step 2: Deploy to Render.com

### 2.1 Create New Web Service

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Web Service"**
3. Connect your Git repository (GitHub/GitLab/Bitbucket)
4. Select your repository and branch

### 2.2 Configure Service Settings

**Basic Settings:**
- **Name**: `tilevision-backend` (or your preferred name)
- **Environment**: `Python 3`
- **Python Version**: `3.11.9` ⚠️ **IMPORTANT: Set this manually in Render dashboard!**
- **Region**: Choose closest to your users
- **Branch**: `main` (or your default branch)
- **Root Directory**: `backend` (if your backend folder is in a subdirectory)

**Build & Deploy:**
- **Build Command**: `pip install --upgrade pip setuptools wheel && pip install -r requirements.txt`
- **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

**OR if using Docker:**
- **Dockerfile Path**: `backend/Dockerfile`
- **Docker Context**: `backend/`

### 2.3 Set Environment Variables

Click **"Environment"** tab and add:

| Variable | Value | Description |
|----------|-------|-------------|
| `REPLICATE_API_TOKEN` | `your_token_here` | Your Replicate API token (required) |
| `PORT` | `10000` | Port (Render sets this automatically, but good to have fallback) |
| `DEBUG` | `false` | Set to false for production |
| `MAX_IMAGE_SIZE` | `1024` | Max image dimension in pixels |
| `ALLOWED_ORIGINS` | `*` | CORS origins (use `*` for testing, specific domains for production) |

**Important**: 
- Keep `REPLICATE_API_TOKEN` as **Secret** (Render will encrypt it)
- For production, set `ALLOWED_ORIGINS` to your mobile app's domain(s)

### 2.4 Deploy

1. Click **"Create Web Service"**
2. Render will build and deploy your service
3. Wait for deployment to complete (usually 2-5 minutes)
4. Your service URL will be: `https://tilevision-backend.onrender.com` (or your custom domain)

---

## ⏰ Step 3: Setup UptimeRobot (Keep Server Awake)

### 3.1 Create Monitor

1. Go to [UptimeRobot Dashboard](https://uptimerobot.com/dashboard)
2. Click **"Add New Monitor"**
3. Configure:

**Monitor Settings:**
- **Monitor Type**: `HTTP(s)`
- **Friendly Name**: `TileVision Backend Keep-Alive`
- **URL**: `https://your-service-name.onrender.com/health`
- **Monitoring Interval**: `5 minutes` (free tier minimum)

**Alert Settings:**
- **Alert Contacts**: Add your email (optional, for notifications)

### 3.2 Save Monitor

Click **"Create Monitor"**

**How it works:**
- UptimeRobot pings your `/health` endpoint every 5 minutes
- This prevents Render from spinning down your service
- Uses ~288 requests/day (well within free tier limits)
- Keeps your service active 24/7 using Render's 750 free hours efficiently

---

## ✅ Step 4: Verify Deployment

### 4.1 Test Health Endpoint

```bash
curl https://your-service-name.onrender.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "timestamp": "2025-01-XX...",
  "services": {
    "segmentation": true,
    "perspective": true
  }
}
```

### 4.2 Test API Docs

Visit: `https://your-service-name.onrender.com/docs`

You should see the interactive API documentation.

### 4.3 Test Tiles Endpoint

```bash
curl https://your-service-name.onrender.com/api/tiles
```

Should return the tile catalog.

---

## 📱 Step 5: Update Mobile App

Update your mobile app's API base URL:

**File**: `mobile/lib/services/api_service.dart`

```dart
// Change from:
static const String _defaultBaseUrl = 'http://10.0.2.2:8000';

// To:
static const String _defaultBaseUrl = 'https://your-service-name.onrender.com';
```

**For Android Emulator:**
- Use `http://10.0.2.2:8000` for local development
- Use Render URL for production/testing

---

## 🔒 Production Security Checklist

- [ ] Set `DEBUG=false` in Render environment variables
- [ ] Set `ALLOWED_ORIGINS` to specific domains (not `*`)
- [ ] Use HTTPS (Render provides this automatically)
- [ ] Keep `REPLICATE_API_TOKEN` as secret in Render
- [ ] Monitor usage in Render dashboard
- [ ] Set up alerts in UptimeRobot for downtime

---

## 💰 Cost Breakdown

### Render.com (Free Tier)
- **750 hours/month** = 31 days × 24 hours = **744 hours**
- With UptimeRobot pings: **100% covered** ✅
- **Cost**: $0/month

### UptimeRobot (Free Tier)
- **50 monitors** (you need 1)
- **5-minute intervals** (perfect for keep-alive)
- **Cost**: $0/month

**Total Monthly Cost: $0** 🎉

---

## 🐛 Troubleshooting

### Service Keeps Spinning Down

**Problem**: Service sleeps after 15 minutes despite UptimeRobot

**Solutions**:
1. Verify UptimeRobot monitor is active (green status)
2. Check that `/health` endpoint returns 200
3. Reduce ping interval if possible (paid UptimeRobot allows 1-minute)
4. Consider Render's paid tier ($7/month) for always-on service

### Build Fails

**Common Issues**:

1. **Python Version Mismatch (Most Common)**
   - **Error**: `Cannot import 'setuptools.build_meta'` or `numpy` build fails
   - **Cause**: Render using Python 3.13, but dependencies need Python 3.11
   - **Fix**: 
     - Go to Render Dashboard → Your Service → Settings
     - Scroll to "Python Version"
     - Select **Python 3.11.9** (or latest 3.11.x)
     - Save and redeploy

2. **Missing Dependencies**
   - **Error**: Package installation fails
   - **Fix**: Check Render build logs for specific package errors
   - **Solution**: Update `requirements.txt` with compatible versions

3. **OpenCV Dependencies**
   - **Error**: OpenCV build fails
   - **Fix**: Should be handled automatically, but if issues persist, check system dependencies

4. **Setuptools Missing**
   - **Error**: `BackendUnavailable: Cannot import 'setuptools.build_meta'`
   - **Fix**: Updated build command includes `setuptools` installation

### CORS Errors

**Problem**: Mobile app can't connect to API

**Solution**: 
- Set `ALLOWED_ORIGINS=*` for testing
- For production, set specific origins: `ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com`

### Slow Response Times

**First Request**: 30-60 seconds (cold start)
- This is normal for Render free tier
- Subsequent requests: < 1 second

**Solution**: 
- UptimeRobot keeps service warm
- Consider paid tier for faster cold starts

---

## 📊 Monitoring

### Render Dashboard
- View logs: Real-time application logs
- Metrics: CPU, Memory, Request count
- Deployments: History and rollback options

### UptimeRobot Dashboard
- Uptime percentage
- Response times
- Alert history

---

## 🔄 Updating Deployment

1. Push changes to your Git repository
2. Render automatically detects changes
3. Triggers new build and deployment
4. Zero-downtime deployment (brief restart)

---

## 📝 Notes

- **Free Tier Limitations**:
  - 15-minute inactivity timeout (solved by UptimeRobot)
  - 30-second cold start on first request
  - 512MB RAM limit
  - Shared CPU resources

- **Scaling**:
  - Free tier handles 3-5 concurrent users well
  - For more users, consider Render's paid tiers ($7+/month)

---

## 🎉 Success!

Your TileVision backend is now:
- ✅ Deployed on Render.com
- ✅ Running 24/7 with UptimeRobot
- ✅ Free forever (within usage limits)
- ✅ Ready for mobile app integration

**Next Steps**:
1. Test all API endpoints
2. Update mobile app with Render URL
3. Monitor usage and performance
4. Enjoy your free hosting! 🚀

