import 'package:shared_preferences/shared_preferences.dart';

/// Service to track image generation usage
/// TODO: Replace with Supabase integration for server-side tracking
class UsageService {
  // Store current user ID for user-specific tracking
  static String? _currentUserId;
  
  // Base keys - will be prefixed with user ID
  static const String _keyImagesUsed = 'images_used_count';
  static const String _keyImageLimit = 'image_limit';
  static const String _keyLastResetDate = 'last_reset_date';
  
  /// Set the current user ID for user-specific tracking
  /// Call this when user logs in
  static Future<void> setCurrentUserId(String userId) async {
    _currentUserId = userId;
    // Store user ID for persistence across app restarts
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }
  
  /// Get the current user ID
  static Future<String?> getCurrentUserId() async {
    if (_currentUserId != null) {
      return _currentUserId;
    }
    // Try to load from storage
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('current_user_id');
    return _currentUserId;
  }
  
  /// Clear current user (call on logout)
  static Future<void> clearCurrentUser() async {
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }
  
  /// Get storage key with user ID prefix
  static Future<String> _getUserKey(String baseKey) async {
    final userId = await getCurrentUserId();
    if (userId == null) {
      // If no user ID, use 'guest' as default
      // This allows testing without login
      return 'guest_$baseKey';
    }
    return 'user_${userId}_$baseKey';
  }

  /// Get current usage statistics for the current user
  static Future<UsageStats> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    // TODO: Fetch from Supabase instead of local storage
    // This will be replaced with:
    // - Fetch user's image_limit from Supabase user metadata
    // - Fetch user's images_used from Supabase usage table
    // - Check if user is in beta access list
    
    // Get user-specific keys
    final imagesUsedKey = await _getUserKey(_keyImagesUsed);
    final imageLimitKey = await _getUserKey(_keyImageLimit);
    final lastResetDateKey = await _getUserKey(_keyLastResetDate);
    
    final imagesUsed = prefs.getInt(imagesUsedKey) ?? 0;
    final imageLimit = prefs.getInt(imageLimitKey) ?? 10; // Default limit for beta
    final lastResetDate = prefs.getString(lastResetDateKey);
    
    return UsageStats(
      imagesUsed: imagesUsed,
      imageLimit: imageLimit,
      imagesRemaining: imageLimit - imagesUsed,
      lastResetDate: lastResetDate,
    );
  }

  /// Increment usage count when an image is generated
  /// This should be called after successful image generation
  static Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagesUsedKey = await _getUserKey(_keyImagesUsed);
    final currentCount = prefs.getInt(imagesUsedKey) ?? 0;
    await prefs.setInt(imagesUsedKey, currentCount + 1);
    
    // TODO: Also update Supabase usage table
    // final userId = await getCurrentUserId();
    // await supabase.from('usage_logs').insert({
    //   'user_id': userId,
    //   'action': 'image_generated',
    //   'created_at': DateTime.now().toIso8601String(),
    // });
  }

  /// Set the image limit for the current user
  /// This will be called from Supabase when user data is fetched
  static Future<void> setImageLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    final imageLimitKey = await _getUserKey(_keyImageLimit);
    await prefs.setInt(imageLimitKey, limit);
    
    // TODO: This will be set from Supabase user metadata
    // The admin panel will update user metadata with image_limit
    // When fetching from Supabase:
    // final userId = await getCurrentUserId();
    // final userMeta = await supabase
    //   .from('user_metadata')
    //   .select()
    //   .eq('id', userId)
    //   .single();
    // await setImageLimit(userMeta['image_limit']);
  }

  /// Reset usage for the current user (for testing or admin purposes)
  static Future<void> resetUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagesUsedKey = await _getUserKey(_keyImagesUsed);
    final lastResetDateKey = await _getUserKey(_keyLastResetDate);
    await prefs.setInt(imagesUsedKey, 0);
    await prefs.setString(lastResetDateKey, DateTime.now().toIso8601String());
    
    // TODO: Reset in Supabase as well
    // final userId = await getCurrentUserId();
    // await supabase.from('usage_logs').delete().eq('user_id', userId);
  }
  
  /// Get usage stats for a specific user (admin function)
  /// Useful for viewing other users' usage
  static Future<UsageStats> getUsageStatsForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesUsedKey = 'user_${userId}_$_keyImagesUsed';
    final imageLimitKey = 'user_${userId}_$_keyImageLimit';
    final lastResetDateKey = 'user_${userId}_$_keyLastResetDate';
    
    final imagesUsed = prefs.getInt(imagesUsedKey) ?? 0;
    final imageLimit = prefs.getInt(imageLimitKey) ?? 10;
    final lastResetDate = prefs.getString(lastResetDateKey);
    
    return UsageStats(
      imagesUsed: imagesUsed,
      imageLimit: imageLimit,
      imagesRemaining: imageLimit - imagesUsed,
      lastResetDate: lastResetDate,
    );
  }

  /// Check if user has remaining images
  static Future<bool> hasRemainingImages() async {
    final stats = await getUsageStats();
    return stats.imagesRemaining > 0;
  }

  /// Check if user has reached their limit
  static Future<bool> hasReachedLimit() async {
    final stats = await getUsageStats();
    return stats.imagesUsed >= stats.imageLimit;
  }
}

/// Data class for usage statistics
class UsageStats {
  final int imagesUsed;
  final int imageLimit;
  final int imagesRemaining;
  final String? lastResetDate;

  UsageStats({
    required this.imagesUsed,
    required this.imageLimit,
    required this.imagesRemaining,
    this.lastResetDate,
  });

  double get usagePercentage => imageLimit > 0 ? imagesUsed / imageLimit : 0.0;
  
  bool get isLimitReached => imagesRemaining <= 0;
}

