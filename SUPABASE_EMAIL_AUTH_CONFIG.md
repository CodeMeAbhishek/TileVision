# Supabase Email Auth Configuration Guide

## Recommended Settings for TileVision Beta

Since accounts are created by admin only (no signup from app), here are the recommended settings:

### ✅ Enable Email Provider
**Setting**: Enable Email provider  
**Value**: ✅ **ON** (Checked)  
**Why**: Required for users to login with email/password

### 🔒 Secure Email Change
**Setting**: Secure email change  
**Value**: ✅ **ON** (Recommended) or OFF  
**Why**: 
- ON: More secure - requires confirmation on both old and new email
- OFF: Simpler - only new email needs confirmation
- **Recommendation**: ON for better security

### 🔒 Secure Password Change
**Setting**: Secure password change  
**Value**: ✅ **ON** (Recommended)  
**Why**: 
- ON: Users must be recently logged in (within 24 hours) to change password
- OFF: Users can change password anytime
- **Recommendation**: ON for better security

### 🛡️ Prevent Use of Leaked Passwords
**Setting**: Prevent use of leaked passwords  
**Value**: ✅ **ON** (If on Pro plan) or OFF (Free tier)  
**Why**: 
- Rejects passwords found in data breaches
- Only available on Pro plan and above
- **Recommendation**: Enable if you have Pro plan

### 📏 Minimum Password Length
**Setting**: Minimum password length  
**Value**: **6** characters (default)  
**Why**: 
- Matches app validation (minimum 6 characters)
- Can increase to 8 for better security
- **Recommendation**: Keep at 6 (matches app) or increase to 8

### 🔤 Password Requirements
**Setting**: Password Requirements  
**Value**: **No required characters (default)**  
**Why**: 
- Default is fine for beta testing
- Can add requirements later if needed
- **Recommendation**: Keep default for now

### ⏱️ Email OTP Expiration
**Setting**: Email OTP Expiration  
**Value**: **3600** seconds (1 hour)  
**Why**: 
- Not critical since we're not using email confirmation
- Default is fine
- **Recommendation**: Keep default

### 🔢 Email OTP Length
**Setting**: Email OTP Length  
**Value**: **8** digits  
**Why**: 
- Not critical since we're not using email confirmation
- Default is fine
- **Recommendation**: Keep default

---

## ⚠️ IMPORTANT: Disable Sign Ups

**This is the most important setting!**

1. Go to **Authentication** → **Sign In / Providers**
2. Find the **"User Signups"** section
3. Toggle **"Allow new users to sign up"** to **OFF** (grey/disabled)
4. Click **"Save changes"** button at the bottom
5. This prevents users from creating accounts from the app

**Why**: Since accounts are created by admin only, we need to disable public signups.

**Also in User Signups section:**
- **"Confirm email"**: Toggle to **OFF** (admin creates accounts, no confirmation needed)
- **"Allow manual linking"**: Keep **OFF** (disabled)
- **"Allow anonymous sign-ins"**: Keep **OFF** (disabled)

---

## Summary of Recommended Settings

| Setting | Recommended Value | Reason |
|---------|-------------------|--------|
| Enable Email provider | ✅ ON | Required for login |
| Secure email change | ✅ ON | Better security |
| Secure password change | ✅ ON | Better security |
| Prevent leaked passwords | ✅ ON (if Pro) | Better security |
| Minimum password length | 6 or 8 | Matches app validation |
| Password requirements | Default | Fine for beta |
| Email OTP expiration | 3600 (default) | Not critical |
| Email OTP length | 8 (default) | Not critical |
| **Disable sign ups** | ✅ **ON** | **Critical - prevents app signups** |

---

## Step-by-Step Configuration

1. **Go to Authentication → Providers**
   - ✅ Enable Email provider
   - Configure other settings as above

2. **Go to Authentication → Settings**
   - ✅ **Disable sign ups** (Most Important!)
   - This prevents account creation from app

3. **Save all changes**

---

## Testing After Configuration

1. Try to create account from app → Should fail (signups disabled)
2. Create user in dashboard → Should work
3. Login with dashboard-created user → Should work
4. Check that user can access app → Should work

---

## Notes

- **Email confirmations**: Can be disabled since admin creates accounts
- **Password reset**: Can be enabled if you want users to reset passwords
- **OTP settings**: Not critical since we're not using email OTP for login
- **Password requirements**: Can be made stricter later if needed

---

## Troubleshooting

### Users can still sign up from app
- Check that "Disable sign ups" is enabled in Authentication → Settings
- Verify the setting is saved

### Users can't login
- Check that Email provider is enabled
- Verify user account exists in Authentication → Users
- Check that `user_metadata` is set up correctly

### Password too weak error
- Check minimum password length setting
- Ensure password meets requirements
- Try increasing minimum length if needed

