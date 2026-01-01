# 🔧 Render Deployment Fix

## Problem
Build fails with error: `Cannot import 'setuptools.build_meta'` or `numpy` installation fails.

## Root Cause
Render is using **Python 3.13.4** by default, but your dependencies (especially `numpy==1.24.3`) don't support Python 3.13 yet.

## ✅ Solution (2 Steps)

### Step 1: Set Python Version in Render Dashboard

1. Go to your Render service dashboard
2. Click **"Settings"** tab
3. Scroll down to **"Python Version"** section
4. Select **Python 3.11.9** (or latest 3.11.x available)
5. Click **"Save Changes"**

### Step 2: Update Build Command

In Render Dashboard → Settings → Build & Deploy:

**Change Build Command to:**
```bash
pip install --upgrade pip setuptools wheel && pip install -r requirements.txt
```

**OR if using Root Directory:**
```bash
cd backend && pip install --upgrade pip setuptools wheel && pip install -r requirements.txt
```

### Step 3: Redeploy

1. Click **"Manual Deploy"** → **"Deploy latest commit"**
2. Wait for build to complete
3. Check logs - should see Python 3.11.x now

---

## Alternative: Use Docker

If Python version issues persist, use Docker instead:

1. In Render Dashboard → Settings
2. Change **"Environment"** from `Python 3` to `Docker`
3. Set **"Dockerfile Path"**: `backend/Dockerfile`
4. Set **"Docker Context"**: `backend/`
5. Save and redeploy

Dockerfile already specifies Python 3.11, so this should work immediately.

---

## Verify Fix

After redeploy, check build logs:
- Should see: `Using Python version 3.11.x`
- Should see: `Successfully installed numpy...`
- Build should complete without errors

---

## Still Having Issues?

1. Check build logs for specific error messages
2. Verify `requirements.txt` is in the correct location
3. Ensure `runtime.txt` exists (though Render may ignore it)
4. Try Docker deployment method instead

