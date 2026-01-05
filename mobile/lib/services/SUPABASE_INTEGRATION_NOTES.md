# Supabase Integration Notes for Beta Testing

## Overview
This app is set up for closed beta testing where only admin-approved accounts can login and have usage limits controlled from an admin panel.

## Current Implementation
- Usage tracking is currently stored locally using `shared_preferences`
- Profile screen displays usage statistics (used/remaining images)
- Usage is incremented when images are successfully generated
- Usage limit check prevents generation when limit is reached

## Supabase Integration Plan

### 1. Database Schema

Create the following tables in Supabase:

```sql
-- User metadata table (extends Supabase auth.users)
-- This will store per-user limits set by admin
CREATE TABLE user_metadata (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  image_limit INTEGER DEFAULT 10,
  is_beta_user BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Usage logs table
CREATE TABLE usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL, -- 'image_generated'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_usage_logs_user_id ON usage_logs(user_id);
CREATE INDEX idx_usage_logs_created_at ON usage_logs(created_at);
```

### 2. Row Level Security (RLS) Policies

```sql
-- Users can only read their own metadata
ALTER TABLE user_metadata ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own metadata"
  ON user_metadata FOR SELECT
  USING (auth.uid() = id);

-- Users can only insert their own usage logs
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert own usage logs"
  ON usage_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own usage logs"
  ON usage_logs FOR SELECT
  USING (auth.uid() = user_id);
```

### 3. Admin Panel Setup

Create an admin panel (separate web app or Supabase dashboard) to:
- Approve beta users (set `is_beta_user = true`)
- Set `image_limit` per user
- View usage statistics
- Manage user access

### 4. Code Changes Required

#### In `usage_service.dart`:
- Replace `SharedPreferences` calls with Supabase queries
- Fetch `image_limit` from `user_metadata` table
- Count usage from `usage_logs` table
- Insert usage logs when images are generated

#### In `profile_screen.dart`:
- Replace mock auth with Supabase auth
- Check `is_beta_user` flag before allowing login
- Show appropriate messages for non-beta users

#### In `main.dart`:
- Initialize Supabase client
- Set up auth state listener
- Redirect to login if not authenticated

### 5. Authentication Flow

1. User attempts to sign in
2. Check if user exists in `user_metadata` with `is_beta_user = true`
3. If not approved, show message: "Your account is pending approval"
4. If approved, allow login and fetch user's `image_limit`
5. Track all usage in `usage_logs` table

### 6. Usage Tracking

When an image is generated:
1. Check current usage count from `usage_logs`
2. Compare with `image_limit` from `user_metadata`
3. If under limit, proceed with generation
4. After successful generation, insert log into `usage_logs`
5. Update profile screen to show new usage stats

### 7. Admin Functions

Admin panel should allow:
- Creating/approving beta user accounts
- Setting custom `image_limit` per user
- Viewing usage statistics per user
- Resetting usage counts (if needed)
- Disabling user access

## Migration Steps

1. Add `supabase_flutter` package to `pubspec.yaml`
2. Initialize Supabase in `main.dart`
3. Create database tables and policies
4. Update `UsageService` to use Supabase
5. Update `ProfileScreen` to use Supabase auth
6. Test with admin-approved accounts
7. Deploy admin panel for managing users

## Testing Checklist

- [ ] Admin can create beta user accounts
- [ ] Admin can set image limits per user
- [ ] Only approved users can login
- [ ] Usage is tracked correctly in database
- [ ] Profile shows correct usage stats
- [ ] Limit enforcement works correctly
- [ ] Non-beta users see appropriate message

