CREATE OR REPLACE FUNCTION get_user_image_count(user_uuid UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER
  FROM usage_logs
  WHERE user_id = user_uuid
    AND action = 'image_generated';
$$ LANGUAGE SQL SECURITY DEFINER;
