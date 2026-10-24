-- TileVision schema for a new Supabase project.
-- Paste and run this in SQL Editor after creating the project.

-- User metadata (beta approval + image limit)
CREATE TABLE IF NOT EXISTS user_metadata (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  image_limit INTEGER DEFAULT 10 NOT NULL,
  is_beta_user BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_metadata_beta ON user_metadata(is_beta_user);

ALTER TABLE user_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own metadata"
  ON user_metadata FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own metadata"
  ON user_metadata FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Usage logs
CREATE TABLE IF NOT EXISTS usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  action TEXT NOT NULL DEFAULT 'image_generated',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usage_logs_user_id ON usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_created_at ON usage_logs(created_at);

ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own usage logs"
  ON usage_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own usage logs"
  ON usage_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Usage count helper
CREATE OR REPLACE FUNCTION get_user_image_count(user_uuid UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER
  FROM usage_logs
  WHERE user_id = user_uuid
    AND action = 'image_generated';
$$ LANGUAGE SQL SECURITY DEFINER;
