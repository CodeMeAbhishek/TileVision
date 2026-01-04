# Render Deployment & Restart Guide

## Production URL
Your backend is deployed at: **https://tilevision.onrender.com**

## How to Restart Backend Server on Render (Free Account)

### Method 1: Via Render Dashboard (Easiest)
1. **Log in to Render Dashboard**
   - Go to: https://dashboard.render.com
   - Sign in with your account

2. **Navigate to Your Service**
   - Click on "Services" in the left sidebar
   - Find your service: `tilevision` (or whatever you named it)

3. **Restart the Service**
   - Click on your service name
   - In the service dashboard, look for the **"Manual Deploy"** section
   - Click the **"Restart"** button (usually at the top right)
   - Or click **"Manual Deploy"** → **"Deploy latest commit"**

### Method 2: Via Render CLI (If Installed)
```bash
# Install Render CLI (if not installed)
npm install -g render-cli

# Login
render login

# Restart service
render services:restart <service-id>
```

### Method 3: Trigger via Git Push
- Push any commit to your connected Git repository
- Render will automatically detect and redeploy
- This effectively restarts the service

## Important Notes for Free Tier

### Free Tier Limitations:
- **Spins down after 15 minutes of inactivity**
- **Cold start takes 30-60 seconds** (first request after spin-down)
- **750 hours/month free** (enough for 24/7 if you're the only user)
- **No auto-restart on crash** (you need to manually restart)

### To Keep Service Active:
1. **Use UptimeRobot** (Free monitoring service)
   - Set up monitoring for: `https://tilevision.onrender.com/health`
   - Set check interval to 5 minutes
   - This will ping your service and keep it awake

2. **Add Health Check Endpoint** (Already exists)
   - Your backend has: `GET /health` endpoint
   - This is perfect for monitoring services

## Current Deployment Status
Based on your UptimeRobot dashboard:
- ✅ Service is **UP**
- ✅ Uptime: **99.744%** (last 7/30 days)
- ✅ Currently up for **2d 18h 19m**
- ✅ Health checks every **5 minutes**

## Building APK with Production URL

The APK has been built with production URL: `https://tilevision.onrender.com`

**APK Location:**
```
mobile\build\app\outputs\flutter-apk\app-release.apk
```

## Environment Variables on Render

Make sure these are set in Render Dashboard:
1. Go to your service → **Environment** tab
2. Add/verify these variables:
   - `REPLICATE_API_TOKEN` - Your Replicate API token
   - `PORT` - Usually auto-set by Render (default: 8000)
   - `BASE_URL` - Optional, defaults to `https://tilevision.onrender.com`

## Troubleshooting

### Service Won't Start:
1. Check **Logs** tab in Render dashboard
2. Verify environment variables are set
3. Check if `requirements.txt` is up to date
4. Verify `Procfile` or `render.yaml` is correct

### Service Keeps Spinning Down:
- Set up UptimeRobot monitoring (free)
- Or upgrade to paid plan for always-on service

### Cold Start Issues:
- First request after spin-down takes 30-60 seconds
- This is normal for free tier
- Consider showing loading message in mobile app

## Quick Restart Steps (Summary)
1. Go to https://dashboard.render.com
2. Click "Services" → Your service name
3. Click "Restart" button
4. Wait 30-60 seconds for service to come back online

