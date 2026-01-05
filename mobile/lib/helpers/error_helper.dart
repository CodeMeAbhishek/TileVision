class ErrorHelper {
  /// Convert technical error messages to user-friendly messages
  static String getUserFriendlyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socket') || 
        errorStr.contains('network') || 
        errorStr.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    if (errorStr.contains('timeout')) {
      return 'Request took too long. The server might be busy. Please try again.';
    }
    
    if (errorStr.contains('404')) {
      return 'Service not found. Please contact support if this persists.';
    }
    
    if (errorStr.contains('500')) {
      return 'Server error. Please try again in a moment.';
    }
    
    if (errorStr.contains('503')) {
      return 'Service temporarily unavailable. Please wait and try again.';
    }
    
    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Permission denied. Please enable camera/gallery access in settings.';
    }
    
    if (errorStr.contains('failed to load tiles')) {
      return 'Unable to load tiles. Please check your connection and try again.';
    }
    
    if (errorStr.contains('failed to apply tile')) {
      return 'Failed to apply tile. Please try again.';
    }
    
    if (errorStr.contains('material replacement failed')) {
      return 'AI processing failed. Please try again.';
    }
    
    if (errorStr.contains('insufficient credit') || errorStr.contains('402') || errorStr.contains('payment required')) {
      return 'Insufficient Replicate credit. Please add credit to your account to continue using AI features.';
    }
    
    if (errorStr.contains('rate limit') || errorStr.contains('429') || errorStr.contains('throttled')) {
      return 'Rate limit exceeded. Please wait a moment and try again.';
    }
    
    // Authentication errors
    if (errorStr.contains('invalid api key') || 
        errorStr.contains('invalid key') ||
        errorStr.contains('401')) {
      return 'Invalid Supabase API key. Please check your .env file and ensure you\'re using the correct anon key from Supabase dashboard.';
    }
    
    if (errorStr.contains('invalid login') || 
        errorStr.contains('invalid credentials') ||
        errorStr.contains('email not confirmed') ||
        errorStr.contains('wrong password') ||
        errorStr.contains('user not found')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    
    if (errorStr.contains('pending approval') || errorStr.contains('not approved')) {
      return 'Your account is pending approval. Please contact support.';
    }
    
    if (errorStr.contains('supabase not initialized')) {
      return 'App configuration error. Please restart the app.';
    }
    
    // Default friendly message
    return 'Something went wrong. Please try again.';
  }
  
  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('timeout') || 
           errorStr.contains('socket') || 
           errorStr.contains('network') ||
           errorStr.contains('connection') ||
           errorStr.contains('500') ||
           errorStr.contains('503');
  }
}

