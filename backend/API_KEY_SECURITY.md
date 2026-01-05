# API Key Security Guide

This document outlines how API keys are handled securely in the TileVision application.

## ✅ Current Security Status

### Backend API Keys

All backend API keys are stored in **environment variables only**:

1. **REPLICATE_API_TOKEN**
   - **Location**: Environment variable (`.env` file in development, platform secrets in production)
   - **Usage**: Used for AI services (segmentation, material replacement, realistic rendering)
   - **Exposure**: ❌ Never exposed to client-side code
   - **Status**: ✅ Secure

### Mobile App API Keys

The mobile app uses **Supabase anon key**, which is safe for client-side use:

1. **SUPABASE_URL** and **SUPABASE_ANON_KEY**
   - **Location**: `.env` file (git-ignored)
   - **Usage**: Supabase authentication and database access
   - **Exposure**: ✅ Safe for client-side (Supabase anon key is designed for this)
   - **Status**: ✅ Secure (anon key has Row Level Security policies)

## 🔒 Security Best Practices Implemented

### 1. Environment Variable Storage

✅ **All sensitive keys in environment variables**
- Development: `.env` file (git-ignored)
- Production: Platform secrets (Render.com, etc.)

### 2. No Hardcoded Keys

✅ **No API keys in source code**
- All keys loaded from environment variables
- No keys in configuration files
- No keys in comments or documentation

### 3. Git Ignore Protection

✅ **`.env` files are git-ignored**
- Prevents accidental commits of keys
- Separate `.env` files for each environment

### 4. Client-Side Key Safety

✅ **Only safe keys exposed client-side**
- Supabase anon key is safe (has RLS policies)
- No backend API keys in mobile app
- Backend keys never sent to client

## 📋 Key Management Checklist

### Development Setup

- [x] Create `.env` file in `backend/` directory
- [x] Add `REPLICATE_API_TOKEN=your_token_here` to `.env`
- [x] Create `.env` file in `mobile/` directory
- [x] Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to mobile `.env`
- [x] Verify `.env` files are in `.gitignore`

### Production Deployment

- [x] Store `REPLICATE_API_TOKEN` in deployment platform secrets
- [x] Never commit `.env` files to version control
- [x] Use different keys for development and production
- [x] Rotate keys periodically

### Key Rotation Procedure

1. **Generate new key** in service provider dashboard
2. **Update environment variable**:
   - Development: Update `.env` file
   - Production: Update platform secrets
3. **Restart service** to load new key
4. **Verify functionality** with test request
5. **Revoke old key** after verification (wait 24-48 hours)

## 🚨 Security Warnings

### ⚠️ Never Do These:

- ❌ Commit `.env` files to git
- ❌ Hardcode API keys in source code
- ❌ Share API keys in chat/email
- ❌ Use production keys in development
- ❌ Expose backend API keys to client-side code
- ❌ Store keys in client-side configuration files

### ✅ Always Do These:

- ✅ Use environment variables for all keys
- ✅ Keep `.env` files in `.gitignore`
- ✅ Use different keys for each environment
- ✅ Rotate keys regularly (every 90 days recommended)
- ✅ Monitor API usage for suspicious activity
- ✅ Use least privilege principle (minimum required permissions)

## 🔍 Verification Steps

### Check for Hardcoded Keys

```bash
# Search for potential API keys in codebase
grep -r "r[a-zA-Z0-9_-]\{40,\}" backend/
grep -r "sk-[a-zA-Z0-9_-]\{40,\}" backend/
grep -r "REPLICATE.*=" backend/ --exclude-dir=venv
```

### Verify Environment Variables

```bash
# Backend
cd backend
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print('REPLICATE_API_TOKEN:', 'SET' if os.getenv('REPLICATE_API_TOKEN') else 'NOT SET')"

# Mobile (check .env file exists)
cd mobile
ls -la .env
```

### Test Key Loading

```python
# backend/test_keys.py
import os
from dotenv import load_dotenv

load_dotenv()

token = os.getenv("REPLICATE_API_TOKEN")
if token and token != "your_token_here":
    print("✅ REPLICATE_API_TOKEN is set")
else:
    print("❌ REPLICATE_API_TOKEN is not set or using placeholder")
```

## 📚 Additional Resources

- [OWASP API Security](https://owasp.org/www-project-api-security/)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/security)
- [Environment Variables Best Practices](https://12factor.net/config)
- [Render.com Environment Variables](https://render.com/docs/environment-variables)

## 🔄 Key Rotation Schedule

Recommended rotation schedule:

- **Development keys**: Rotate every 6 months
- **Production keys**: Rotate every 90 days
- **After security incident**: Rotate immediately
- **After team member leaves**: Rotate within 24 hours

## 📞 Support

If you suspect a key has been compromised:

1. **Immediately revoke** the key in service provider dashboard
2. **Generate new key** and update environment variables
3. **Review access logs** for suspicious activity
4. **Notify team** of the rotation
5. **Document incident** for security review

