CREATE POLICY "Users can view own metadata"
  ON user_metadata FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own metadata"
  ON user_metadata FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own usage logs"
  ON usage_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own usage logs"
  ON usage_logs FOR SELECT
  USING (auth.uid() = user_id);
