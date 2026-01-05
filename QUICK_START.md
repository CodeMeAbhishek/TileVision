# Quick Start Guide - TileVision with Authentication

## What Was Implemented

✅ **Authentication Required**: App now requires login before access  
✅ **Login Only**: Users can only login - accounts created by admin in Supabase  
✅ **Supabase Integration**: Ready for Supabase authentication  
✅ **User-Specific Usage Tracking**: Each user has separate usage limits  
✅ **Image Limits from Dashboard**: Set per-user limits directly in Supabase dashboard  

## Setup Steps

### 1. Install Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Set Up Supabase

Follow the detailed guide in `SUPABASE_SETUP.md`:

1. Create Supabase project at [supabase.com](https://supabase.com)
2. Get your API keys (URL and anon key)
3. Run the SQL scripts to create tables
4. Configure authentication

### 3. Configure App

Open `mobile/lib/main.dart` and replace:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

With your actual values:

```dart
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 4. Run the App

```bash
flutter run
```

The app will:
- Show login screen if not authenticated
- Block access to main app until login
- Automatically redirect after successful login

### 5. Create Test User

1. **Create Account in Supabase**: Go to Authentication → Users → Add user
2. **Set Image Limit**: Go to Table Editor → `user_metadata` → Set limit for user
3. **Sign In**: User can now login with credentials from Supabase
4. **Usage Tracking**: App automatically tracks usage per user

## User Management (Supabase Dashboard)

### Create User Accounts

1. Go to **Authentication** → **Users** in Supabase dashboard
2. Click **"Add user"** → **"Create new user"**
3. Enter email and set password
4. Copy the user's UUID

### Set Image Limits

1. Go to **Table Editor** → `user_metadata` in Supabase dashboard
2. Click **Insert row** or edit existing row
3. Set:
   - **id**: User's UUID
   - **is_beta_user**: `true`
   - **image_limit**: Your desired limit (e.g., 10, 25, 50)
4. Click **Save**

**Note**: Each user can have a different image limit set directly in the dashboard.

## Key Features

### Authentication Flow
- Admin creates user accounts in Supabase dashboard
- Admin sets image limits per user in `user_metadata` table
- Users login with credentials provided by admin
- Only users with `is_beta_user = true` can access the app
- Session persists across app restarts

### Usage Tracking
- Each user has separate usage count
- Image limits set per user in Supabase dashboard (`user_metadata` table)
- App automatically fetches limit from database on login
- App blocks generation when limit reached
- Usage stats shown in Profile screen

### Security
- Row Level Security (RLS) enabled
- Users can only see their own data
- Service role key only for admin panel
- Anon key safe for client apps

## Troubleshooting

### "Supabase not initialized"
- Check that you've set the URL and key in `main.dart`
- Verify values are correct (no extra spaces)

### "Your account is pending approval"
- User account exists but metadata not set up
- Solution: Create record in `user_metadata` table with `is_beta_user = true`

### "Invalid login credentials"
- User account doesn't exist in Supabase
- Solution: Create user account in Supabase dashboard (Authentication → Users)

### Can't login
- Check that user account exists in Supabase
- Verify `user_metadata` record exists with `is_beta_user = true`
- Check that image_limit is set in `user_metadata` table

## Next Steps

1. Complete Supabase setup (see `SUPABASE_SETUP.md`)
2. Test with a few beta users
3. Monitor usage via admin panel
4. Adjust image limits as needed
5. Collect feedback from beta testers

## Files Created/Modified

- ✅ `mobile/lib/services/auth_service.dart` - Authentication service
- ✅ `mobile/lib/screens/auth_screen.dart` - Login/signup UI
- ✅ `mobile/lib/widgets/auth_wrapper.dart` - Auth guard
- ✅ `mobile/lib/main.dart` - App initialization
- ✅ `admin/simple_admin.html` - Admin panel
- ✅ `SUPABASE_SETUP.md` - Detailed setup guide

## Support

For issues:
1. Check `SUPABASE_SETUP.md` for setup problems
2. Verify Supabase tables are created correctly
3. Check browser console for errors (admin panel)
4. Check Flutter logs for app errors

