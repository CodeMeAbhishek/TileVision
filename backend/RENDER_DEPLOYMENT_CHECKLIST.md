# Render Deployment Checklist - Security Update

## ✅ Yes, Push to Render to Deploy Security Updates

After implementing security hardening, you need to:
1. **Push code to trigger Render rebuild** (or manually deploy)
2. **Update environment variables** in Render dashboard
3. **Restart the service** to apply changes

---

## 🔑 Environment Variables for Render (Backend Only)

### Required Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `REPLICATE_API_TOKEN` | `your_token_here` | **Required** - Replicate API token for AI services |

### Recommended Variables (Security Hardening)

| Variable | Value | Description |
|----------|-------|-------------|
| `ALLOWED_ORIGINS` | `*` or specific domains | **NEW** - CORS origins (use `*` for testing, specific domains for production) |
| `DEBUG` | `false` | Set to `false` for production |
| `MAX_IMAGE_SIZE` | `10` | Max image size in MB (default: 10MB) |
| `BASE_URL` | `https://tilevision.onrender.com` | Base URL for tile images (auto-detected) |

### Optional Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `PORT` | `10000` | Port (Render sets this automatically, but good fallback) |
| `AI_VALIDATION_THRESHOLD` | `0.12` | AI pattern validation threshold (optional) |

---

## 📋 Two .env Files Explained

### 1. `backend/.env` → Render Environment Variables

**Purpose**: Backend server configuration (production)

**Where to set**: Render Dashboard → Environment tab

**Variables needed in Render**:
```
REPLICATE_API_TOKEN=your_token_here
ALLOWED_ORIGINS=*
DEBUG=false
MAX_IMAGE_SIZE=10
BASE_URL=https://tilevision.onrender.com
PORT=10000
```

### 2. `mobile/.env` → Local Development/Build Only

**Purpose**: Mobile app configuration (NOT for Render)

**Where to set**: Local `.env` file in `mobile/` directory

**Variables needed locally**:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Important**: 
- ❌ **DO NOT** add mobile env vars to Render
- ✅ Mobile `.env` is only for local development and building APK
- ✅ Supabase anon key is safe for client-side (designed for this)

---

## 🚀 Deployment Steps

### Step 1: Update Render Environment Variables

1. Go to Render Dashboard → Your Service → **Environment** tab
2. Add/Update these variables:

   **Required:**
   - `REPLICATE_API_TOKEN` (should already exist, verify it's set)

   **New/Update:**
   - `ALLOWED_ORIGINS` = `*` (or specific domains like `https://yourdomain.com,https://www.yourdomain.com`)
   - `DEBUG` = `false`
   - `MAX_IMAGE_SIZE` = `10`
   - `BASE_URL` = `https://tilevision.onrender.com` (or your custom domain)

### Step 2: Deploy Code Changes

**Option A: Auto-deploy (if connected to Git)**
- Push code to your repository
- Render will automatically detect changes and rebuild

**Option B: Manual Deploy**
- Go to Render Dashboard → Your Service
- Click **"Manual Deploy"** → **"Deploy latest commit"**

### Step 3: Verify Deployment

1. Check deployment logs for errors
2. Test health endpoint:
   ```bash
   curl https://tilevision.onrender.com/health
   ```
3. Test rate limiting (make 11 rapid requests):
   ```bash
   for i in {1..11}; do curl https://tilevision.onrender.com/api/tiles; done
   ```
   Expected: 11th request should return `429 Too Many Requests`

---

## 📱 Mobile APK Build

### For Building APK Locally:

1. **Create/Update `mobile/.env` file**:
   ```bash
   cd mobile
   # Create .env file if it doesn't exist
   echo "SUPABASE_URL=your_supabase_url" > .env
   echo "SUPABASE_ANON_KEY=your_supabase_anon_key" >> .env
   ```

2. **Build APK**:
   ```bash
   flutter build apk --release
   ```

**Important**: 
- Mobile `.env` is **NOT** used by Render
- Mobile `.env` is only for local development and APK builds
- The APK will include the Supabase keys (this is safe - anon key is designed for client-side)

---

## 🔍 Current Render Environment Variables (From Screenshot)

Based on your Render dashboard, you currently have:
- ✅ `ALLOWED_ORIGINS` - Set
- ✅ `DEBUG` - Set
- ✅ `MAX_IMAGE_SIZE` - Set
- ✅ `PORT` - Set
- ✅ `REPLICATE_API_TOKEN` - Set (hidden)

**Action Required**: 
- Verify `ALLOWED_ORIGINS` is set correctly (should be `*` for testing or specific domains for production)
- All other variables look good!

---

## ⚠️ Important Notes

1. **Backend vs Mobile**:
   - Backend env vars → Render Dashboard
   - Mobile env vars → Local `.env` file only

2. **Security**:
   - Never commit `.env` files to git
   - Render encrypts secret values automatically
   - Mobile Supabase anon key is safe for client-side

3. **After Deployment**:
   - Service will restart automatically
   - New security features (rate limiting, validation) will be active
   - Test endpoints to verify everything works

---

## ✅ Quick Checklist

- [ ] Push code to trigger Render rebuild (or manual deploy)
- [ ] Verify `REPLICATE_API_TOKEN` is set in Render
- [ ] Add/Update `ALLOWED_ORIGINS` in Render (if not already set)
- [ ] Verify `DEBUG=false` in Render
- [ ] Wait for deployment to complete
- [ ] Test `/health` endpoint
- [ ] Test rate limiting (should get 429 after limit)
- [ ] Build APK locally with mobile `.env` file (if needed)

---

## 🆘 Troubleshooting

**Service won't start?**
- Check deployment logs in Render
- Verify `REPLICATE_API_TOKEN` is set correctly
- Check that `requirements.txt` includes `slowapi`

**Rate limiting not working?**
- Verify `slowapi` is installed (check requirements.txt)
- Check deployment logs for import errors

**CORS errors?**
- Update `ALLOWED_ORIGINS` in Render to include your domain
- Or set to `*` for testing (not recommended for production)

