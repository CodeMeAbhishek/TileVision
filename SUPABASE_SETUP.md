# Supabase Setup Guide for TileVision Beta Testing

This guide will walk you through setting up Supabase for authentication and user management in the TileVision app.

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click **"New Project"**
4. Fill in the project details:
   - **Name**: TileVision (or your preferred name)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose the closest region to your users
   - **Pricing Plan**: Free tier is sufficient for beta testing
5. Click **"Create new project"**
6. Wait 2-3 minutes for the project to be created

## Step 2: Get Your API Keys

1. In your Supabase project dashboard, go to **Settings** (gear icon) → **API**
2. You'll see two important values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: A long string starting with `eyJ...`
3. Copy both values - you'll need them for the app

## Step 3: Set Up Database Tables

### 3.1 Create User Metadata Table

1. Go to **SQL Editor** in your Supabase dashboard
2. Click **"New query"**
3. Paste and run this SQL:

```sql
-- Create user_metadata table
CREATE TABLE IF NOT EXISTS user_metadata (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  image_limit INTEGER DEFAULT 10 NOT NULL,
  is_beta_user BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_metadata_beta ON user_metadata(is_beta_user);

-- Enable Row Level Security
ALTER TABLE user_metadata ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own metadata
CREATE POLICY "Users can view own metadata"
  ON user_metadata FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update their own metadata (limited fields)
CREATE POLICY "Users can update own metadata"
  ON user_metadata FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
```

### 3.2 Create Usage Logs Table

```sql
-- Create usage_logs table
CREATE TABLE IF NOT EXISTS usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  action TEXT NOT NULL DEFAULT 'image_generated',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_usage_logs_user_id ON usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_created_at ON usage_logs(created_at);

-- Enable Row Level Security
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only insert their own usage logs
CREATE POLICY "Users can insert own usage logs"
  ON usage_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only view their own usage logs
CREATE POLICY "Users can view own usage logs"
  ON usage_logs FOR SELECT
  USING (auth.uid() = user_id);
```

### 3.3 Create Function to Get Usage Count

```sql
-- Function to get user's image usage count
CREATE OR REPLACE FUNCTION get_user_image_count(user_uuid UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER
  FROM usage_logs
  WHERE user_id = user_uuid
    AND action = 'image_generated';
$$ LANGUAGE SQL SECURITY DEFINER;
```

## Step 4: Set Up Authentication

### 4.1 Configure Email Auth

1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled
3. Configure email settings:
   - **Enable email confirmations**: OFF (for beta, you can enable later)
   - **Secure email change**: ON
   - **Double confirm email changes**: ON
   - **Disable sign ups**: ON (Important! Users cannot create accounts from app)

### 4.2 Disable Public Sign Ups

**Important**: Since accounts are created by admin only:

1. Go to **Authentication** → **Sign In / Providers** (or **Settings**)
2. Find **"Allow new users to sign up"** section
3. Toggle **"Allow new users to sign up"** to **OFF** (grey/disabled)
4. This prevents users from creating accounts from the app
5. Only admins can create accounts via Supabase dashboard

**Also recommended:**
- Toggle **"Confirm email"** to **OFF** (since admin creates accounts, email confirmation isn't needed)
- Keep **"Allow manual linking"** and **"Allow anonymous sign-ins"** disabled (OFF)

### 4.3 Set Up Email Templates (Optional)

1. Go to **Authentication** → **Email Templates**
2. Customize the templates if needed
3. For beta testing, you can keep default templates

## Step 5: Configure App with Supabase Credentials

### Option A: Using Environment Variables (Recommended for Production)

1. Create a file `mobile/.env` (add to `.gitignore`):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

2. Update `mobile/lib/main.dart` to load from .env (requires `flutter_dotenv` package)

### Option B: Direct Configuration (For Development)

1. Open `mobile/lib/main.dart`
2. Find the constants:
```dart
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'YOUR_SUPABASE_URL_HERE',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',
);
```

3. Replace with your actual values:
```dart
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**⚠️ Important**: Never commit these credentials to version control!

## Step 6: Create Admin Panel (Web Interface)

You have several options for the admin panel:

### Option A: Supabase Dashboard (Simple)

1. Use Supabase Dashboard → **Table Editor** → `user_metadata`
2. Manually edit records to:
   - Set `is_beta_user = true` for approved users
   - Set `image_limit` for each user

### Option B: Simple Web Admin Panel (Recommended)

Create a simple HTML/JavaScript admin panel:

1. Create `admin/index.html`:
```html
<!DOCTYPE html>
<html>
<head>
  <title>TileVision Admin Panel</title>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
</head>
<body>
  <h1>TileVision Admin Panel</h1>
  <div id="app">
    <input type="email" id="userEmail" placeholder="User Email">
    <button onclick="approveUser()">Approve User</button>
    <button onclick="setLimit()">Set Image Limit</button>
    <input type="number" id="imageLimit" placeholder="Image Limit" value="10">
  </div>
  <script>
    const supabaseUrl = 'YOUR_SUPABASE_URL';
    const supabaseKey = 'YOUR_SERVICE_ROLE_KEY'; // Use service role key for admin
    const supabase = supabase.createClient(supabaseUrl, supabaseKey);
    
    async function approveUser() {
      const email = document.getElementById('userEmail').value;
      // Get user by email, then update user_metadata
      // Implementation here
    }
  </script>
</body>
</html>
```

### Option C: Use Supabase Admin API

Create a simple Node.js/Python script to manage users via Supabase Admin API.

## Step 7: Create User Accounts (Admin Only)

### Method 1: Via Supabase Dashboard (Recommended)

1. Go to **Authentication** → **Users** in Supabase dashboard
2. Click **"Add user"** → **"Create new user"**
3. Fill in:
   - **Email**: User's email address
   - **Password**: Set a temporary password (user can change later)
   - **Auto Confirm User**: ✅ Check this (so user can login immediately)
4. Click **"Create user"**
5. Copy the user's **UUID** (you'll need it for Step 8)

### Method 2: Via SQL Editor

```sql
-- Create user via SQL (advanced)
-- Note: This requires admin privileges
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'user@example.com',
  crypt('temporary_password', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW()
);
```

**Note**: After creating user, you still need to set up their metadata (Step 8).

## Step 8: Set Up User Metadata and Image Limits

After creating a user account, you need to:

1. **Get the user's UUID**:
   - Go to **Authentication** → **Users**
   - Find the user and copy their **UUID**

2. **Set image limit and approve user**:

### Method 1: Via Table Editor

1. Go to **Table Editor** → `user_metadata`
2. Click **Insert row**
3. Fill in:
   - **id**: User's UUID (from `auth.users` table)
   - **is_beta_user**: `true` ✅
   - **image_limit**: `10` (or your desired limit - set this per user)
4. Click **Save**

### Method 2: Via SQL Editor

```sql
-- Insert or update user metadata
INSERT INTO user_metadata (id, is_beta_user, image_limit)
VALUES ('user-uuid-here', true, 10)  -- Replace with actual UUID and limit
ON CONFLICT (id) 
DO UPDATE SET 
  is_beta_user = true,
  image_limit = 10,  -- Update limit here
  updated_at = NOW();
```

### Setting Different Limits Per User

You can set different image limits for different users:

```sql
-- User 1: 10 images
INSERT INTO user_metadata (id, is_beta_user, image_limit)
VALUES ('user1-uuid', true, 10)
ON CONFLICT (id) DO UPDATE SET image_limit = 10;

-- User 2: 25 images
INSERT INTO user_metadata (id, is_beta_user, image_limit)
VALUES ('user2-uuid', true, 25)
ON CONFLICT (id) DO UPDATE SET image_limit = 25;

-- User 3: 50 images
INSERT INTO user_metadata (id, is_beta_user, image_limit)
VALUES ('user3-uuid', true, 50)
ON CONFLICT (id) DO UPDATE SET image_limit = 50;
```

## Step 9: Test the Setup

1. **Create a test user** in Supabase dashboard (Step 7)
2. **Set up user metadata** with image limit (Step 8)
3. Run the Flutter app: `flutter run`
4. **Sign in** with the test user credentials
5. Verify that:
   - Login works correctly
   - User can access the app
   - Profile shows correct image limit
   - Usage tracking works

## Step 10: Usage Tracking

The app automatically:
- Tracks image generation in `usage_logs` table
- Checks `user_metadata.image_limit` before allowing generation
- Shows usage stats in the Profile screen

### View Usage Statistics

Run this SQL query to see all user usage:

```sql
SELECT 
  u.email,
  um.image_limit,
  COUNT(ul.id) as images_used,
  (um.image_limit - COUNT(ul.id)) as remaining
FROM auth.users u
LEFT JOIN user_metadata um ON u.id = um.id
LEFT JOIN usage_logs ul ON u.id = ul.user_id AND ul.action = 'image_generated'
WHERE um.is_beta_user = true
GROUP BY u.id, u.email, um.image_limit
ORDER BY images_used DESC;
```

## Troubleshooting

### "Your account is pending approval"
- User exists but `is_beta_user = false` or no record in `user_metadata`
- Solution: Set up user metadata with `is_beta_user = true` (Step 8)

### "Invalid login credentials"
- User account doesn't exist in Supabase
- Solution: Create the user account in Supabase dashboard (Step 7)

### "Supabase not initialized"
- Check that you've set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `main.dart`
- Verify the values are correct (no extra spaces)

### "Row Level Security policy violation"
- Check that RLS policies are created correctly (Step 3)
- Verify user is authenticated before querying

### Can't see user_metadata table
- Make sure you ran the SQL scripts in Step 3
- Check Table Editor → `user_metadata` exists

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for production
3. **Service Role Key**: Keep this secret - only use in server-side/admin code
4. **Anon Key**: Safe to use in client apps (protected by RLS)
5. **Regular Backups**: Supabase free tier includes daily backups

## Next Steps

- Set up email templates for better UX
- Create a proper admin panel for easier user management
- Set up usage analytics dashboard
- Configure rate limiting if needed

## Support

For Supabase-specific issues:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)

For app-specific issues, check the code comments and TODO items in:
- `mobile/lib/services/auth_service.dart`
- `mobile/lib/services/usage_service.dart`

